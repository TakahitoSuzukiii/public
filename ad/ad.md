# ActiveDirectory関連

## 🧩 主なADグループ操作コマンド

| コマンド                            | 説明                                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| `Add-ADGroupMember`                 | グループにユーザー・コンピューター・サービスアカウントを追加 |
| `Remove-ADGroupMember`              | グループからメンバーを削除                                   |
| `Get-ADGroupMember`                 | グループの現在のメンバー一覧を取得                           |
| `Add-ADPrincipalGroupMembership`    | ユーザー・コンピューターを複数グループに一括追加             |
| `Remove-ADPrincipalGroupMembership` | ユーザー・コンピューターを複数グループから一括削除           |

---

## 🛠️ `Add-ADGroupMember` の主な引数

| 引数                       | 説明                                       |
| -------------------------- | ------------------------------------------ |
| `-Identity`                | グループの識別子（名前、DN、GUID、SID） ★  |
| `-Members`                 | 追加するメンバー（SAM名、DN、GUID、SID） ★ |
| `-Server`                  | 操作対象のドメインコントローラー （★）     |
| `-Credential`              | 実行に使用する資格情報（PSCredential）     |
| `-AuthType`                | 認証方式（Negotiate または Basic）         |
| `-Confirm`                 | 実行前に確認プロンプトを表示               |
| `-WhatIf`                  | 実行せずに結果をシミュレート               |
| `-DisablePermissiveModify` | 既存メンバー追加時にエラーを出す ★         |
| `-MemberTimeToLive`        | メンバーのTTL（一時的なメンバーシップ）    |
| `-Partition`               | ADパーティション指定（AD LDS用）           |
| `-PassThru`                | 結果オブジェクトを返す ★                   |

🔗 詳細は [Microsoft Learnの公式ドキュメント](https://learn.microsoft.com/en-us/powershell/module/activedirectory/add-adgroupmember?view=windowsserver2025-ps) を参照ください。

## 🛠 使用例：`Add-ADGroupMember` のフルオプション指定

```powershell
Add-ADGroupMember `
  -Identity "CN=DevTeam,OU=Groups,DC=example,DC=com" `
  -Members "jdoe", "CN=svcApp,OU=ServiceAccounts,DC=example,DC=com" `
  -Server "DC01.example.com" `
  -DisablePermissiveModify `
  -PassThru
```

## 🔍 各引数の詳細と使い方

| 引数                       | 説明                                                                                                                         | 使用例                                                                          |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `-Identity`                | 追加対象のグループを識別します。名前（SAM名）、DN（識別名）、GUID、SID のいずれかで指定可能。                                | `"CN=DevTeam,OU=Groups,DC=example,DC=com"`（DN形式）                            |
| `-Members`                 | 追加するメンバーの識別子。複数指定可能。ユーザー名（SAM名）、DN、GUID、SID など。                                            | `"jdoe"`（SAM名）、`"CN=svcApp,OU=ServiceAccounts,DC=example,DC=com"`（DN形式） |
| `-Server`                  | 操作対象のドメインコントローラーを指定。複数DCがある環境で、特定のDCに対して操作したい場合に使用。                           | `"DC01.example.com"`                                                            |
| `-DisablePermissiveModify` | 既にメンバーであるオブジェクトを再度追加しようとした場合、通常は無視されますが、このオプションを指定するとエラーになります。 | `-DisablePermissiveModify`（スイッチ型）                                        |
| `-PassThru`                | コマンドの結果として、追加されたオブジェクトを返します。スクリプト内で後続処理に使いたい場合に便利。                         | `-PassThru`（スイッチ型）                                                       |

## ✅ 実行結果の例（`-PassThru` 使用時）

```powershell
DistinguishedName : CN=jdoe,CN=Users,DC=example,DC=com
Name              : jdoe
ObjectClass       : user
ObjectGUID        : 12345678-90ab-cdef-1234-567890abcdef
```

## 🧭 AD ユーザーのログオン名の種類

| 表示名                                  | 実体                       | 例                 | 説明                                                                   |
| --------------------------------------- | -------------------------- | ------------------ | ---------------------------------------------------------------------- |
| ユーザー ログオン名（pre-Windows 2000） | `SAMAccountName`           | `jdoe`             | NetBIOS形式で、`DOMAIN\jdoe` のように使われる。                        |
| ユーザー ログオン名                     | `UserPrincipalName`（UPN） | `jdoe@example.com` | 通常のメール形式。`@` の前半が `SAMAccountName` と一致することが多い。 |

---

## ✅ 一致するかどうかの確認方法

```powershell
Get-ADUser -Identity jdoe | Select-Object SamAccountName, UserPrincipalName
```

### 🔍 出力例
```text
SamAccountName     : jdoe
UserPrincipalName  : jdoe@example.com
```

このように、**UPN の @ の前半部分（`jdoe`）が SAMAccountName（`jdoe`）と一致している**のが一般的です。

---

## 🛠️ `Remove-ADGroupMember` の主な引数

| 引数                       | 説明                                                  |
| -------------------------- | ----------------------------------------------------- |
| `-Identity`                | 対象グループ ★                                        |
| `-Members`                 | 削除するメンバー ★                                    |
| `-Confirm`                 | 削除前に確認プロンプト（`-Confirm:$false`で省略可能） |
| `-Credential`              | 実行資格情報                                          |
| `-Server`                  | ドメインコントローラー指定 （★）                      |
| `-DisablePermissiveModify` | 非メンバー削除時にエラーを出す ★                      |
| `-AuthType`                | 認証方式                                              |
| `-Partition`               | ADパーティション指定（AD LDS用）                      |
| `-PassThru`                | 結果オブジェクトを返す ★                              |
| `-WhatIf`                  | 実行せずに結果をシミュレート                          |

🔗 詳細は [Remove-ADGroupMember の公式ドキュメント](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adgroupmember?view=windowsserver2025-ps) を参照ください。

---

## 🧠 補足：識別子の指定方法

`-Members` 引数では以下の形式が使用可能です：

- Distinguished Name（例：`CN=John Doe,OU=Users,DC=example,DC=com`）
- SAMAccountName（例：`jdoe`）
- GUID（例：`{12345678-1234-1234-1234-1234567890ab}`）
- SID（例：`S-1-5-21-...`）

---

了解しました、崇史さん。`-DisablePermissiveModify` を `true` に指定することで、**既にグループに存在するメンバーの追加**や、**存在しないメンバーの削除**を行おうとした際に、**エラーを発生させる**ことができます。これは、冪等性を排除して、明示的な状態変更のみを許容したい場合に有効です。

以下に、`Add-ADGroupMember` および `Remove-ADGroupMember` に `-DisablePermissiveModify $true` を指定した例を複数提示します。

---

## 🧩 Add-ADGroupMember の使用例（`-DisablePermissiveModify $true`）

### ✅ 例1：単一ユーザー追加（冗長な追加を防止）

```powershell
Add-ADGroupMember -Identity "SalesTeam" -Members "user01" -DisablePermissiveModify $true
```

- `user01` が既に `SalesTeam` に所属している場合、エラーになります。

---

### ✅ 例2：複数ユーザー追加（明示的に新規追加）

```powershell
Add-ADGroupMember -Identity "ITAdmins" -Members "admin01", "admin02" -DisablePermissiveModify $true
```

- どちらかが既にメンバーであれば、コマンド全体が失敗します。

---

## 🧩 Remove-ADGroupMember の使用例（`-DisablePermissiveModify $true`）

### ✅ 例1：単一ユーザー削除（存在しない場合はエラー）

```powershell
Remove-ADGroupMember -Identity "SalesTeam" -Members "user01" -DisablePermissiveModify $true -Confirm:$false
```

- `user01` がメンバーでない場合、エラーになります。

---

### ✅ 例2：複数ユーザー削除（厳密な状態管理）

```powershell
Remove-ADGroupMember -Identity "DevOpsTeam" -Members "dev01", "dev02" -DisablePermissiveModify $true -Confirm:$false
```

- どちらかがメンバーでない場合、削除処理は失敗します。

---

了解しました、崇史さん。`Get-ADGroupMember` は Active Directory グループの現在のメンバー（ユーザー、コンピューター、グループなど）を取得するための基本コマンドです。以下に **主要なオプションの詳細** と、**指定グループ（例：`office-use`）のメンバー一覧取得方法**を具体的に解説します。

---

## 🧭 `Get-ADGroupMember` の主要オプション一覧

| オプション    | 説明                                               | 使用例                                                         |
| ------------- | -------------------------------------------------- | -------------------------------------------------------------- |
| `-Identity`   | 対象のグループを指定（名前、DN、GUID、SID）        | `"office-use"` / `"CN=office-use,OU=Groups,DC=example,DC=com"` |
| `-Recursive`  | ネストされたグループのメンバーも含めて取得         | `-Recursive`（スイッチ型）                                     |
| `-Server`     | 操作対象のドメインコントローラーを指定             | `"DC01.example.com"`                                           |
| `-Partition`  | 特定のディレクトリパーティションを指定（通常不要） | `"CN=Configuration,DC=example,DC=com"`                         |
| `-AuthType`   | 認証方式を指定（`Negotiate` または `Basic`）       | `-AuthType Negotiate`                                          |
| `-Credential` | 別のユーザー資格情報で実行                         | `-Credential (Get-Credential)`                                 |

---

## 🧪 使用例：`office-use` グループのメンバー一覧を取得

```powershell
Get-ADGroupMember -Identity "office-use"
```

### 🔍 出力例
```text
DistinguishedName : CN=jdoe,CN=Users,DC=example,DC=com
Name              : jdoe
ObjectClass       : user
ObjectGUID        : 12345678-90ab-cdef-1234-567890abcdef
```

---

## 🧠 より詳しく取得したい場合（ユーザー属性付き）

```powershell
Get-ADGroupMember -Identity "office-use" | Where-Object { $_.ObjectClass -eq "user" } | Get-ADUser -Properties DisplayName, EmailAddress
```

### 🔍 出力例
```text
DisplayName   EmailAddress
------------  ---------------------
John Doe      jdoe@example.com
Alice Smith   asmith@example.com
```

---

## 🔁 ネストされたグループも含めたい場合

```powershell
Get-ADGroupMember -Identity "office-use" -Recursive
```

これにより、`office-use` に含まれる他のグループのメンバーもすべて展開して取得できます。

---

## 🧪 ドメインコントローラーを指定して取得

```powershell
Get-ADGroupMember -Identity "office-use" -Server "DC01.example.com"
```

これは複数DCがある環境で、特定のDCに対してクエリを実行したい場合に有効です。

---

## 🧰 応用：CSV形式でエクスポートする例

```powershell
Get-ADGroupMember -Identity "office-use" |
  Where-Object { $_.ObjectClass -eq "user" } |
  Get-ADUser -Properties DisplayName, EmailAddress |
  Select-Object DisplayName, EmailAddress |
  Export-Csv -Path "office-use-members.csv" -NoTypeInformation
```

---

必要であれば、OUごとのグループメンバー一覧取得や、変更履歴のログ出力なども自動化できます。どんな運用に組み込みたいか、ぜひ教えてください。もっと深掘りできますよ。

了解です、崇史さん。`Get-ADGroupMember -Identity "office-use"` を使って複数ユーザーが所属している場合の出力例と、それを `D:\ops\office\` に CSV 形式で保存する方法を以下に詳しく解説します。

---

## 📤 コマンド出力例（複数ユーザーが所属している場合）

```powershell
Get-ADGroupMember -Identity "office-use"
```

### 🔍 出力例（PowerShell コンソール上）

```text
DistinguishedName : CN=jdoe,CN=Users,DC=example,DC=com
Name              : jdoe
ObjectClass       : user
ObjectGUID        : 11111111-aaaa-bbbb-cccc-111111111111

DistinguishedName : CN=asmith,CN=Users,DC=example,DC=com
Name              : asmith
ObjectClass       : user
ObjectGUID        : 22222222-bbbb-cccc-dddd-222222222222

DistinguishedName : CN=btanaka,CN=Users,DC=example,DC=com
Name              : btanaka
ObjectClass       : user
ObjectGUID        : 33333333-cccc-dddd-eeee-333333333333
```

このように、各メンバーの基本情報（名前、オブジェクトクラス、GUIDなど）が表示されます。

---

## 📁 CSV形式で `D:\ops\office\` に出力する方法

以下のスクリプトを使えば、**ユーザーのみを抽出し、表示名とメールアドレスを含めて CSV に保存**できます。

```powershell
# グループメンバーを取得し、ユーザーのみを抽出して詳細情報を取得
Get-ADGroupMember -Identity "office-use" |
  Where-Object { $_.ObjectClass -eq "user" } |
  Get-ADUser -Properties DisplayName, EmailAddress |
  Select-Object Name, DisplayName, EmailAddress |
  Export-Csv -Path "D:\ops\office\office-use-members.csv" -NoTypeInformation -Encoding UTF8
```

### 📄 出力されるCSVの内容（例）

```csv
Name,DisplayName,EmailAddress
jdoe,John Doe,jdoe@example.com
asmith,Alice Smith,asmith@example.com
btanaka,田中 勉,btanaka@example.com
```

---

## ✅ 補足ポイント

- `Export-Csv` の `-Encoding UTF8` は日本語名（例：田中 勉）を含む場合に文字化け防止に有効です。
- `Select-Object` で必要な属性だけを抽出することで、CSVが見やすくなります。
- `D:\ops\office\` フォルダが存在しない場合は、事前に `New-Item -ItemType Directory` で作成しておくと安全です。

---

必要なら、グループごとにループ処理して一括出力するスクリプトも作成できますよ。運用に合わせてカスタマイズしましょうか？