# 📘 SSM Automation設計ドキュメント：ADグループへのユーザー追加

## 🧩 シナリオ概要

S3に格納されたJSONファイルからユーザーリストを取得し、指定されたActive DirectoryグループにPowerShell経由でユーザーを追加します。処理結果はSNSを通じて通知され、ログはローカルに保存されます。

---

## 🛠️ 処理ステップ概要

| ステップ名          | 処理内容                                                 |
| ------------------- | -------------------------------------------------------- |
| `AddUsersToADGroup` | S3からJSON取得 → ADグループにユーザー追加 → 結果ログ作成 |
| `notifyResult`      | 結果ログをSNS経由で通知                                  |

---

## 📄 Automation YAMLテンプレート

```yaml
schemaVersion: '2.2'
description: "ADのofficeグループに新規登録ユーザーリストを追加するテンプレート"
parameters:
  TargetInstanceId:
    type: String
    description: "踏み台サーバーのインスタンスID"
mainSteps:
  - action: aws:runPowerShellScript
    name: AD_AddOfficeUsersToOfficeUseGroup
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
          Write-Log "=== ADの$GPNグループへのユーザー追加開始 ==="

          Read-S3Object -BucketName $S3BUCKET -Key $S3KEYIN -File $fetchPath
          Start-Sleep -Seconds 1
          $json = Get-Content $fetchPath | ConvertFrom-Json
          $users = $json.Users

          $resultLog = @()
          foreach ($user in $users) {
              try {
                  Write-Log "処理中: $user"
                  Add-ADGroupMember -Identity $GPN -Members $user -DisablePermissiveModify $true -Confirm $false
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

          $result = "【ADの$GPNグループへのユーザー追加結果】`n" + ($resultLog | Out-String)
          Set-Content -Path $tmp -Value $result
          Start-Sleep -Seconds 1
          Write-S3Object -BucketName $S3BUCKET -Key $S3KEYOUT -File $tmp
          Start-Sleep -Seconds 1
          Write-Log "=== ADの$GPNグループへのユーザー追加終了 ===`n"
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
          aws sns publish --topic-arn $SNSTOPIC --message "$message" --region REGION
    targets:
      - Key: InstanceIds
        Values:
          - "{{ TargetInstanceId }}"
```

---

## 📦 パラメーターストア構成（String型）

| 名前           | 値（例）                                                  |
| -------------- | --------------------------------------------------------- |
| `/AD/S3BUCKET` | `my-ad-user-bucket`                                       |
| `/AD/S3KEYIN`  | `office-users.csv`                                        |
| `/AD/S3KEYOUT` | `result.txt`                                              |
| `/AD/GPN`      | `office`                                                  |
| `/AD/FILEPATH` | `D:\ops\office`                                           |
| `/AD/FETCH`    | `office-users.csv`                                        |
| `/AD/TMP`      | `office-tmp.csv`                                          |
| `/AD/SNSTOPIC` | `arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults` |

---

## 🔐 IAMポリシー例（SNS通知用）

```json
{
  "Effect": "Allow",
  "Action": "sns:Publish",
  "Resource": "arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults"
}
```

---

## ✅ 前提条件

- EC2インスタンスにAD管理ツールがインストール済み
- IAMロールに `sns:Publish` 権限が付与されている
- S3バケットに対象JSONファイルが存在
- Systems Manager Agentが有効で、EC2がSSM管理対象であること

---

## 🧭 ① `Get-SSMParameter`（AWS Systems Manager パラメータ取得）

### 🔧 使い方

```powershell
Get-SSMParameter -Name "/my/parameter" -WithDecryption $true
```

### 🛠 主なオプション

| オプション        | 説明                                                    |
| ----------------- | ------------------------------------------------------- |
| `-Name`           | パラメータストアのキー名                                |
| `-WithDecryption` | SecureString の復号を有効にする（暗号化された値を取得） |

### ✅ 出力確認

```powershell
(Get-SSMParameter -Name "/my/parameter").Parameter.Value
```

---

## 🛠 AWS Tools for PowerShell のセットアップ手順（Windows）

### ✅ 1. PowerShell 実行ポリシーの確認

```powershell
Get-ExecutionPolicy
```

- `Restricted` の場合は以下で変更：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### ✅ 2. AWS.Tools.Installer モジュールのインストール

```powershell
Install-Module -Name AWS.Tools.Installer -Scope CurrentUser
```

> 初回は「信頼されていないリポジトリ」警告が出ることがありますが、`Y` を入力して続行します。

---

### ✅ 3. 必要な AWS モジュールのインストール

例：SSM と S3 を使う場合

```powershell
Install-AWSToolsModule AWS.Tools.S3, AWS.Tools.SimpleSystemsManagement
```

> モジュールは個別にインストール可能。必要なサービスだけを選べます。

---

### ✅ 4. AWS 認証情報の設定

#### 方法①: プロファイル登録

```powershell
Set-AWSCredential -AccessKey "AKIA..." -SecretKey "xxxx..." -StoreAs "MyProfile"
```

#### 方法②: 環境変数に設定（CI/CD向け）

```powershell
$env:AWS_ACCESS_KEY_ID = "AKIA..."
$env:AWS_SECRET_ACCESS_KEY = "xxxx..."
```

---

### ✅ 5. モジュールの読み込み（必要に応じて）

```powershell
Import-Module AWS.Tools.S3
Import-Module AWS.Tools.SimpleSystemsManagement
```

---

## 📦 モジュールの種類と選び方

| モジュール名            | 特徴                                   |
| ----------------------- | -------------------------------------- |
| `AWS.Tools.*`           | 推奨。サービスごとに分割されており軽量 |
| `AWSPowerShell.NetCore` | 単一モジュール。PowerShell Core 向け   |
| `AWSPowerShell`         | レガシー。Windows PowerShell 固有      |

> モジュール化された `AWS.Tools.*` が現在の推奨です。

---

## 🔗 公式ドキュメント

- [AWS公式：Windows AWS Tools for PowerShell のインストール手順（日本語）](https://docs.aws.amazon.com/ja_jp/powershell/v4/userguide/pstools-getting-set-up-windows.html)

---

## 📥 Read-S3Object の AWS CLI 版（S3からファイルをダウンロード）

```powershell
Read-S3Object -BucketName $S3BUCKET -Key $S3KEYIN -File $fetchPath
```

### ✅ AWS CLI での代替コマンド：

```bash
aws s3 cp s3://$S3BUCKET/$S3KEYIN $fetchPath
```

### 🔍 解説：

| 項目         | 説明                                                             |
| ------------ | ---------------------------------------------------------------- |
| `aws s3 cp`  | S3との間でファイルをコピーする基本コマンド                       |
| `s3://...`   | S3のバケットとキーを指定するURI形式                              |
| `$fetchPath` | ローカル保存先のフルパス（例：`D:\ops\office\office-users.csv`） |

---

## 📤 Write-S3Object の AWS CLI 版（ローカルファイルをS3にアップロード）

```powershell
Write-S3Object -BucketName $S3BUCKET -Key $S3KEYOUT -File $tmp
```

### ✅ AWS CLI での代替コマンド：

```bash
aws s3 cp $tmp s3://$S3BUCKET/$S3KEYOUT
```

### 🔍 解説：

| 項目       | 説明                                                                     |
| ---------- | ------------------------------------------------------------------------ |
| `$tmp`     | アップロード対象のローカルファイルパス（例：`D:\ops\office\result.txt`） |
| `s3://...` | アップロード先のS3バケットとキー                                         |

---

## 🧪 実行例（具体的な値を使った例）

```bash
aws s3 cp "D:\ops\office\office-users.csv" s3://my-ad-user-bucket/office-users.csv
aws s3 cp "D:\ops\office\result.txt" s3://my-ad-user-bucket/result.txt
```

---

## 🛡️ 補足：CLI実行時の注意点

- 実行環境に AWS CLI がインストールされている必要があります
- `aws configure` で認証情報（Access Key, Secret Key, Region）を設定済みであること
- IAMロールまたはユーザーに `s3:GetObject` / `s3:PutObject` 権限が必要です

---

もし PowerShell スクリプト内で AWS CLI を直接使いたい場合は、以下のように `Start-Process` や `Invoke-Expression` を使って組み込むこともできます。  
ご希望ならそのパターンも展開できますよ。どうしましょう？