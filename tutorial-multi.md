<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

# 連接多個 GCP 專案至 AICOM

## 開始之前

您已進入 GCP Cloud Shell。本教學將引導您透過終端機勾選式多選清單選取專案、設定專案標籤、啟用必要 API，並完成 IAM 授權。完成後，請返回 AICOM 進行資料驗證。

請確認您在每個目標專案中，都具備設定標籤、啟用 API 和管理 IAM 授權所需的權限。

同一次 AICOM 綁定產生的 Label Value 可供本次多個專案共用，用於驗證您對各專案的操控權。請保持原本的 AICOM 綁定視窗開啟。若關閉視窗導致 Label Value 失效，請重新開始綁定，取得新的值並為全部目標專案重新設定標籤。

## 勾選要串接的 GCP 專案

在本教學資料夾的 Cloud Shell 終端機執行下方指令，並依提示完成 Cloud Shell 授權。專案清單會直接顯示在終端機內。

```bash
bash setup-multi.sh --select
```

清單會顯示目前帳號可存取的專案名稱與 Project ID，反白列代表目前游標位置。

```text
AICOM | 選擇要綁定的 GCP 專案
↑↓ 移動  空白鍵 勾選/取消  Enter 儲存

a 全選  c 清空  PgUp/PgDn 翻頁  q/Esc 取消

[x] 正式環境
    company-prod
[ ] 測試環境
    company-staging
[x] 開發環境
    company-dev

已勾選 2 / 3 個專案
```

上方是示範畫面，實際清單依帳號而定。

- 使用方向鍵 `↑`、`↓` 移動，按空白鍵勾選或取消勾選。
- 可勾選多個專案，再按 `Enter` 確認並自動儲存。
- `a` 可全選，`c` 可清空，`Page Up`、`Page Down` 可翻頁。
- `q` 或 `Esc` 可取消。至少勾選一個專案才能儲存。

請選擇您有權設定標籤、啟用 API 與授予 IAM 權限的專案。若畫面提示尺寸不足，請拉高或放大 Cloud Shell 終端機。

儲存後，終端機會顯示已選的 Project ID，即可繼續下一步。清單存於本教學資料夾的 `.aicom-projects`，後續步驟會自動讀取。重新執行 `--select` 會清除上次清單，開始新的選取；取消或讀取失敗後，請重新選取並確認。

## 設定專案標籤

將 `<LABEL-VALUE>` 替換為從本次 AICOM 綁定視窗複製的 Label Value，再執行完整指令。腳本會將相同的 `aicom-binding` 標籤值設定至清單中的每個專案。

```bash
LABEL_VALUE="<LABEL-VALUE>"
bash setup-multi.sh --label "$LABEL_VALUE" --selected
```

請確認結果顯示所有專案都已完成本步驟，再繼續啟用 API。若有失敗，依畫面錯誤修正後重跑本步驟；重跑時也可直接列出失敗專案的 Project ID，取代 `--selected`。

## 啟用必要 API

執行下方指令，為清單中的每個專案啟用以下 API，讓 AICOM 取得雲資源與監控資料。

- Cloud Resource Manager API
- Compute Engine API
- Cloud SQL Admin API
- Cloud Storage API
- BigQuery API
- Cloud Monitoring API
- Vertex AI API
- Cloud Asset API

```bash
bash setup-multi.sh --enable-apis --selected
```

專案較多時，請等待腳本顯示結果摘要。若顯示權限不足，請聯繫專案管理員協助。部分 API 可能已成功啟用，修正問題後可重新執行本步驟。請在所有專案都成功後繼續。

## 授予 AICOM 存取權限

執行下方指令，將各專案的 Viewer（`roles/viewer`）角色授予 AICOM 指定的服務帳戶，讓 AICOM 能讀取雲資源與監控資料。

```bash
bash setup-multi.sh --selected
```

腳本會逐一處理所有專案。某個專案失敗時會繼續處理其餘專案，最後列出本步驟的成功與失敗清單。若有失敗，請修正後重跑該步驟；已完成的設定會保留。IAM 授權成功後，請確認前面的標籤與 API 步驟也已全部成功。

## 返回 AICOM 完成驗證

確認清單中的每個專案都完成標籤設定、API 啟用和 IAM 授權後，返回原本的 AICOM 綁定視窗。

依 AICOM 畫面提供本次各專案的 Project ID 與串接名稱，完成驗證及綁定。請確認本次清單中的所有專案都已驗證成功。

若驗證失敗，請確認該專案使用本次綁定的 Label Value，且三個設定步驟都已完成，再重新驗證。
