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

| 引数                       | 説明                                     |
| -------------------------- | ---------------------------------------- |
| `-Identity`                | グループの識別子（名前、DN、GUID、SID）  |
| `-Members`                 | 追加するメンバー（SAM名、DN、GUID、SID） |
| `-Server`                  | 操作対象のドメインコントローラー         |
| `-Credential`              | 実行に使用する資格情報（PSCredential）   |
| `-AuthType`                | 認証方式（Negotiate または Basic）       |
| `-Confirm`                 | 実行前に確認プロンプトを表示             |
| `-WhatIf`                  | 実行せずに結果をシミュレート             |
| `-DisablePermissiveModify` | 既存メンバー追加時にエラーを出す         |
| `-MemberTimeToLive`        | メンバーのTTL（一時的なメンバーシップ）  |
| `-Partition`               | ADパーティション指定（AD LDS用）         |
| `-PassThru`                | 結果オブジェクトを返す                   |

🔗 詳細は [Microsoft Learnの公式ドキュメント](https://learn.microsoft.com/en-us/powershell/module/activedirectory/add-adgroupmember?view=windowsserver2025-ps) を参照ください。

---

## 🛠️ `Remove-ADGroupMember` の主な引数

| 引数                       | 説明                                                  |
| -------------------------- | ----------------------------------------------------- |
| `-Identity`                | 対象グループ                                          |
| `-Members`                 | 削除するメンバー                                      |
| `-Confirm`                 | 削除前に確認プロンプト（`-Confirm:$false`で省略可能） |
| `-Credential`              | 実行資格情報                                          |
| `-Server`                  | ドメインコントローラー指定                            |
| `-DisablePermissiveModify` | 非メンバー削除時にエラーを出す                        |
| `-AuthType`                | 認証方式                                              |
| `-Partition`               | ADパーティション指定（AD LDS用）                      |
| `-PassThru`                | 結果オブジェクトを返す                                |
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


