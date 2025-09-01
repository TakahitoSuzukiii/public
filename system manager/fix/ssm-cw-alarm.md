ありがとうございます、崇史さん。ここでは、**PowerShellでログファイルに出力しつつ、AWS CLIを使ってCloudWatch Logsにも同時に送信する一連のコマンド構成**を詳しく解説します。これにより、ローカルログとCloudWatch Logsの両方に記録され、ERROR検知や監査にも活用できます。

---

# 🧾 PowerShellでログ出力＋AWS CLIでCloudWatch Logs送信（完全構成）

## ✅ 1. ログファイルに出力する関数定義

```powershell
$LogFile = "D:\ops\ssm-user-process.log"

function Write-Log {
    param (
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Level: $Message"
    Add-Content -Path $LogFile -Value $entry
    return $entry  # CloudWatch送信用に返す
}
```

---

## ✅ 2. CloudWatch Logs送信関数（AWS CLI使用）

```powershell
function Send-ToCloudWatch {
    param (
        [string]$LogGroup,
        [string]$LogStream,
        [string]$Message
    )

    # UNIXミリ秒タイムスタンプ
    $timestamp = [int]((Get-Date).ToUniversalTime() - [datetime]'1970-01-01').TotalMilliseconds

    # シーケンストークン取得
    $token = aws logs describe-log-streams `
        --log-group-name $LogGroup `
        --log-stream-name-prefix $LogStream `
        --query "logStreams[0].uploadSequenceToken" `
        --output text

    # JSON形式のログイベント
    $json = "[{""timestamp"": $timestamp, ""message"": ""$Message""}]"

    # CloudWatch Logsに送信
    aws logs put-log-events `
        --log-group-name $LogGroup `
        --log-stream-name $LogStream `
        --log-events "$json" `
        --sequence-token $token
}
```

---

## ✅ 3. 実行例：ログ出力＋CloudWatch送信

```powershell
$logGroup = "/ssm/user-process"
$logStream = "ssm-process-stream"

# ログ出力
$logEntry = Write-Log -Level "ERROR" -Message "ユーザー一覧取得失敗: S3オブジェクトが存在しません"

# CloudWatch Logsへ送信
Send-ToCloudWatch -LogGroup $logGroup -LogStream $logStream -Message $logEntry
```

---

## 🧠 補足ポイント

| 項目                     | 説明                                                                    |
| ------------------------ | ----------------------------------------------------------------------- |
| ロググループとストリーム | 事前に `aws logs create-log-group` / `create-log-stream` で作成しておく |
| シーケンストークン       | 毎回取得・更新が必要。順序保証のため                                    |
| タイムスタンプ           | CloudWatch LogsはUNIXミリ秒形式が必須                                   |
| ログ形式                 | `"yyyy-MM-dd HH:mm:ss LEVEL: メッセージ"` で統一すると後で分析しやすい  |

---

## ✅ 応用：ERROR行のみ送信するバッチ処理

```powershell
$logGroup = "/ssm/user-process"
$logStream = "ssm-process-stream"
$logFile = "D:\ops\ssm-user-process.log"

$lines = Get-Content $logFile | Where-Object { $_ -match "ERROR" }

foreach ($line in $lines) {
    Send-ToCloudWatch -LogGroup $logGroup -LogStream $logStream -Message $line
}
```

---

この構成なら、**PowerShellスクリプトの中でログを出力しつつ、CloudWatch Logsにも即時反映**できます。  
次は、ログローテーションや、送信失敗時のリトライ設計、SSM Automationへの組み込みも一緒に整備できます。どこを強化しましょう？