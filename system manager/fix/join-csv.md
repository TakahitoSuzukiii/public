# 📄 PowerShellスクリプト仕様書：CSVユーザーID統合処理

## 🧭 概要

複数のCSVファイル（ヘッダーなし・A列にユーザーID）を結合し、以下の2種類の出力ファイルを生成するPowerShellスクリプトです：

- `user_list_all.csv`：重複ありの統合ファイル
- `user_list_all_unique.csv`：重複排除済みの統合ファイル

すべてのユーザーIDは**先頭ゼロを保持**した文字列として扱われます。

---

## 📦 入力仕様

| 項目         | 内容                                                       |
| ------------ | ---------------------------------------------------------- |
| 入力ファイル | `user_list1.csv`, `user_list2.csv`, `user_list3.csv`       |
| ファイル形式 | CSV（ヘッダーなし）                                        |
| データ構造   | A列にユーザーID（例：`0123445`, `09737834`）が縦一列で並ぶ |
| 文字コード   | UTF-8（推奨）                                              |
| ファイル順   | 上記の順番で結合される                                     |

---

## 📤 出力仕様

| ファイル名                 | 内容                               | 保存先                   |
| -------------------------- | ---------------------------------- | ------------------------ |
| `user_list_all.csv`        | 結合された全ユーザーID（重複あり） | `D/ops/office/edit_csv/` |
| `user_list_all_unique.csv` | 重複排除済みのユーザーID一覧       | `D/ops/office/edit_csv/` |

---

## 🛠 スクリプト本体

```powershell
# 処理開始時間を記録
$start_time = Get-Date
Write-Host "🔹 処理開始: $start_time"

# 入力ファイルのリスト
$input_files = @("user_list1.csv", "user_list2.csv", "user_list3.csv")

# 出力ファイルのパス
$output_file        = "D/ops/office/edit_csv/user_list_all.csv"
$output_file_unique = "D/ops/office/edit_csv/user_list_all_unique.csv"

# 全ユーザーIDを格納する配列
$all_user_ids = @()

# 各入力ファイルの件数を表示しながら読み込み
foreach ($file in $input_files) {
    if (Test-Path $file) {
        $ids = Get-Content $file
        $count = $ids.Count
        Write-Host "📄 $file のユーザーID件数: $count"
        $all_user_ids += $ids
    } else {
        Write-Host "⚠️ ファイルが見つかりません: $file"
    }
}

# 重複ありのファイルを新規作成（上書き）
$all_user_ids | Set-Content $output_file

# 重複なしのファイルを新規作成（ソート付き）
$unique_user_ids = $all_user_ids | Sort-Object | Get-Unique
$unique_user_ids | Set-Content $output_file_unique

# 件数を画面に出力
Write-Host "📦 結合後（重複あり）のユーザーID件数: $($all_user_ids.Count)"
Write-Host "📦 重複排除後のユーザーID件数: $($unique_user_ids.Count)"

# 処理完了時間を記録
$end_time = Get-Date
Write-Host "✅ 処理完了: $end_time"
```

---

## 🖥 実行結果例（画面出力）

```plaintext
🔹 処理開始: 2025/09/15 22:12:03
📄 user_list1.csv のユーザーID件数: 500
📄 user_list2.csv のユーザーID件数: 600
📄 user_list3.csv のユーザーID件数: 400
📦 結合後（重複あり）のユーザーID件数: 1500
📦 重複排除後のユーザーID件数: 1342
✅ 処理完了: 2025/09/15 22:12:05
```

---

## 🔐 仕様上の注意点

- **先頭ゼロの保持**：`Get-Content` と `Set-Content` により、IDは文字列として扱われ、Excelで開いてもゼロが消えません。
- **ファイル上書き**：出力ファイルは毎回新規作成され、既存ファイルがあれば自動的に上書きされます。
- **ファイル存在チェック**：入力ファイルが存在しない場合は警告を表示しますが、処理は継続されます。

---

## 📈 拡張案（必要に応じて）

- ログファイルへの出力（`Out-File`）
- エラー通知（メールやSlack連携）
- スケジュール実行（`Task Scheduler`や`Scheduled Job`）
- 処理時間の計測と表示（`$end_time - $start_time`）
