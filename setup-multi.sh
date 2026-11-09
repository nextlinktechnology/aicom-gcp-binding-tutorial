#!/bin/bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Keep the selection workflow behind the multi-project script entry point.
if [ "${1:-}" = "--select" ]; then
    shift
    exec python3 -c "$(cat <<'PYTHON_SELECTOR'
#!/usr/bin/env python3
"""Select accessible GCP projects and save IDs for the tutorial steps."""

import argparse
import curses
import sys
import unicodedata
import fcntl
import re
import json
import os
from pathlib import Path
import subprocess
import tempfile


MESSAGES = {
    "zh": {
        "loading": "正在讀取目前帳號可存取的 GCP 專案…",
        "replacing": "開始重新選擇，已清除上次的專案清單。",
        "title": "AICOM | 選擇要綁定的 GCP 專案",
        "keys": "↑↓ 移動  空白鍵 勾選/取消  Enter 儲存",
        "more_keys": "a 全選  c 清空  PgUp/PgDn 翻頁  q/Esc 取消",
        "count": "已勾選 {count} / {total} 個專案 · 目前第 {position} 個",
        "required": "請至少勾選一個專案，再按 Enter。",
        "small": "請放大終端機，至少 40 欄 × 12 列。q 可取消。",
        "tty": "請直接在 Cloud Shell 互動式終端機執行此指令。",
        "saved": "已儲存 {count} 個專案。請繼續教學的「設定專案標籤」步驟。",
        "cancelled": "已取消選擇。請重新執行選單後再繼續教學。",
        "empty": "目前帳號沒有可列出的專案。請確認登入帳號與專案存取權限。",
        "error": "無法完成專案選擇，請查看錯誤後重試。",
    },
    "en": {
        "loading": "Loading GCP projects accessible by the active account…",
        "replacing": "Starting a new selection. The previous project list has been cleared.",
        "title": "AICOM | Select GCP projects to connect",
        "keys": "Up/Down Move  Space Toggle  Enter Save",
        "more_keys": "a All  c Clear  PgUp/PgDn Page  q/Esc Cancel",
        "count": "Selected {count} / {total} projects · Row {position}",
        "required": "Select at least one project before pressing Enter.",
        "small": "Enlarge the terminal to 40 columns x 12 rows. q cancels.",
        "tty": "Run this command directly in an interactive Cloud Shell terminal.",
        "saved": "Saved {count} projects. Continue to the Set the Project Labels step.",
        "cancelled": "Selection cancelled. Run the selector again before continuing.",
        "empty": "No projects were listed. Check the active account and project access.",
        "error": "Could not complete project selection. Review the error and try again.",
    },
}

def display_name(value):
    # Project names are external data and may contain terminal control characters.
    return "".join(character for character in value if character.isprintable())


def draw_text(screen, row, value, attributes=0):
    # Clip by terminal cells so Chinese names and resizing cannot overflow a row.
    height, width = screen.getmaxyx()
    if row >= height:
        return
    available = max(0, width - 2)
    rendered = []
    for character in display_name(value):
        cells = 0 if unicodedata.combining(character) else (2 if unicodedata.east_asian_width(character) in "WF" else 1)
        if cells > available:
            break
        rendered.append(character)
        available -= cells
    try:
        screen.addstr(row, 0, "".join(rendered), attributes)
    except curses.error:
        # A resize may occur between measuring the window and drawing the text.
        pass


def select_projects(screen, projects, messages):
    screen.keypad(True)
    try:
        curses.curs_set(0)
    except curses.error:
        pass
    selected = set()
    cursor = 0
    first_visible = 0
    status = ""
    while True:
        screen.erase()
        height, width = screen.getmaxyx()
        if height < 12 or width < 40:
            draw_text(screen, 0, messages["small"])
            screen.refresh()
            if screen.get_wch() in ("q", "Q", "\x1b"):
                return None
            continue
        page_size = max(1, (height - 8) // 2)
        first_visible = min(first_visible, cursor)
        first_visible = max(first_visible, cursor - page_size + 1)
        draw_text(screen, 0, messages["title"], curses.A_BOLD)
        draw_text(screen, 1, messages["keys"])
        draw_text(screen, 2, messages["more_keys"])
        for index in range(first_visible, min(len(projects), first_visible + page_size)):
            project = projects[index]
            marker = "[x]" if project["projectId"] in selected else "[ ]"
            name = project.get("name") or project["projectId"]
            attributes = curses.A_REVERSE if index == cursor else curses.A_NORMAL
            row = 4 + (index - first_visible) * 2
            draw_text(screen, row, f"{marker} {name}", attributes)
            draw_text(screen, row + 1, f"    {project['projectId']}", attributes)
        draw_text(screen, height - 3, messages["count"].format(count=len(selected), total=len(projects), position=cursor + 1))
        draw_text(screen, height - 2, status, curses.A_BOLD)
        screen.refresh()
        key = screen.get_wch()
        status = ""
        if key in ("q", "Q", "\x1b"):
            return None
        if key in ("\n", "\r", curses.KEY_ENTER):
            if selected:
                return [project for project in projects if project["projectId"] in selected]
            status = messages["required"]
        elif key == " ":
            project_id = projects[cursor]["projectId"]
            selected.symmetric_difference_update({project_id})
        elif key in ("a", "A"):
            selected = {project["projectId"] for project in projects}
        elif key in ("c", "C"):
            selected.clear()
        elif key in (curses.KEY_UP, "k"):
            cursor = max(0, cursor - 1)
        elif key in (curses.KEY_DOWN, "j"):
            cursor = min(len(projects) - 1, cursor + 1)
        elif key == curses.KEY_PPAGE:
            cursor = max(0, cursor - page_size)
        elif key == curses.KEY_NPAGE:
            cursor = min(len(projects) - 1, cursor + page_size)
        elif key == curses.KEY_HOME:
            cursor = 0
        elif key == curses.KEY_END:
            cursor = len(projects) - 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory")
    parser.add_argument("--language", choices=("zh", "en"), default="zh")
    args = parser.parse_args()
    messages = MESSAGES[args.language]
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        print(messages["tty"])
        return 1
    selection_file = Path(args.directory) / ".aicom-projects"
    temporary_path = None
    lock = None
    try:
        lock = selection_file.with_name(".aicom-projects-lock").open("a")
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        # Invalidate old selections so cancellation or a failed refresh cannot reuse them.
        if selection_file.exists():
            selection_file.unlink()
            print(messages["replacing"])
        print(messages["loading"])
        result = subprocess.run(
            ["gcloud", "projects", "list", "--format=json(projectId,name)", "--sort-by=name,projectId"],
            check=True, stdout=subprocess.PIPE, text=True,
        )
        projects = json.loads(result.stdout)
        if not isinstance(projects, list):
            raise ValueError("Invalid project list returned by gcloud.")
        for project in projects:
            project_id = project.get("projectId") if isinstance(project, dict) else None
            if not isinstance(project_id, str) or re.fullmatch(r"[a-z0-9][a-z0-9.:-]*", project_id) is None:
                raise ValueError("Invalid Project ID returned by gcloud.")
            if project.get("name") is not None and not isinstance(project["name"], str):
                raise ValueError("Invalid project name returned by gcloud.")
        if not projects:
            print(messages["empty"])
            return 1
        selected = curses.wrapper(select_projects, projects, messages)
        if selected is None:
            print(messages["cancelled"])
            return 1
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=selection_file.parent,
                                         prefix=".aicom-projects-", delete=False) as output:
            temporary_path = Path(output.name)
            for project in selected:
                output.write(project["projectId"] + "\n")
        os.replace(temporary_path, selection_file)
        print("\n" + messages["saved"].format(count=len(selected)))
        for project in selected:
            print(f"  [x] {project['projectId']}")
        return 0
    except (EOFError, KeyboardInterrupt):
        print("\n" + messages["cancelled"])
        return 1
    except (OSError, ValueError, curses.error, subprocess.CalledProcessError) as error:
        print(f"{messages['error']}\n{error}")
        return 1
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
        if lock is not None:
            lock.close()


if __name__ == "__main__":
    raise SystemExit(main())
PYTHON_SELECTOR
)" "$SCRIPT_DIRECTORY" "$@"
fi

# 多專案設定，預設執行 IAM 授權。
ACTION="iam"
LABEL_VALUE=""
case "${1:-}" in
    --label)
        ACTION="label"
        LABEL_VALUE="${2:-}"
        if [[ -z "$LABEL_VALUE" || "$LABEL_VALUE" == *[\<\>\,\=[:space:]]* ]]; then
            echo "❌ 請提供 AICOM 產生的有效 Label Value。" >&2
            exit 1
        fi
        shift 2
        ;;
    --enable-apis)
        ACTION="apis"
        shift
        ;;
esac

if [ "${1:-}" = "--selected" ]; then
    if [ "$#" -ne 1 ]; then
        echo '❌ --selected 請單獨使用，專案清單由專案選取介面提供。' >&2
        exit 1
    fi
    SELECTION_FILE="$SCRIPT_DIRECTORY/.aicom-projects"
    if [ ! -s "$SELECTION_FILE" ]; then
        echo '❌ 尚未選擇專案。請先執行 bash setup-multi.sh --select 並確認儲存清單。' >&2
        exit 1
    fi
    SELECTED_PROJECTS=()
    while IFS= read -r PROJECT_ID || [ -n "$PROJECT_ID" ]; do
        SELECTED_PROJECTS+=("$PROJECT_ID")
    done < "$SELECTION_FILE"
    set -- "${SELECTED_PROJECTS[@]}"
fi

if [ "$#" -eq 0 ]; then
    echo '❌ 請提供至少一個 Project ID。' >&2
    echo 'IAM 授權範例：bash setup-multi.sh "my-company-prod-123" "my-company-dev-123"' >&2
    exit 1
fi

# 先檢查整份清單，避免尚未替換的佔位文字造成部分專案先被修改。
for CURRENT_PROJECT in "$@"; do
    if [[ -z "$CURRENT_PROJECT" || "$CURRENT_PROJECT" == -* || "$CURRENT_PROJECT" == *[\<\>[:space:]]* ]]; then
        echo "❌ 無效的 Project ID：[$CURRENT_PROJECT]。請逐一傳入真實的 Project ID。" >&2
        exit 1
    fi
done

if ! command -v gcloud >/dev/null 2>&1; then
    echo "❌ 找不到 gcloud，請在 Google Cloud Shell 中執行。" >&2
    exit 1
fi

SERVICE_ACCOUNT="test-aicom-gcp-resource-viewer@rd-testing-6.iam.gserviceaccount.com"
ROLE="roles/viewer"

# 每個分支只執行一個指令，直接將該指令的結果回傳給批次處理。
configure_project() {
    local project_id="$1"
    case "$ACTION" in
        label)
            gcloud alpha projects update "$project_id" \
                --update-labels="aicom-binding=$LABEL_VALUE" --quiet
            ;;
        apis)
            gcloud services enable \
                cloudresourcemanager.googleapis.com \
                compute.googleapis.com \
                sqladmin.googleapis.com \
                storage.googleapis.com \
                bigquery.googleapis.com \
                monitoring.googleapis.com \
                aiplatform.googleapis.com \
                cloudasset.googleapis.com \
                --project="$project_id" --quiet
            ;;
        iam)
            gcloud projects add-iam-policy-binding "$project_id" \
                --member="serviceAccount:$SERVICE_ACCOUNT" \
                --role="$ROLE" \
                --condition=None --quiet
            ;;
    esac
}

SUCCESSFUL_PROJECTS=()
FAILED_PROJECTS=()
echo "🚀 GCP 專案設定，本次步驟 [$ACTION]，共 $# 個專案。"
for CURRENT_PROJECT in "$@"; do
    echo "⏳ 正在處理 [$CURRENT_PROJECT]..."
    if configure_project "$CURRENT_PROJECT"; then
        SUCCESSFUL_PROJECTS+=("$CURRENT_PROJECT")
        echo "✅ [$CURRENT_PROJECT] 本步驟完成。"
    else
        FAILED_PROJECTS+=("$CURRENT_PROJECT")
        echo "❌ [$CURRENT_PROJECT] 本步驟失敗，請查看上方錯誤訊息。" >&2
    fi
done

echo ""
echo "本次步驟 [$ACTION] 結果：成功 ${#SUCCESSFUL_PROJECTS[@]}，失敗 ${#FAILED_PROJECTS[@]}。"
if [ "${#SUCCESSFUL_PROJECTS[@]}" -gt 0 ]; then
    printf '✅ %s\n' "${SUCCESSFUL_PROJECTS[@]}"
fi
if [ "${#FAILED_PROJECTS[@]}" -gt 0 ]; then
    printf '❌ %s\n' "${FAILED_PROJECTS[@]}"
    echo "請修正錯誤，對失敗的專案重新執行本步驟，全部成功後再繼續教學。" >&2
    exit 1
fi
echo "🎉 所有指定專案已完成本步驟。"
