# 📘 SSM Automation設計ドキュメント：ADグループからユーザー削除

## 🧩 シナリオ概要

S3に格納されたJSONファイルからユーザーリストを取得し、指定されたActive DirectoryグループからPowerShell経由でユーザーを削除します。処理結果はSNSを通じて通知され、ログはS3に保存されます。

---

## 🛠️ 処理ステップ概要

| ステップ名               | 処理内容                                                   |
| ------------------------ | ---------------------------------------------------------- |
| `RemoveUsersFromADGroup` | S3からJSON取得 → ADグループからユーザー削除 → 結果ログ作成 |
| `notifyResult`           | 結果ログをSNS経由で通知                                    |

---

## 📄 Automation YAMLテンプレート（削除版）

```yaml
schemaVersion: '2.2'
description: "ADのofficeグループからユーザーリストを削除するテンプレート"
parameters:
  TargetInstanceId:
    type: String
    description: "踏み台サーバーのインスタンスID"
mainSteps:
  - action: aws:runPowerShellScript
    name: AD_RemoveOfficeUsersFromGroup
    inputs:
      runCommand:
        - |
          $S3BUCKET     = (Get-SSMParameter -Name "/AD/S3BUCKET").Value
          $S3KEYIN      = (Get-SSMParameter -Name "/AD/S3KEYIN").Value
          $S3KEYOUT     = (Get-SSMParameter -Name "/AD/S3KEYOUT").Value
          $GPN          = (Get-SSMParameter -Name "/AD/GPN").Value
          $FILEPATH     = (Get-SSMParameter -Name "/AD/FILEPATH").Value
          $FETCH        = (Get-SSMParameter -Name "/AD/FETCH").Value
          $TMP          = (Get-SSMParameter -Name "/AD/TMP").Value
          $fetchPath    = Join-Path -Path $FILEPATH -ChildPath $FETCH
          $tmp          = Join-Path -Path $FILEPATH -ChildPath $TMP
          $logDate      = Get-Date -Format "yyyyMMdd"
          $logFile      = "$logDate.log"
          $logPath      = Join-Path -Path $FILEPATH -ChildPath $logFile
          function Write-Log($msg) {
              $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
              Add-Content -Path $logPath -Value "$timestamp - $msg"
          }
          Write-Log "=== ADの$GPNグループからのユーザー削除開始 ==="

          Read-S3Object -BucketName $S3BUCKET -Key $S3KEYIN -File $fetchPath
          Start-Sleep -Seconds 1
          $json = Get-Content $fetchPath | ConvertFrom-Json
          $users = $json.Users

          $resultLog = @()
          foreach ($user in $users) {
              try {
                  Write-Log "処理中: $user"
                  Remove-ADGroupMember -Identity $GPN -Members $user -Confirm:$false
                  $resultLog += [PSCustomObject]@{
                      User = $user
                      Status = "成功"
                      Message = ""
                  }
                  Write-Log "成功: $user"
              } catch {
                  $resultLog += [PSCustomObject]@{
                      User = $user
                      Status = "失敗"
                      Message = $_.Exception.Message
                  }
                  Write-Log "失敗: $user - $($_.Exception.Message)"
              }
          }

          $result = "【ADの$GPNグループからのユーザー削除結果】`n" + ($resultLog | Out-String)
          Set-Content -Path $tmp -Value $result
          Start-Sleep -Seconds 1
          Write-S3Object -BucketName $S3BUCKET -Key $S3KEYOUT -File $tmp
          Start-Sleep -Seconds 1
          Write-Log "=== ADの$GPNグループからのユーザー削除終了 ===`n"
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
          $FILEPATH    = (Get-SSMParameter -Name "/AD/FILEPATH").Value
          $TMP         = (Get-SSMParameter -Name "/AD/TMP").Value
          $SNSTOPIC    = (Get-SSMParameter -Name "/AD/SNSTOPIC").Value
          $tmp         = Join-Path -Path $FILEPATH -ChildPath $TMP

          $message = Get-Content -Path $tmp -Raw
          aws sns publish --topic-arn $SNSTOPIC --message "$message" --region $REGION
    targets:
      - Key: InstanceIds
        Values:
          - "{{ TargetInstanceId }}"
```

---

## 📦 パラメーターストア構成（同一でOK）

| 名前           | 値（例）                                                  |
| -------------- | --------------------------------------------------------- |
| `/AD/S3BUCKET` | `my-ad-user-bucket`                                       |
| `/AD/S3KEYIN`  | `office-users-to-remove.json`                             |
| `/AD/S3KEYOUT` | `remove-result.txt`                                       |
| `/AD/GPN`      | `office`                                                  |
| `/AD/FILEPATH` | `D:\ops\office`                                           |
| `/AD/FETCH`    | `office-users-to-remove.json`                             |
| `/AD/TMP`      | `office-remove-tmp.txt`                                   |
| `/AD/SNSTOPIC` | `arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults` |

---

## ✅ 補足ポイント

- `Remove-ADGroupMember` は `-Confirm:$false` を指定することで確認プロンプトを回避できます
- 削除対象ユーザーがグループに存在しない場合でも、例外処理でログに記録されます
- SNS通知のメッセージは「削除結果」として明示されます

---

この削除パターンを追加すれば、**追加・削除の両方をAutomationで管理できる**ようになります。  
もし「差分検出して追加・削除を自動判定する」ような高度なロジックも検討しているなら、次のステップとして提案できますよ！

## ✅ このシナリオの特徴

| 特徴                             | 説明                               |
| -------------------------------- | ---------------------------------- |
| `Remove-ADGroupMember`           | ユーザーをADグループから削除       |
| `-DisablePermissiveModify $true` | 存在しないユーザー削除時にエラー   |
| `-Confirm:$false`                | 対話なしで削除実行                 |
| SNS通知                          | 削除結果を一覧で通知（成功／失敗） |
