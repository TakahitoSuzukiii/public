# 🧩 要件整理

## 🎯 ユースケース
- ドメインユーザーがブラウザからWebサイトにアクセス
- ユーザー名とパスワードを入力して認証
- 認証後、セッション確認ボタンを押下
- 「セッション切断しますか？」のダイアログ表示 → OKで切断処理実行
- `D:/ops/server.csv` に記載されたインスタンスID群に対して、対象ユーザーのセッションを切断
- 全て成功したら「セッション切断が完了しました」と表示

## 💻 運用環境
- Web UI：ASP.NET Core（IISローカルホスト）
- サーバー群：AWS上の Windows Server 2016 / 2019
- セッション切断：AWS Systems Manager (SSM) + PowerShell
- サーバーリスト：S3に配置された `server.csv`
- 認証：簡易フォーム認証（将来的にAD連携も可）

---

# 🛠️ 構築手順（ASP.NET Core + IIS）

## 1. ASP.NET Core Webアプリの作成

```bash
dotnet new mvc -n SessionManagerWeb
cd SessionManagerWeb
```

- Razor PagesまたはMVCで構築
- 認証フォーム（Login.cshtml）とセッション確認画面（Dashboard.cshtml）を作成

## 2. 認証処理（簡易）

- `LoginController.cs` にてユーザー名とパスワードを検証
- 認証成功時にセッション情報を保持（`HttpContext.Session`）

## 3. セッション確認・切断画面

- `DashboardController.cs` にて「確認」ボタン押下時に `server.csv` を読み込み
- AWS SDK for .NET（boto3相当）で S3 から `server.csv` を取得
- 認証済みユーザー名を元に、SSMで各インスタンスに `logoff` コマンドを送信

## 4. PowerShellスクリプト（SSM経由）

```powershell
$query = query user
foreach ($line in $query) {
    $fields = $line -split '\s+'
    if ($fields[0] -eq 'USERNAME') { continue }
    if ($fields[0] -eq $env:USERNAME) {
        logoff $fields[1]
    }
}
```

## 5. IISローカルホスト運用

- IISにASP.NET Core Hosting Bundleをインストール  
  👉 [公式ガイド](https://learn.microsoft.com/ja-jp/aspnet/core/host-and-deploy/iis/?view=aspnetcore-8.0)
- アプリを発行 → IISの `Default Web Site` に配置
- アプリケーションプールを `.NET CLR Version: No Managed Code` に設定

---

# ☁️ AWS Amplifyとの連携（オプション）

## 利用目的
- フロントエンド（Vue.jsなど）をAmplifyでホスト
- バックエンド（ASP.NET）はIISで運用し、API Gateway経由で連携

## 構成例
- Vue.jsでSPA構築 → Amplify Hostingで公開
- API Gateway → Lambda → ASP.NET API（または直接IIS公開）
- 認証はCognito連携も可能

👉 [Amplify公式ドキュメント](https://docs.aws.amazon.com/ja_jp/amplify/latest/userguide/welcome.html)

---

# 📦 必要なドキュメント一覧

| ドキュメント名           | 内容                              |
| ------------------------ | --------------------------------- |
| `README.md`              | 全体構成とセットアップ手順        |
| `server.csv`             | インスタンスIDとホスト名の一覧    |
| `LoginController.cs`     | 認証処理                          |
| `DashboardController.cs` | セッション確認・切断処理          |
| `SessionManager.ps1`     | PowerShellスクリプト（SSM用）     |
| `appsettings.json`       | S3バケット名、AWS認証情報など     |
| `IIS_Deploy.md`          | IISへの配置手順                   |
| `Amplify_Integration.md` | Amplifyとの連携手順（オプション） |

---

# ✅ 運用ポイント

- **ログ管理**：切断結果をCloudWatch LogsまたはS3に保存
- **監査対応**：ユーザー操作ログを記録（IP、時刻、対象インスタンス）
- **セキュリティ**：フォーム認証はTLS必須。将来的にAD連携やCognito導入を検討
- **保守性**：PowerShellスクリプトはSSM Automation Document化して再利用性向上
