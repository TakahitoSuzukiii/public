了解です、崇史さん。S3のバージョニングとライフサイクル管理は、コスト最適化とデータ保持戦略の要です。以下に、**6か月で削除するライフサイクルルールの設定方法**と、**バージョン取得・バックアップ・リストアの手順**を詳しく解説します。

---

## 🗑️ ライフサイクルルール：6か月で削除する設定

S3では「現行バージョン」と「非現行バージョン（旧バージョン）」に対して個別にルールを設定できます。

### ✅ JSON形式のライフサイクル設定例

```json
{
  "Rules": [
    {
      "ID": "DeleteCurrentAndPreviousVersionsAfter180Days",
      "Status": "Enabled",
      "Prefix": "",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 180
      },
      "Expiration": {
        "Days": 180
      }
    }
  ]
}
```

- `Expiration.Days`: 現行バージョンを180日後に削除（削除マーカーが付く）
- `NoncurrentVersionExpiration.NoncurrentDays`: 非現行バージョンを180日後に完全削除

### 🛠️ 設定方法（AWS CLI）

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-bucket-name \
  --lifecycle-configuration file://lifecycle.json
```

※ `lifecycle.json` は上記JSONを保存したファイル

---

## 📦 バージョン取得・バックアップ・リストア方法

### 🔍 1. バージョン一覧の取得

```bash
aws s3api list-object-versions --bucket your-bucket-name --prefix your-object-key
```

出力例（簡略）:

```json
{
  "Versions": [
    {
      "Key": "example.txt",
      "VersionId": "3HL4kqtJlcpXroDTDmjVBH40Nrjfkd",
      "IsLatest": true
    },
    {
      "Key": "example.txt",
      "VersionId": "2sT4kqtJlcpXroDTDmjVBH40Nrjfkd",
      "IsLatest": false
    }
  ]
}
```

---

### 💾 2. 特定バージョンのバックアップ（別バケットや別キーへコピー）

```bash
aws s3api copy-object \
  --bucket backup-bucket-name \
  --copy-source your-bucket-name/example.txt?versionId=2sT4kqtJlcpXroDTDmjVBH40Nrjfkd \
  --key backup/example.txt
```

---

### 🔄 3. リストア（旧バージョンを現行に戻す）

```bash
aws s3api copy-object \
  --bucket your-bucket-name \
  --copy-source your-bucket-name/example.txt?versionId=2sT4kqtJlcpXroDTDmjVBH40Nrjfkd \
  --key example.txt
```

この操作により、指定した旧バージョンが新しい現行バージョンとして再登録されます。

---

## 🧠 補足とベストプラクティス

- 削除マーカーが付いたオブジェクトは `GET` できませんが、削除マーカーを削除すれば旧バージョンが復活します
- バージョニングされたオブジェクトは、**完全に削除しない限り復元可能**です
- ライフサイクルルールは **1日1回のバッチ処理**で適用されます（日本時間では午前9時頃）
- 削除マーカーにも課金が発生するため、**期限切れ削除マーカーの削除ルール**も併用推奨

---

必要であれば、Markdown形式の運用ガイドやSSM Automation連携のテンプレートもご提供できます。次は、削除マーカーの管理や、Glacier移行との併用について掘り下げてみましょうか？