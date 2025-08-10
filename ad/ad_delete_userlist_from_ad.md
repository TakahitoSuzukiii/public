## 🗑️ ADユーザーの削除：`Remove-ADUser`

### 🔧 基本構文

```powershell
Remove-ADUser -Identity "username"
```

### 🛠 主なオプション

| オプション        | 説明                                                               |
| ----------------- | ------------------------------------------------------------------ |
| `-Identity`       | 削除対象のユーザー（sAMAccountName, DistinguishedName, GUID など） |
| `-Confirm:$false` | 削除確認をスキップ（自動化時に便利）                               |
| `-Credential`     | 別の資格情報で実行する場合                                         |
| `-Server`         | 特定のドメインコントローラーを指定する場合                         |

### ✅ 例：確認なしで削除

```powershell
Remove-ADUser -Identity "takahashi.takashi" -Confirm:$false
```

---

## 🆕 ADユーザーの新規追加：`New-ADUser`

### 🔧 基本構文

```powershell
New-ADUser -Name "Takashi Takahashi" -SamAccountName "takahashi.takashi" -UserPrincipalName "takahashi.takashi@example.local" -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true
```

### 🛠 主なオプション

| オプション                | 説明                                             |
| ------------------------- | ------------------------------------------------ |
| `-Name`                   | 表示名（CN）                                     |
| `-SamAccountName`         | ログオン名（NetBIOS形式）                        |
| `-UserPrincipalName`      | UPN（通常はメール形式）                          |
| `-AccountPassword`        | パスワード（SecureString形式）                   |
| `-Enabled`                | アカウントの有効化（`$true`）                    |
| `-Path`                   | OUの指定（例：`"OU=Users,DC=example,DC=local"`） |
| `-GivenName` / `-Surname` | 名・姓                                           |
| `-DisplayName`            | 表示名                                           |
| `-EmailAddress`           | メールアドレス                                   |
| `-Department` / `-Title`  | 部署・役職などの属性                             |

### ✅ 例：OU指定でユーザー作成

```powershell
New-ADUser `
    -Name "Takashi Takahashi" `
    -SamAccountName "takahashi.takashi" `
    -UserPrincipalName "takahashi.takashi@example.local" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Enabled $true `
    -Path "OU=TestUsers,DC=example,DC=local" `
    -GivenName "Takashi" `
    -Surname "Takahashi" `
    -DisplayName "Takashi Takahashi"
```

---

## 🧠 補足：パスワードの SecureString 化

```powershell
$securePwd = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force
```

これは `-AccountPassword` に渡す必要があります。  
パスワードポリシーに合わないと作成に失敗するので注意です。

---

## 🔐 ユーザー作成後の追加処理例

- グループ追加：`Add-ADGroupMember`
- 属性更新：`Set-ADUser`
- ログ出力：`Export-Csv` や `Out-File`

---

了解です、崇史さん。  
ここでは「ADグループからの削除」ではなく、**Active Directoryからユーザーアカウントそのものを削除する**パターンをご紹介します。これはより強力な操作なので、**誤削除防止のための事前確認やログ保存が重要**になります。

---

# 📘 SSM Automation設計ドキュメント：ADユーザー削除

## 🧩 シナリオ概要

S3に格納されたJSONファイルから削除対象ユーザーリストを取得し、Active Directoryからユーザーアカウントを削除します。処理結果はSNSで通知され、ログはS3に保存されます。

---

## 🛠️ 処理ステップ概要

| ステップ名      | 処理内容                                       |
| --------------- | ---------------------------------------------- |
| `RemoveADUsers` | S3からJSON取得 → ADユーザー削除 → 結果ログ作成 |
| `notifyResult`  | 結果ログをSNS経由で通知                        |

---

## 📄 Automation YAMLテンプレート（ユーザー削除）

```yaml
schemaVersion: '2.2'
description: "ADからユーザーアカウントを削除するテンプレート"
parameters:
  TargetInstanceId:
    type: String
    description: "踏み台サーバーのインスタンスID"
mainSteps:
  - action: aws:runPowerShellScript
    name: AD_RemoveUsers
    inputs:
      runCommand:
        - |
          $S3BUCKET     = (Get-SSMParameter -Name "/AD/S3BUCKET").Value
          $S3KEYIN      = (Get-SSMParameter -Name "/AD/S3KEYIN").Value
          $S3KEYOUT     = (Get-SSMParameter -Name "/AD/S3KEYOUT").Value
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
          Write-Log "=== ADのユーザー削除開始 ==="

          Read-S3Object -BucketName $S3BUCKET -Key $S3KEYIN -File $fetchPath
          Start-Sleep -Seconds 1
          $json = Get-Content $fetchPath | ConvertFrom-Json
          $users = $json.Users

          $resultLog = @()
          foreach ($user in $users) {
              try {
                  Write-Log "処理中: $user"
                  Remove-ADUser -Identity $user -Confirm:$false
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

          $result = "【ADユーザー削除結果】`n" + ($resultLog | Out-String)
          Set-Content -Path $tmp -Value $result
          Start-Sleep -Seconds 1
          Write-S3Object -BucketName $S3BUCKET -Key $S3KEYOUT -File $tmp
          Start-Sleep -Seconds 1
          Write-Log "=== ADのユーザー削除終了 ===`n"
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

## 📦 パラメーターストア構成（例）

| 名前           | 値（例）                                                  |
| -------------- | --------------------------------------------------------- |
| `/AD/S3BUCKET` | `my-ad-user-bucket`                                       |
| `/AD/S3KEYIN`  | `users-to-delete.json`                                    |
| `/AD/S3KEYOUT` | `delete-result.txt`                                       |
| `/AD/FILEPATH` | `D:\ops\delete`                                           |
| `/AD/FETCH`    | `users-to-delete.json`                                    |
| `/AD/TMP`      | `delete-tmp.txt`                                          |
| `/AD/SNSTOPIC` | `arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults` |

---

## ⚠️ 注意点とベストプラクティス

- `Remove-ADUser` は**ユーザーアカウントを完全に削除**するため、事前にバックアップや退職処理が完了していることを確認してください
- 削除前に `Get-ADUser` で存在確認を入れることも可能です（オプション）
- 削除ログは必ずS3に保存し、監査対応できるようにしておくと安心です
