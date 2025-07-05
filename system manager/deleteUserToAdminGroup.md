# 🧑‍💼 Active Directory グループメンバー削除 自動化タスク構成資料  
（JSON指定：testdomain.com / testgroup / testuser / delete）

---

## 📌 タスク概要

| 項目     | 内容                                                                |
| -------- | ------------------------------------------------------------------- |
| タスク名 | ManageADGroupMembershipFromJson (delete)                            |
| 対象     | Active Directory ドメイン `testdomain.com` 上のグループ `testgroup` |
| 実行内容 | ユーザー `testuser` をグループから削除                              |
| 実行方法 | AWS Systems Manager Automation による任意実行                       |
| 入力形式 | JSONファイル（S3 URIで指定）                                        |
| 通知     | 実行完了後に Microsoft Teams とメール（SNS）に結果を送信            |

---

## 🧾 JSON ファイル（削除操作）

```json
{
  "domain": "testdomain.com",
  "group": "testgroup",
  "user": "testuser",
  "action": "remove"
}
```

> ✅ `"action": "remove"` によって、Automation ドキュメントは削除処理を実行します。

---

## 📄 Automation ドキュメント（共通構成）

Automation ドキュメントは、JSONファイルの `action` フィールドに応じて処理を分岐します：

```powershell
if ($action -eq "add") {
  Add-ADGroupMember -Identity $group -Members $user -Server $domain
  Write-Host "$user added to $group"
} elseif ($action -eq "remove") {
  Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false -Server $domain
  Write-Host "$user removed from $group"
} else {
  throw "Invalid action: $action"
}
```

この構成により、同じ Automation ドキュメントで `"add"` と `"remove"` の両方に対応できます。

---

## 📬 通知例（Teams / メール）

```
✅ SSM Automation タスク完了: ManageADGroupMembershipFromJson
📊 実行結果:
Domain: testdomain.com
Group: testgroup
User: testuser
Action: remove
Status: Success
```

---

## ✅ まとめ（削除操作）

| 項目         | 内容                                                  |
| ------------ | ----------------------------------------------------- |
| ドメイン     | testdomain.com                                        |
| グループ     | testgroup                                             |
| ユーザー     | testuser                                              |
| アクション   | remove（グループから削除）                            |
| 実行形式     | JSONファイルを S3 に格納し、Automation で読み取り実行 |
| 通知         | Lambda 経由で SNS + Teams に送信                      |
| セキュリティ | IAM制御、スキーマ検証、S3暗号化、監査ログ             |
