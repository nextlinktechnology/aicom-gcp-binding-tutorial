<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

# 連接多個 GCP 專案至 AICOM

## 開始之前

您已進入 GCP Cloud Shell。本教學將引導您透過 GCP 圖形選擇器逐一加入專案、設定專案標籤、啟用必要 API，並完成 IAM 授權。完成後，請返回 AICOM 進行資料驗證。

請確認您在每個目標專案中，都具備設定標籤、啟用 API 和管理 IAM 授權所需的權限。

同一次 AICOM 綁定產生的 Label Value 可供本次多個專案共用，用於驗證您對各專案的操控權。請保持原本的 AICOM 綁定視窗開啟。若關閉視窗導致 Label Value 失效，請重新開始綁定，取得新的值並為全部目標專案重新設定標籤。

## 開始本次專案清單

在本教學資料夾的 Cloud Shell 終端機執行下方指令，建立本次綁定清單。這個步驟會清除上次儲存的清單，開始一次新的綁定時執行一次即可。

```bash
python3 select-projects.py reset
```

## 逐一選擇並加入 GCP 專案

請使用下方 GCP 圖形選擇器，選擇第一個要綁定的專案。

<walkthrough-project-setup></walkthrough-project-setup>

選取完成後，請確認下方指令中的 Project ID 是剛選擇的專案，再複製完整指令至 Cloud Shell 終端機執行，將它加入本次清單。

```bash
python3 select-projects.py add "<walkthrough-project-id/>"
```

成功後，終端機會顯示目前累積的專案清單。

若要加入其他專案，請留在此步驟，重複以下操作。

1. 使用上方 GCP 選擇器切換至下一個專案。
2. 確認上方加入指令已顯示新的 Project ID，再重新複製並執行。
3. 檢查終端機顯示的清單是否已包含剛加入的專案。

每次切換專案後，都需要執行一次加入指令。請每次從教學重新複製更新後的指令，終端機歷史指令會保留之前的 Project ID。重複加入相同專案會自動略過，已加入的其他專案會保留。

所有專案加入後，再前往下一步。若加入錯誤專案，可回到「開始本次專案清單」重設，再重新選擇本次要綁定的專案。

## 確認本次專案清單

執行下方指令查看清單，確認包含本次所有要綁定的專案。

```bash
python3 select-projects.py list
```

若清單缺少專案，請返回上一個步驟選取並加入，再回來檢查。確認清單正確後，再繼續設定標籤。

清單儲存在本教學資料夾的 `.aicom-projects`，後續步驟會自動讀取整份清單。重新開啟終端機時，回到同一份教學資料夾即可繼續；同一次綁定可使用 `list` 查看已選專案。

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
