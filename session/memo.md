爆速で構築するために、以下のようなアーキテクチャと技術スタックを提案します。セッション切断機能を持つWebサイトを最小構成で実現しつつ、セキュリティと運用性も確保します。

---

## 🚀 全体構成概要

| コンポーネント | 技術                        | 役割                                                 |
| -------------- | --------------------------- | ---------------------------------------------------- |
| Web UI         | Flask + HTML/CSS/JS         | ユーザー認証・セッション確認・切断操作               |
| 認証           | Flask-Login or BasicAuth    | ユーザーID/パスワード認証                            |
| バックエンド   | Python + boto3 + PowerShell | S3からCSV取得、対象サーバー抽出、セッション切断      |
| サーバー情報   | S3 (server.csv)             | 対象インスタンスIDのリスト保持                       |
| セッション切断 | AWS SSM + PowerShell        | 各Windows Serverに対してセッション切断コマンドを実行 |

---

## 🧱 ステップ別構築ガイド

### ① FlaskベースのWebアプリ構築

- Flaskでフォーム付きのWebページを作成
- 認証は `flask-httpauth` または `Flask-Login` を使用
- HTMLテンプレートはJinja2で構築

参考: [QiitaのFlask入門記事](https://qiita.com/t-iguchi/items/f7847729631022a5041f)

### ② 認証処理

- ユーザーIDとパスワードは一旦ハードコード（後でDB連携可）
- 認証成功後、セッション確認ボタンを表示
- JavaScriptで「セッション切断しますか？」のダイアログ表示

### ③ S3からCSV取得 → 対象インスタンス抽出

```python
import boto3
import csv

def get_instance_ids_from_s3(bucket, key):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=bucket, Key=key)
    lines = response['Body'].read().decode('utf-8').splitlines()
    reader = csv.DictReader(lines)
    return [row['instance_id'] for row in reader]
```

参考: [S3のファイル操作まとめ](https://qiita.com/c60evaporator/items/da47620d69f84a9be7dc)

### ④ AWS SSMでセッション切断コマンド実行

- PowerShellコマンド例（SSM経由）:

```powershell
query user | ForEach-Object {
    $fields = $_ -split '\s+'
    if ($fields[0] -ne 'USERNAME') {
        logoff $fields[1]
    }
}
```

- PythonからSSM Automation実行:

```python
ssm = boto3.client('ssm')
for instance_id in instance_ids:
    ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName='AWS-RunPowerShellScript',
        Parameters={'commands': [powershell_script]},
    )
```

- 成功判定は `CommandId` で `GetCommandInvocation` を使って確認

---

## ✅ 成功メッセージ表示

- 全インスタンスで `Status == 'Success'` を確認後、Webページに「セッション切断が完了しました」と表示

---

## 🔐 セキュリティと運用のポイント

- 認証情報は環境変数またはAWS Secrets Managerで管理
- S3のserver.csvはIAMポリシーでアクセス制限
- SSM実行権限は最小権限でIAMロールに付与
- ログはCloudWatch Logsに送信（監査対応）

---

## 🧪 テストとデプロイ

- ローカルでFlaskアプリをテスト
- EC2（Amazon Linux）にFlaskアプリをデプロイ
- `gunicorn + nginx` で本番運用も可能

---

## ✨ 追加アイデア（拡張性）

- ユーザーごとのセッション履歴表示
- 切断ログをS3またはCloudWatch Logsに保存
- AD連携によるユーザー認証強化（LDAP over SSL）

---

必要なら、FlaskのテンプレートコードやSSM Automation DocumentのYAMLも一緒に作成できます。どこから着手したいですか？