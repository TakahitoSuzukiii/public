# 📘 SSM Automation設計ドキュメント：ADグループユーザー一覧取得

## 🧩 シナリオ概要

指定されたActive Directoryグループに所属するユーザー一覧を取得し、CSVファイルとしてローカルに保存した後、S3にアップロードします。処理結果はSNSで通知されます。

---

## 🛠️ 処理ステップ概要

| ステップ名             | 処理内容                                                        |
| ---------------------- | --------------------------------------------------------------- |
| `ExportADGroupMembers` | ADグループのメンバー一覧取得 → CSV形式で保存 → S3へアップロード |
| `notifyResult`         | 処理完了通知をSNS経由で送信                                     |

---

## 📄 Automation YAMLテンプレート（ユーザー一覧取得）

```yaml
schemaVersion: '2.2'
description: "指定のADグループのユーザー一覧をCSV形式で取得・保存するテンプレート"
parameters:
  TargetInstanceId:
    type: String
    description: "踏み台サーバーのインスタンスID"
mainSteps:
  - action: aws:runPowerShellScript
    name: ExportADGroupMembers
    inputs:
      runCommand:
        - |
          $S3BUCKET     = (Get-SSMParameter -Name "/AD/S3BUCKET").Value
          $S3KEYOUT     = (Get-SSMParameter -Name "/AD/S3KEYOUT").Value
          $GPN          = (Get-SSMParameter -Name "/AD/GPN").Value
          $FILEPATH     = (Get-SSMParameter -Name "/AD/FILEPATH").Value
          $EXPORT       = (Get-SSMParameter -Name "/AD/EXPORT").Value
          $exportPath   = Join-Path -Path $FILEPATH -ChildPath $EXPORT
          $logDate      = Get-Date -Format "yyyyMMdd"
          $logFile      = "$logDate.log"
          $logPath      = Join-Path -Path $FILEPATH -ChildPath $logFile
          function Write-Log($msg) {
              $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
              Add-Content -Path $logPath -Value "$timestamp - $msg"
          }
          Write-Log "=== ADの$GPNグループユーザー一覧の出力開始 ==="

          try {
              Write-Log "処理中"
              $members = Get-ADGroupMember -Identity $GPN | Where-Object { $_.objectClass -eq 'user' }
              $exportData = $members | Select-Object Name, SamAccountName, DistinguishedName
              $exportData | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
              Write-Log "成功: $members"
          } catch {
              Write-Log "失敗: $($_.Exception.Message)"
          }

          Write-S3Object -BucketName $S3BUCKET -Key $S3KEYOUT -File $exportPath
          Write-Log "=== ADの$GPNグループユーザー一覧の出力終了 ===`n"
      targets:
        - Key: InstanceIds
          Values:
            - "{{ TargetInstanceId }}"
  - name: notifyResult
    action: aws:runPowerShellScript
    inputs:
      runCommand:
        - |
          $REGION      = (Get-SSMParameter -Name "/AD/REGION").Value
          $SNSTOPIC    = (Get-SSMParameter -Name "/AD/SNSTOPIC").Value
          $message     = "ADグループ '$((Get-SSMParameter -Name "/AD/GPN").Value)' のユーザー一覧を取得し、S3に保存しました。"

          aws sns publish --topic-arn $SNSTOPIC --message "$message" --region $REGION
    targets:
      - Key: InstanceIds
        Values:
          - "{{ TargetInstanceId }}"
```

---

## 📦 パラメーターストア構成（例）

| 名前           | 値（例）                                                  |
| -------------- | --------------------------------------------------------- |
| `/AD/S3BUCKET` | `my-ad-user-bucket`                                       |
| `/AD/S3KEYOUT` | `group-users.csv`                                         |
| `/AD/GPN`      | `office`                                                  |
| `/AD/FILEPATH` | `D:\ops\audit`                                            |
| `/AD/EXPORT`   | `group-users.csv`                                         |
| `/AD/REGION`   | `ap-northeast-1`                                          |
| `/AD/SNSTOPIC` | `arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults` |

---

## ✅ 補足ポイント

- `Get-ADGroupMember` で取得したユーザーは `objectClass` フィルタでユーザーのみ抽出
- `Export-Csv` に `-NoTypeInformation` を指定して余計なヘッダーを除去
- SNS通知は簡潔なメッセージで完了報告
