# AICOM GCP 資源綁定教學

本專案提供將 Google Cloud Platform (GCP) 專案資源串接至 AICOM 的自動化授權腳本與 Cloud Shell 教學。

## 快速啟動

請點擊下方按鈕，在 Google Cloud Shell 中直接開啟並執行本教學：

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=您的_GITHUB_REPO_網址&cloudshell_tutorial=tutorial.md)
> **注意**：請將上述網址中的 `您的_GITHUB_REPO_網址` 替換為本 Repository 的實際 URL。

## 執行流程簡介
1. **選擇專案與啟用必要 API**：啟用 AICOM 讀取資源所需的 GCP APIs (如 Compute Engine, Cloud Storage 等)。
2. **執行授權 Script**：將 AICOM Service Account 授予目標 Project 所需的 IAM 檢視權限。
3. **完成驗證**：返回 AICOM 平台繼續進行資料驗證。