# AICOM GCP 資源綁定教學

本專案提供將 Google Cloud Platform (GCP) 專案資源串接至 AICOM 的自動化設定腳本與 Cloud Shell 教學，支援單一專案與一次設定多個專案。

## 快速啟動

依本次要綁定的專案數量與語言選擇教學，在 Google Cloud Shell 中開啟。

| 教學 | 文件 | Cloud Shell |
| --- | --- | --- |
| 單一專案・繁體中文 | [tutorial.md](tutorial.md) | [開啟教學](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nextlinktechnology/aicom-gcp-binding-tutorial&cloudshell_tutorial=tutorial.md) |
| 單一專案・English | [tutorial-en.md](tutorial-en.md) | [Open tutorial](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nextlinktechnology/aicom-gcp-binding-tutorial&cloudshell_tutorial=tutorial-en.md) |
| 多專案・繁體中文 | [tutorial-multi.md](tutorial-multi.md) | [開啟教學](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nextlinktechnology/aicom-gcp-binding-tutorial&cloudshell_tutorial=tutorial-multi.md) |
| 多專案・English | [tutorial-multi-en.md](tutorial-multi-en.md) | [Open tutorial](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nextlinktechnology/aicom-gcp-binding-tutorial&cloudshell_tutorial=tutorial-multi-en.md) |

## 執行流程

1. 選擇單一專案，或透過 GCP 圖形選擇器逐一選取並加入多個專案。
2. 設定 `aicom-binding` 標籤。同一次 AICOM 綁定的多個專案可共用一個 Label Value。
3. 為各專案啟用必要 API。
4. 將各專案的 `roles/viewer` 角色授予 AICOM 服務帳戶。
5. 返回 AICOM，完成各專案的資料驗證與綁定。

## 腳本用法

| 用途 | 腳本 | 對應教學 |
| --- | --- | --- |
| 單專案 IAM 授權 | `setup.sh` | `tutorial.md`、`tutorial-en.md` |
| 累積與查看 GCP 選取的專案清單 | `select-projects.py` | `tutorial-multi.md`、`tutorial-multi-en.md` |
| 多專案標籤、API 與 IAM 設定 | `setup-multi.sh` | `tutorial-multi.md`、`tutorial-multi-en.md` |

單一專案 IAM 授權可直接執行。

```bash
bash setup.sh "my-company-prod-123"
```

多專案教學使用 GCP 原生圖形選擇器。每次選擇一個專案，執行教學中自動帶入 Project ID 的加入指令，再切換專案重複加入。請由上方 Cloud Shell 連結開啟多專案教學。

開始本次綁定時，先建立空清單。

```bash
python3 select-projects.py reset
```

教學會透過 `<walkthrough-project-id/>` 帶入目前選取的專案。以下是加入指令的範例，請以實際選取的專案為準。

```bash
python3 select-projects.py add "my-company-prod-123"
```

每次切換專案後，重新複製教學中的加入指令並執行。重複加入相同專案會自動略過。完成後查看累積清單。

```bash
python3 select-projects.py list
```

英文訊息可在子指令前加上 `--language en`，例如 `python3 select-projects.py --language en list`。

確認清單後，將 `<LABEL-VALUE>` 替換為 AICOM 本次提供的值，分步執行下列指令，每一步全部成功後再繼續。

```bash
LABEL_VALUE="<LABEL-VALUE>"
bash setup-multi.sh --label "$LABEL_VALUE" --selected
```

```bash
bash setup-multi.sh --enable-apis --selected
```

```bash
bash setup-multi.sh --selected
```

選取結果儲存在本教學資料夾的 `.aicom-projects`，各步驟透過 `--selected` 讀取。只有 `reset` 會清空清單，`add` 會累積專案，`list` 可查看結果。若加入錯誤專案，請重設清單後重新選取。清單已加入 Git 忽略規則。請在同一份教學資料夾完成本次操作。

`setup-multi.sh` 每次執行都會顯示該步驟的成功與失敗專案。某專案失敗後會繼續處理其餘專案；只要有失敗，腳本便回傳非零結束碼。成功的設定會保留，修正錯誤後可重跑該步驟，也可將 `--selected` 替換為失敗專案的 ID（例如 `"company-prod"`）。腳本的摘要只代表本次步驟的結果。

腳本使用的 AICOM 服務帳戶為 `test-aicom-gcp-resource-viewer@rd-testing-6.iam.gserviceaccount.com`。

Cloud Shell 連結會讀取 GitHub 上的檔案。多專案教學、`select-projects.py` 與 `setup-multi.sh` 需發布至該儲存庫後，連結才能使用這個版本。
