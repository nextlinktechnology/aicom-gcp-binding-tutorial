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
        "title": "選擇要連接至 AICOM 的專案",
        "header": "編號  專案名稱 / Project ID",
        "note": "請選擇您有權設定標籤、啟用 API 與授予 IAM 權限的專案。",
        "prompt": "輸入編號，以空白分隔（例如 1 3），或輸入 q 取消 > ",
        "invalid": "請輸入清單中的有效編號，例如 1 3。",
        "selected": "已選擇 {count} 個專案",
        "confirm": "輸入 y 確認儲存、a 繼續加入、n 清空重選、q 取消 > ",
        "confirm_invalid": "請輸入 y、a、n 或 q。",
        "saved": "已儲存 {count} 個專案。請繼續教學的「設定專案標籤」步驟。",
        "cancelled": "已取消選擇。請重新執行選單後再繼續教學。",
        "empty": "目前帳號沒有可列出的專案。請確認登入帳號與專案存取權限。",
        "error": "無法完成專案選擇，請查看錯誤後重試。",
    },
    "en": {
        "loading": "Loading GCP projects accessible by the active account…",
        "replacing": "Starting a new selection. The previous project list has been cleared.",
        "title": "Select projects to connect to AICOM",
        "header": "No.   Project name / Project ID",
        "note": "Choose projects where you can update labels, enable APIs and grant IAM access.",
        "prompt": "Enter numbers separated by spaces (for example 1 3), or q to cancel > ",
        "invalid": "Enter valid numbers from the list, for example 1 3.",
        "selected": "Selected {count} projects",
        "confirm": "Enter y to save, a to add more, n to start over, or q to cancel > ",
        "confirm_invalid": "Enter y, a, n or q.",
        "saved": "Saved {count} projects. Continue to the Set the Project Labels step.",
        "cancelled": "Selection cancelled. Run the selector again before continuing.",
        "empty": "No projects were listed. Check the active account and project access.",
        "error": "Could not complete project selection. Review the error and try again.",
    },
}


def display_name(value):
    # Project names are external data and may contain terminal control characters.
    return "".join(character for character in value if character.isprintable())


def select_projects(projects, messages):
    selected_by_id = {}
    while True:
        print("\n" + messages["title"])
        print(messages["header"])
        for number, project in enumerate(projects, start=1):
            print(f"{number:<5} {display_name(project.get('name') or project['projectId'])}")
            print(f"      {project['projectId']}")
        print("\n" + messages["note"])
        selection = input(messages["prompt"]).strip()
        if selection.lower() == "q":
            return None
        # Compare strings to known options to reject zero, negatives and huge numbers.
        options = {str(number): project for number, project in enumerate(projects, start=1)}
        numbers = selection.split()
        if not numbers or any(number not in options for number in numbers):
            print(messages["invalid"])
            continue
        for number in numbers:
            project = options[number]
            selected_by_id[project['projectId']] = project
        selected = list(selected_by_id.values())
        print("\n" + messages["selected"].format(count=len(selected)))
        for project in selected:
            print(f"  ✓ {display_name(project.get('name') or project['projectId'])} ({project['projectId']})")
        while True:
            answer = input(messages["confirm"]).strip().lower()
            if answer == "y":
                return selected
            if answer == "q":
                return None
            if answer == "n":
                selected_by_id.clear()
                break
            if answer == "a":
                break
            print(messages["confirm_invalid"])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory")
    parser.add_argument("--language", choices=("zh", "en"), default="zh")
    args = parser.parse_args()
    messages = MESSAGES[args.language]
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
        selected = select_projects(projects, messages)
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
        return 0
    except (EOFError, KeyboardInterrupt):
        print("\n" + messages["cancelled"])
        return 1
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
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
        echo '❌ --selected 請單獨使用，專案清單由終端機互動選單提供。' >&2
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
