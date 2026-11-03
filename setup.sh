#!/bin/bash
set -euo pipefail

echo "====================================================="
echo "🚀 GCP Project 授權設定"
echo "====================================================="
echo ""

# ---------------------------------------------------
# [檢查一] 確認使用者是否正確傳入 Project ID
# ---------------------------------------------------
CURRENT_PROJECT="${1:-}"

if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" = "<PROJECT-ID>" ]; then
    echo "❌ 錯誤：未偵測到有效的 Project ID！"
    echo "💡 請將 <PROJECT-ID> 替換為目標 GCP Project 的真實 Project ID。"
    echo ""
    echo "👉 正確範例：bash setup.sh \"my-company-prod-123\""
    echo ""
    exit 1
fi

# ---------------------------------------------------
# [檢查二] 將終端機環境切換至目標專案
# ---------------------------------------------------
gcloud config set project "$CURRENT_PROJECT" >/dev/null 2>&1

echo "✅ 目前指定的專案 ID：[$CURRENT_PROJECT]"
echo "⏳ 正在授予 AICOM Service Account 讀取權限..."

# ---------------------------------------------------
# [核心指令] 賦予平台監控 Service Account 檢視權限
# ---------------------------------------------------
SERVICE_ACCOUNT="test-aicom-gcp-resource-viewer@rd-testing-6.iam.gserviceaccount.com"
ROLE="roles/viewer"

gcloud projects add-iam-policy-binding "$CURRENT_PROJECT" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="$ROLE" \
  --condition=None

# ---------------------------------------------------
# [結束] 顯示成功訊息
# ---------------------------------------------------
echo ""
echo "🎉 授權設定已完成。"
echo "已為 service account [$SERVICE_ACCOUNT] 賦予 [$ROLE] 權限於專案 [$CURRENT_PROJECT]。"
echo "====================================================="