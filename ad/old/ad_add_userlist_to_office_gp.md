# **ユーザー追加シナリオ**

目的は、S3にアップロードされたJSONファイルからユーザーリストを取得し、指定されたADグループにそれらのユーザーを追加することです。

---

## ✅ 最終版 SSM Document（SNS通知に東京リージョン指定）

```yaml
schemaVersion: '2.2'
description: "Add users to AD group using PowerShell and JSON from S3, then notify via SNS"
parameters:
  S3Bucket:
    type: String
    description: "S3 bucket name"
  S3Key:
    type: String
    description: "S3 object key"
  GroupName:
    type: String
    description: "AD group name to add users to"
  SourceInstanceId:
    type: String
    description: "踏み台EC2インスタンスID"
  SNSTopicArn:
    type: String
    description: "SNS Topic ARN for notification"
mainSteps:
  - action: aws:runPowerShellScript
    name: AddUsersToADGroup
    inputs:
      runCommand:
        - |
          param (
              [string]$S3Bucket = "{{ S3Bucket }}",
              [string]$S3Key = "{{ S3Key }}",
              [string]$GroupName = "{{ GroupName }}"
          )

          $localPath = "C:\Temp\group_users.json"
          Read-S3Object -BucketName $S3Bucket -Key $S3Key -File $localPath

          $json = Get-Content $localPath | ConvertFrom-Json
          $users = $json.Users

          $resultLog = @()
          foreach ($user in $users) {
              try {
                  Add-ADGroupMember -Identity $GroupName -Members $user -DisablePermissiveModify $true
                  $resultLog += [PSCustomObject]@{
                      User = $user
                      Status = "成功"
                      Message = ""
                  }
              } catch {
                  $resultLog += [PSCustomObject]@{
                      User = $user
                      Status = "失敗"
                      Message = $_.Exception.Message
                  }
              }
          }

          $resultText = "【ADのoffice-useグループへの新規登録ユーザー追加結果】`n" + ($resultLog -join "`n")
          Set-Content -Path "C:\Temp\add_result.txt" -Value $resultText
      targets:
        - Key: InstanceIds
          Values:
            - "{{ SourceInstanceId }}"
  - name: notifyResult
    action: aws:runPowerShellScript
    inputs:
      runCommand:
        - |
          param (
              [string]$TopicArn = "{{ SNSTopicArn }}"
          )

          $message = Get-Content -Path "C:\Temp\add_result.txt" -Raw

          # SNS通知（AWS CLI + 東京リージョン指定）
          aws sns publish --topic-arn $TopicArn --message "$message" --region ap-northeast-1
    targets:
      - Key: InstanceIds
        Values:
          - "{{ SourceInstanceId }}"
```

---

## ✅ IAMロールの確認ポイント

対象インスタンスにアタッチされたIAMロールには、以下の権限が必要です：

```json
{
  "Effect": "Allow",
  "Action": "sns:Publish",
  "Resource": "*"
}
```

※ `Resource` は `SNSTopicArn` に絞るのがベストです。

とても鋭いご質問です、崇史さん。

「`Resource` は `SNSTopicArn` に絞るのがベストです」というのは、**IAMポリシーのセキュリティ設計において、アクセス対象を最小限に限定するべき**という意味です。

---

## 🔐 なぜ絞るべきか？

IAMポリシーで `Resource: "*"` を指定すると、**すべてのSNSトピックに対して Publish が可能**になります。これは便利ですが、以下のリスクがあります：

- 誤って別のトピックに通知してしまう
- 他のシステムのトピックに干渉する可能性がある
- セキュリティ監査で「過剰な権限」と判断される

---

## ✅ 絞るべき書き方（例）

例えば、通知対象のSNSトピックが以下だとします：

```
arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults
```

この場合、IAMポリシーは以下のように書くのが理想です：

```json
{
  "Effect": "Allow",
  "Action": "sns:Publish",
  "Resource": "arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults"
}
```

---

## 🧠 ベストプラクティス

| ポリシー                    | 説明                                        |
| --------------------------- | ------------------------------------------- |
| `"Resource": "*"`           | すべてのSNSトピックに対して許可（広すぎる） |
| `"Resource": "<特定のARN>"` | 必要なトピックだけに限定（推奨）            |

---------------

# NEW

素晴らしい設計意図ですね、崇史さん。  
ご要望に沿って、**SSM Document自体は変更せずに、環境変数やパラメーターストアから動的に値を取得できるようにしつつ**、以下のような変更を加えた **PowerShellスクリプトの最終版** をご提案します。

---

## ✅ 修正ポイントまとめ

| 要望内容           | 対応内容                                                         |
| ------------------ | ---------------------------------------------------------------- |
| パラメータを外部化 | PowerShell内で `Get-SSMParameterValue` や `Get-Item Env:` を使用 |
| JSON → CSV保存     | `D:\ops\office\register_office_userlist.csv` に保存              |
| ログ出力           | 成功/失敗を毎回改行付きでログに記録                              |
| 結果ログ保存先     | `D:\ops\office\register_office_userlist_result.txt` に変更       |

---

## 🛠 PowerShellスクリプト（SSM Document内 runCommand）

```powershell
# 環境変数またはパラメーターストアから値を取得
$S3Bucket       = (Get-SSMParameterValue -Name "/ad/add/S3Bucket").Value
$S3Key          = (Get-SSMParameterValue -Name "/ad/add/S3Key").Value
$GroupName      = (Get-SSMParameterValue -Name "/ad/add/GroupName").Value
$SNSTopicArn    = (Get-SSMParameterValue -Name "/ad/add/SNSTopicArn").Value

# S3からJSONファイルを取得
$localJsonPath = "C:\Temp\group_users.json"
Read-S3Object -BucketName $S3Bucket -Key $S3Key -File $localJsonPath

# JSONをCSVに変換して保存
$json = Get-Content $localJsonPath | ConvertFrom-Json
$users = $json.Users
$csvPath = "D:\ops\office\register_office_userlist.csv"
$users | ForEach-Object { [PSCustomObject]@{ User = $_ } } | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# ADグループへの追加処理とログ出力
$resultLog = @()
foreach ($user in $users) {
    try {
        Add-ADGroupMember -Identity $GroupName -Members $user -DisablePermissiveModify $true
        $resultLog += "$user　成功"
    } catch {
        $resultLog += "$user　失敗　$_"
    }
}

# 結果ログを保存
$resultText = "【ADの $GroupName グループへの新規登録ユーザー追加結果】`n" + ($resultLog -join "`n")
$logPath = "D:\ops\office\register_office_userlist_result.txt"
Set-Content -Path $logPath -Value $resultText -Encoding UTF8
```

---

## 📣 SNS通知スクリプト（notifyResultステップ）

```powershell
# パラメーターストアからARN取得
$TopicArn = (Get-SSMParameterValue -Name "/ad/add/SNSTopicArn").Value

# ログメッセージ読み込み
$message = Get-Content -Path "D:\ops\office\register_office_userlist_result.txt" -Raw

# SNS通知（東京リージョン指定）
aws sns publish --topic-arn $TopicArn --message "$message" --region ap-northeast-1
```

---

## 🧠 パラメーターストアの構成例（String型）

| 名前                  | 値（例）                                                  |
| --------------------- | --------------------------------------------------------- |
| `/ad/add/S3Bucket`    | `my-ad-user-bucket`                                       |
| `/ad/add/S3Key`       | `office-users.json`                                       |
| `/ad/add/GroupName`   | `office-use`                                              |
| `/ad/add/SNSTopicArn` | `arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults` |

---

## ✅ 補足

- `Get-SSMParameterValue` は Systems Manager PowerShell モジュールの関数です。必要に応じて `Get-SSMParameter` に置き換えてください。★
- `D:\ops\office\` フォルダが存在しない場合は事前に作成しておくと安全です。
- IAMロールには `ssm:GetParameter` 権限も忘れずに付与してください。★

---

この構成なら、SSM Documentは固定のまま、環境に応じて柔軟に運用できます。  
さらに自動化を進めたい場合は、CloudWatch EventsやEventBridgeとの連携も可能です。  
次に進めたい方向があれば、ぜひ教えてください！

了解しました、崇史さん。  
以下に、**各ステップを単体で実行する方法**と、**それぞれの処理が正しく動作したかを確認する方法**をセットで詳しく解説します。

---

## 🧩 ステップ①：SSMパラメータストアから値を取得

### 🔧 実行コマンド（例）

```powershell
(Get-SSMParameter -Name "/ad/add/S3Bucket" -WithDecryption $true).Parameter.Value
```

※ `Get-SSMParameterValue` は一部のモジュールで定義されているため、標準では `Get-SSMParameter` を使用します。

### ✅ 確認方法

- 値が文字列として返ってくるか確認
- 例：`my-ad-user-bucket` が表示されればOK

---

## 🧩 ステップ②：S3からJSONファイルを取得

### 🔧 実行コマンド

```powershell
Read-S3Object -BucketName "my-ad-user-bucket" -Key "office-users.json" -File "C:\Temp\group_users.json"
```

※ AWS Tools for PowerShell が必要です。

### ✅ 確認方法

```powershell
Test-Path "C:\Temp\group_users.json"
```

- `True` が返ればファイル取得成功
- 内容確認：

```powershell
Get-Content "C:\Temp\group_users.json"
```

---

## 🧩 ステップ③：JSON → CSV変換して保存

### 🔧 実行コマンド

```powershell
$json = Get-Content "C:\Temp\group_users.json" | ConvertFrom-Json
$users = $json.Users
$users | ForEach-Object { [PSCustomObject]@{ User = $_ } } | Export-Csv -Path "D:\ops\office\register_office_userlist.csv" -NoTypeInformation -Encoding UTF8
```

### ✅ 確認方法

```powershell
Test-Path "D:\ops\office\register_office_userlist.csv"
```

- `True` が返ればCSV生成成功
- 内容確認：

```powershell
Import-Csv "D:\ops\office\register_office_userlist.csv"
```

---

## 🧩 ステップ④：ADグループへのユーザー追加

### 🔧 実行コマンド（1ユーザーずつテスト）

```powershell
Add-ADGroupMember -Identity "office-use" -Members "jdoe" -DisablePermissiveModify $true
```

※ `"jdoe"` は実在するADユーザー名に置き換えてください。

### ✅ 確認方法

```powershell
Get-ADGroupMember -Identity "office-use" | Where-Object { $_.SamAccountName -eq "jdoe" }
```

- 結果が表示されれば追加成功

---

## 🧩 ステップ⑤：ログ出力（成功/失敗）

### 🔧 実行コマンド（例）

```powershell
$resultLog = @("jdoe　成功", "asmith　失敗　ユーザーが存在しません")
$resultText = "【ADの office-use グループへの新規登録ユーザー追加結果】`n" + ($resultLog -join "`n")
Set-Content -Path "D:\ops\office\register_office_userlist_result.txt" -Value $resultText -Encoding UTF8
```

### ✅ 確認方法

```powershell
Get-Content "D:\ops\office\register_office_userlist_result.txt"
```

- ログ内容が整形されて表示されればOK

---

## 🧠 補足：事前準備チェックリスト

| チェック項目               | コマンド例                                    |
| -------------------------- | --------------------------------------------- |
| AWS PowerShellモジュール   | `Get-Module -ListAvailable AWS.Tools.S3`      |
| ADモジュール               | `Get-Module -ListAvailable ActiveDirectory`   |
| パラメータストアアクセス権 | IAMロールに `ssm:GetParameter` 付与済みか確認 |

---

このように、各ステップは単体で検証可能です。  
もしステップ間の依存関係を分離してテストしたい場合は、**モックデータや一時ファイル**を使っても安全に検証できます。  
次はどのステップを重点的にテストしたいですか？それに合わせてテストスクリプトも作成できますよ。

素晴らしいリクエストです、崇史さん。  
以下に、指定された PowerShell コマンドの **使い方・主要オプション** と、**AWS Tools for PowerShell が使える場合／使えない場合の代替手段**をそれぞれ詳しく解説します。

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

## 🧭 ② `Get-SSMParameterValue`（一部モジュールで提供）

### 🔧 使い方（同様の目的）

```powershell
(Get-SSMParameterValue -Name "/my/parameter").Value
```

※ `Get-SSMParameterValue` は AWS.Tools.Common モジュールに含まれる場合があります。標準では `Get-SSMParameter` を使う方が確実です。

---

## 🧭 ③ `Read-S3Object`（S3からファイル取得）

### 🔧 使い方

```powershell
Read-S3Object -BucketName "my-bucket" -Key "data.json" -File "C:\Temp\data.json"
```

### 🛠 主なオプション

| オプション    | 説明                                                     |
| ------------- | -------------------------------------------------------- |
| `-BucketName` | S3バケット名                                             |
| `-Key`        | オブジェクトキー（ファイル名）                           |
| `-File`       | 保存先のローカルパス                                     |
| `-Region`     | 明示的にリージョンを指定する場合（例：`ap-northeast-1`） |

---

## 🧭 ④ `Test-Path`（ファイルやフォルダの存在確認）

### 🔧 使い方

```powershell
Test-Path "C:\Temp\data.json"
```

### ✅ 出力

- `True` → 存在する
- `False` → 存在しない

---

## 🧭 ⑤ `Get-Content`（ファイルの内容を取得）

### 🔧 使い方

```powershell
Get-Content "C:\Temp\data.json"
```

### 🛠 主なオプション

| オプション  | 説明                                |
| ----------- | ----------------------------------- |
| `-Path`     | 対象ファイルのパス                  |
| `-Raw`      | ファイル全体を1つの文字列として取得 |
| `-Encoding` | 文字コード指定（例：`UTF8`）        |

---

## 🧭 ⑥ `Set-Content`（ファイルに内容を書き込む）

### 🔧 使い方

```powershell
Set-Content -Path "C:\Temp\result.txt" -Value "処理結果ログ" -Encoding UTF8
```

### 🛠 主なオプション

| オプション  | 説明                                             |
| ----------- | ------------------------------------------------ |
| `-Path`     | 出力先ファイルのパス                             |
| `-Value`    | 書き込む内容                                     |
| `-Encoding` | 文字コード指定（例：`UTF8`, `ASCII`, `Unicode`） |

---

## 🔄 AWS Tools for PowerShell が使えない場合の代替手段

| 処理              | AWS Tools 使用時               | 代替手段（CLI使用）                                              |
| ----------------- | ------------------------------ | ---------------------------------------------------------------- |
| SSMパラメータ取得 | `Get-SSMParameter`             | `aws ssm get-parameter --name "/my/parameter" --with-decryption` |
| S3ファイル取得    | `Read-S3Object`                | `aws s3 cp s3://my-bucket/data.json C:\Temp\data.json`           |
| SNS通知           | `Publish-SNSMessage`（非標準） | `aws sns publish --topic-arn ... --message ...`                  |

### 🔧 CLI出力をPowerShellに取り込む例

```powershell
$param = aws ssm get-parameter --name "/my/parameter" --with-decryption | ConvertFrom-Json
$param.Parameter.Value
```

---

## 🧠 補足：AWS CLI vs AWS Tools for PowerShell

| 特性     | AWS CLI                        | AWS Tools for PowerShell       |
| -------- | ------------------------------ | ------------------------------ |
| 記法     | JSONベース                     | PowerShellネイティブ           |
| 利用環境 | クロスプラットフォーム         | Windows/PowerShell向け         |
| 柔軟性   | 高い（スクリプト連携しやすい） | AD連携やオブジェクト操作に強い |

---

どちらを使うかは、環境やスクリプトの統一性によって選ぶのがベストです。  
もし AWS CLI ベースで統一したい場合は、すべての処理を CLI + PowerShell で組み直すことも可能です。  
ご希望があれば、CLIベースの完全版もご提案できますよ。どうしましょう？

AWS Tools for PowerShell のセットアップは、Windows 環境で AWS サービスを PowerShell から操作するための重要なステップです。以下に、**最新の推奨手順**を詳しくまとめました。

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

もし Linux や macOS 環境でのセットアップや、CI/CD パイプラインへの組み込み方法も知りたい場合は、そちらも詳しくご案内できますよ。どうしますか？

崇史さんのスクリプトは、すでにかなり良い構造になっています。  
結論から言うと、**`try { ... } catch { ... }` をループ内に使っているため、失敗してもループは止まりません**。  
つまり、**失敗したユーザーだけログに「失敗」と記録され、後続のユーザーの処理は継続されます**。

ただし、改善点としては：

- `$resultLog += "$user　失敗　$_"` の `$_` はオブジェクトなので、**エラーメッセージを明示的に文字列化**するとログが見やすくなります。
- 処理結果を **構造化されたログ形式（オブジェクトやCSV）** にすると、後で分析しやすくなります。

---

## ✅ 改良版スクリプト（失敗してもループ継続＋ログ明確化）

```powershell
$resultLog = @()

foreach ($user in $users) {
    try {
        Add-ADGroupMember -Identity $GroupName -Members $user -DisablePermissiveModify $true
        $resultLog += [PSCustomObject]@{
            User = $user
            Status = "成功"
            Message = ""
        }
    } catch {
        $resultLog += [PSCustomObject]@{
            User = $user
            Status = "失敗"
            Message = $_.Exception.Message
        }
    }
}

# ログ出力（例：CSV形式）
$resultLog | Export-Csv -Path "C:\Logs\ADGroupAddResults.csv" -NoTypeInformation -Encoding UTF8
```

---

## 🧠 補足：ループが止まるケース

PowerShell の `foreach` ループは、**catch ブロック内で `throw` を使わない限り停止しません**。  
もし `throw $_` を使っていた場合は、例外が再スローされてループが中断されます。

---

## 🔍 さらに堅牢にするなら…

- `Test-ADGroupMember` で事前に重複チェック
- `$user` が空文字や無効な形式でないかを `if` で検証
- ログにタイムスタンプを追加

---

この形式なら、失敗してもログに残り、後続ユーザーの処理も確実に実行されます。  
必要なら、**成功ユーザーだけ別ログに分ける**こともできますよ。  
CSVではなく JSON や S3 へのアップロード形式にしたい場合も対応できます。どうしましょう？