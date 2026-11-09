#!/bin/bash
set -euo pipefail

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
        echo '❌ --selected 請單獨使用，專案清單由互動選單提供。' >&2
        exit 1
    fi
    SELECTION_FILE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/.aicom-projects"
    if [ ! -s "$SELECTION_FILE" ]; then
        echo '❌ 尚未選擇專案。請先執行 python3 select-projects.py 並確認清單。' >&2
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
