<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

# 連接您的 GCP 專案至 AICOM

## 開始之前

您已進入 GCP Cloud Shell。請依照本教學執行 AICOM 提供的指令，完成專案串接所需的設定。

本教學將引導您選擇專案、設定專案標籤、啟用必要 API，並完成 IAM 授權。完成後，請返回 AICOM 進行資料驗證。

開始前，請確認您在目標專案中具備 Editor（`roles/editor`）角色，以及設定標籤、啟用 API 和管理 IAM 授權所需的權限。請保持原本的 AICOM 綁定視窗開啟。

## 選擇要串接的 GCP 專案

請選擇要連接至 AICOM 的 GCP 專案。後續的標籤設定、API 啟用與 IAM 授權都將套用至此專案。

若沒有適用的專案，可先建立新專案，再返回此處選擇。

<walkthrough-project-setup></walkthrough-project-setup>

## 設定專案標籤

下方指令已帶入您選擇的 Project ID。請將 `<LABEL-VALUE>` 替換為先前從 AICOM 複製的 Label Value，再將完整指令貼至左側 Cloud Shell 終端機，按 Enter 執行。

```bash
gcloud alpha projects update "<walkthrough-project-id/>" \
  --update-labels="aicom-binding=<LABEL-VALUE>"
```

**提醒**：若關閉 AICOM 綁定視窗，Label Value 將失效，需重新開始綁定流程。

## 啟用必要 API

請執行下方指令，為所選專案啟用以下 API，讓 AICOM 取得雲資源與監控資料。

- Cloud Resource Manager API
- Compute Engine API
- Cloud SQL Admin API
- Cloud Storage API
- BigQuery API
- Cloud Monitoring API
- Vertex AI API
- Cloud Asset API

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  bigquery.googleapis.com \
  monitoring.googleapis.com \
  aiplatform.googleapis.com \
  cloudasset.googleapis.com \
  --project="<walkthrough-project-id/>"
```

將完整指令貼至左側 Cloud Shell 終端機，按 Enter 執行。若顯示權限不足，請聯繫專案管理員協助。

## 授予 AICOM 存取權限

請執行下方指令，將所選專案的必要 IAM 權限授予 AICOM 指定的服務帳戶，讓 AICOM 能讀取雲資源與監控資料。

指令已帶入您選擇的 Project ID。請複製完整指令，貼至左側 Cloud Shell 終端機，按 Enter 執行，並等待授權完成。

```bash
bash setup.sh "<walkthrough-project-id/>"
```

確認指令執行成功後，請返回原本的 AICOM 綁定視窗，點擊「下一步」，輸入 Project ID 與串接名稱，再點擊「驗證」。

驗證成功後，點擊「完成」，即可建立專案綁定。
