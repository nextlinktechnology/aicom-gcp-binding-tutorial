<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

# 連接多個 GCP 專案至 AICOM

## 開始之前

您已進入 GCP Cloud Shell。本教學將引導您從互動選單選取專案、設定專案標籤、啟用必要 API，並完成 IAM 授權。完成後，請返回 AICOM 進行資料驗證。

請確認您在每個目標專案中，都具備設定標籤、啟用 API 和管理 IAM 授權所需的權限。

同一次 AICOM 綁定產生的 Label Value 可供本次多個專案共用，用於驗證您對各專案的操控權。請保持原本的 AICOM 綁定視窗開啟。若關閉視窗導致 Label Value 失效，請重新開始綁定，取得新的值並為全部目標專案重新設定標籤。

## 選擇要串接的 GCP 專案

將下方指令貼至左側 Cloud Shell 終端機，按 Enter 執行。請在本教學資料夾中執行，並依畫面提示完成 Cloud Shell 授權。

```bash
python3 select-projects.py
```

選單會列出目前登入帳號可存取的專案名稱與 Project ID。輸入要綁定的專案編號，以空白分隔，例如 `1 3`，再按 Enter。

```text
選擇要連接至 AICOM 的專案
編號  專案名稱 / Project ID
1     正式環境
      company-prod
2     測試環境
      company-staging
3     開發環境
      company-dev

輸入編號，以空白分隔（例如 1 3），或輸入 q 取消 > 1 3
```

上方是示範畫面，實際清單依帳號而定。專案出現在清單中，仍需具備後續設定所需的權限。

選取後會顯示確認清單，輸入 `y` 儲存、`n` 重新選擇，或 `q` 取消。重複輸入同一編號會自動合併。

確認後，清單會儲存在本教學資料夾的 `.aicom-projects`，後續步驟會自動讀取。重新開啟終端機時，回到同一資料夾即可繼續使用。重新執行選單會先清除上次清單，請完成選取與確認後再繼續；取消或讀取失敗時需重新執行選單。

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
