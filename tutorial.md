<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

# 選擇 Project 並啟用必要 API

請先選擇本次要串接至 AICOM 的 GCP Project，再啟用 AICOM 所需的 API。

## ​

### 1. 選擇要串接的 Project

請選擇本次要串接至 AICOM 的 GCP Project。

如使用既有 Project，請確認您具備必要的設定權限；若尚無適用的 Project，可先建立新 Project。

<walkthrough-project-setup></walkthrough-project-setup>

### 2. 啟用必要 API

AICOM 需透過以下 GCP API 取得此 Project 的雲端資源，請點擊 「啟用」，系統將為目前選擇的 Project 啟用必要 API：

- Cloud Resource Manager API
- Compute Engine API
- Cloud SQL Admin API
- Cloud Storage API
- BigQuery API
- Cloud Monitoring API
- Vertex AI API
- Cloud Asset API

系統將執行以下指令：

<walkthrough-enable-apis apis="cloudresourcemanager.googleapis.com,compute.googleapis.com,sqladmin.googleapis.com,storage.googleapis.com,bigquery.googleapis.com,monitoring.googleapis.com,aiplatform.googleapis.com,cloudasset.googleapis.com"></walkthrough-enable-apis>

## ​完成 AICOM IAM 授權

### 1. 執行授權 Script

下方指令已自動帶入您於前一步選擇的 Project ID，請複製完整指令，貼至左側 Cloud Shell 終端機，並按下 Enter 執行。

```bash
bash setup.sh "<walkthrough-project-id/>"
```

### 2. 返回 AICOM

授權完成後，請返回 AICOM，繼續進行資料驗證。
