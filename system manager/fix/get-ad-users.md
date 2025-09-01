了解です、崇史さん。Windows Server 2016環境で、Active Directoryの特定ドメインに属するユーザー一覧を取得するには、PowerShellの `Get-ADUser` コマンドレットが基本になります。以下に、典型的なパターンと応用例をいくつかご紹介します。

---

### 🧩 基本構文：特定ドメインのユーザー一覧取得

```powershell
Get-ADUser -Filter * -Server "yourdomain.local" | Select-Object Name, SamAccountName
```

- `-Filter *`：すべてのユーザーを対象
- `-Server`：対象ドメインコントローラーまたはドメイン名を指定（FQDN形式が推奨）
- `Select-Object`：必要な属性だけ抽出（例：名前とSAMアカウント）

---

### 🔍 応用：OU単位で絞り込み

```powershell
Get-ADUser -Filter * -SearchBase "OU=Users,DC=yourdomain,DC=local" -Server "yourdomain.local" | Select Name, SamAccountName
```

- `-SearchBase`：特定のOUに限定
- OU構造が複雑な場合は、`Get-ADOrganizationalUnit` で探索可能

---

### 📋 さらに詳細な属性を取得したい場合

```powershell
Get-ADUser -Filter * -Server "yourdomain.local" -Properties DisplayName, EmailAddress, Department | Select DisplayName, EmailAddress, Department
```

- `-Properties`：標準以外の属性を明示的に指定
- 監査やレポート用途に便利

---

### 📦 CSV出力（自動化・ドキュメント化向け）

```powershell
Get-ADUser -Filter * -Server "yourdomain.local" | Select Name, SamAccountName | Export-Csv "C:\ADUsers.csv" -NoTypeInformation -Encoding UTF8
```

---

### 🛡️ 補足：クロスドメイン環境での注意点

- `-Server` に指定するドメインは、信頼関係がある必要があります
- 実行ユーザーの権限が対象ドメインに及んでいるか確認
- 複数ドメインを横断する場合は、スクリプト化してループ処理が有効です

---

もし、ユーザーの有効/無効状態やログオン情報、グループ所属なども含めて抽出したい場合は、さらに属性を追加できます。ご希望があれば、Markdown形式のドキュメントテンプレートもご提供できますよ。

次は、ユーザーのフィルタリング（例：特定部署、ログオン履歴あり、無効ユーザー除外など）について掘り下げましょうか？