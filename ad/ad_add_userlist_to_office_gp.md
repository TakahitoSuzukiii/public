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

もちろん崇史さん。`Get-SSMParameter` は Systems Manager (SSM) のパラメータストアから値を取得するための便利な関数ですが、Automation ドキュメント内の `RunPowerShellScript` ステップで使う際には、代替手段を検討することで柔軟性や制御性が向上します。以下に、代替手段をいくつかの観点から詳しく紹介します。

---

## 🛠 代替手段一覧

### 1. **AWS CLI を使う方法**
PowerShell から直接 AWS CLI を呼び出してパラメータを取得する方法です。

```powershell
$S3BUCKET = (aws ssm get-parameter --name "/AD/S3BUCKET" --with-decryption --query "Parameter.Value" --output text)
```

#### ✅ メリット
- `--with-decryption` により SecureString にも対応
- IAM ロールで権限制御が可能

#### ⚠ 注意点
- AWS CLI がインストールされている必要あり
- Automation 実行ロールに `ssm:GetParameter` 権限が必要

---

### 2. **AWS Tools for PowerShell を使う方法**
PowerShell の AWS モジュールを使って直接取得する方法です。

```powershell
$S3BUCKET = (Get-SSMParameter -Name "/AD/S3BUCKET" -WithDecryption $true).Value
```

これは元のコードと同じですが、`-WithDecryption` を明示することで SecureString に対応できます。

#### ✅ メリット
- PowerShell に統一できる
- Automation ドキュメント内でも自然に使える

#### ⚠ 注意点
- モジュールのバージョンによっては `Get-SSMParameter` が使えない場合がある

---

### 3. **Automation ドキュメントの `InputParameters` を使う方法**
SSM Automation の Document にパラメータを渡す設計にすることで、PowerShell スクリプト内で直接値を使えます。

#### 例: Automation Document 定義（YAML）

```yaml
parameters:
  S3BUCKET:
    type: String
  S3KEYOUT:
    type: String
  GPN:
    type: String
  FILEPATH:
    type: String
  EXPORT:
    type: String
```

#### PowerShell スクリプト内

```powershell
$S3BUCKET = "{{ S3BUCKET }}"
$S3KEYOUT = "{{ S3KEYOUT }}"
```

#### ✅ メリット
- パラメータ取得のロジックを省略できる
- Automation の再利用性が高まる

#### ⚠ 注意点
- 呼び出し元でパラメータを渡す必要がある

---

### 4. **Lambda 経由で取得する方法**
Lambda 関数を使って SSM パラメータを取得し、Automation から呼び出す方法です。

#### 構成例
- Lambda で `/AD/*` パラメータ群をまとめて取得
- Automation から `aws:invokeLambdaFunction` ステップで呼び出す

#### ✅ メリット
- 複雑なロジックを Lambda に集約できる
- キャッシュやバリデーションも可能

#### ⚠ 注意点
- Lambda の管理が必要
- Automation ロールに `lambda:InvokeFunction` 権限が必要

---

### 5. **SSM Parameter Store の `StringList` を活用する方法**
複数の値をまとめて 1 パラメータに格納し、分割して使う方法です。

#### 例: `/AD/CONFIG` に `"bucket,keyout,gpn,filepath,export"` を格納

```powershell
$config = (Get-SSMParameter -Name "/AD/CONFIG").Value.Split(',')
$S3BUCKET = $config[0]
$S3KEYOUT = $config[1]
```

#### ✅ メリット
- パラメータ数を減らせる
- 一括取得で効率的

#### ⚠ 注意点
- 順序依存になるため注意が必要
- 可読性が下がる可能性あり

---

## 🔐 セキュリティと権限の注意点

- Automation 実行ロールに `ssm:GetParameter`（SecureString の場合は `ssm:GetParameters`）の権限が必要
- パラメータ名に環境変数やタグを使うことで柔軟性を持たせることも可能

---

## 💡 おすすめの使い分け

| シナリオ           | 推奨手段                             |
| ------------------ | ------------------------------------ |
| 単純な取得         | AWS CLI または PowerShell モジュール |
| 再利用性重視       | InputParameters による外部渡し       |
| 複雑なロジック     | Lambda 経由                          |
| パラメータ数が多い | StringList でまとめる                |

---

なるほど崇史さん、SSM Parameter Store からの取得が難しい場合に、**Windows Server 2016 の環境変数に直接埋め込む方法**は、シンプルかつ確実な代替手段になります。Automation ドキュメントの `RunPowerShellScript` ステップで環境変数を参照することで、外部依存を減らし、トラブルシューティングも容易になります。

---

## 🧬 方法①：環境変数を事前に設定しておく

### 🔧 PowerShell で環境変数を設定（管理者権限）

```powershell
[System.Environment]::SetEnvironmentVariable("S3BUCKET", "your-bucket-name", "Machine")
[System.Environment]::SetEnvironmentVariable("S3KEYOUT", "your-keyout-path", "Machine")
[System.Environment]::SetEnvironmentVariable("GPN", "your-gpn-value", "Machine")
[System.Environment]::SetEnvironmentVariable("FILEPATH", "your-file-path", "Machine")
[System.Environment]::SetEnvironmentVariable("EXPORT", "your-export-flag", "Machine")
```

- `"Machine"` はシステム全体に設定（再起動不要で即反映）
- `"User"` にすると現在のユーザーのみ対象

### ✅ メリット
- Automation 実行時に即参照可能
- SSM に依存しないため、ネットワークや IAM の問題を回避できる

---

## 🧪 方法②：Automation スクリプト内で環境変数を参照

```powershell
$S3BUCKET = $env:S3BUCKET
$S3KEYOUT = $env:S3KEYOUT
$GPN      = $env:GPN
$FILEPATH = $env:FILEPATH
$EXPORT   = $env:EXPORT
```

- `$env:` プレフィックスで環境変数を取得
- Automation の `RunPowerShellScript` ステップ内でそのまま使える

---

## 🧼 方法③：Automation 実行前に環境変数を一時的に設定

Automation ドキュメントの前段で `aws:runCommand` ステップを使って、対象インスタンスに環境変数を設定することも可能です。

### 例：SSM Document ステップ

```yaml
- name: SetEnvVars
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunPowerShellScript
    Parameters:
      commands:
        - '[System.Environment]::SetEnvironmentVariable("S3BUCKET", "your-bucket-name", "Machine")'
```

---

## 🔐 セキュリティと運用上の注意点

| 項目             | 内容                                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| 🔒 セキュリティ   | 機密情報（例：パスワードやキー）は環境変数に保存しない方が安全。SecureString や AWS Secrets Manager を推奨 |
| 🔄 永続性         | `"Machine"` に設定すれば再起動後も保持されるが、Automation 実行後に削除することも可能                      |
| 🧹 クリーンアップ | Automation の最後に環境変数を削除することで痕跡を残さない運用も可能                                        |

### 削除例：

```powershell
[System.Environment]::SetEnvironmentVariable("S3BUCKET", $null, "Machine")
```

---

## 🧭 補足：環境変数の確認方法

### PowerShell で一覧表示

```powershell
Get-ChildItem Env:
```

### 特定の変数だけ確認

```powershell
$env:S3BUCKET
```

---

## 💡 応用アイデア

- **ドメイン参加時の初期スクリプト**で環境変数を設定しておく
- **SSM State Manager** を使って定期的に環境変数を更新
- **タグベースの条件分岐**で異なる値を設定（例：開発環境 vs 本番）

---

環境変数ベースの運用は、SSM や Lambda に比べてシンプルですが、セキュリティと可視性のバランスが重要です。もし、SecureString を含む値を扱う場合は、別途暗号化や Secrets Manager の併用も検討できます。