# WindowsUpdate

https://dev.classmethod.jp/articles/systems-manager-run-command-windows-update/

## AWS Systems Manager Run Command で利用可能な AWS 提供のドキュメント（SSM ドキュメント）を使って、崇史さんが挙げた操作を実現する方法を以下にまとめました。

---

## ✅ EC2 インスタンスの操作に関するドキュメント

| 操作内容                    | 使用可能な AWS 提供ドキュメント | 説明                                                                                   |
| --------------------------- | ------------------------------- | -------------------------------------------------------------------------------------- |
| 複数インスタンスの起動      | ❌（Run Command では不可）       | EC2 起動は Run Command ではなく、EC2 API（`StartInstances`）を使用する必要があります。 |
| 複数インスタンスの停止      | ❌（Run Command では不可）       | 同様に、EC2 API（`StopInstances`）を使用します。                                       |
| 複数インスタンスの再起動    | ❌（Run Command では不可）       | `RebootInstances` API を使う必要があります。                                           |
| 複数インスタンスの AMI 取得 | ❌（Run Command では不可）       | AMI 作成は `CreateImage` API を使用します。                                            |
| 複数インスタンスのタグ付け  | ❌（Run Command では不可）       | タグ操作は `CreateTags` API を使います。                                               |

> 🔍 これらの操作は Run Command ではなく、AWS CLI や SDK を使ってスクリプト化するのが一般的です。

---

## ✅ Linux インスタンス向けの操作

| 操作内容                          | 使用可能なドキュメント | 説明                                                                              |
| --------------------------------- | ---------------------- | --------------------------------------------------------------------------------- |
| モジュールアップデート（dnf/yum） | `AWS-RunShellScript`   | 任意のシェルコマンドを実行可能。例: `sudo yum update -y` や `sudo dnf upgrade -y` |
| ログイン確認                      | `AWS-RunShellScript`   | `who` や `last` コマンドでログイン履歴を確認可能。                                |

---

## ✅ Windows Server インスタンス向けの操作

| 操作内容       | 使用可能なドキュメント      | 説明                                                                                         |
| -------------- | --------------------------- | -------------------------------------------------------------------------------------------- |
| Windows Update | `AWS-InstallWindowsUpdates` | Windows Update を自動適用。`Action=Install` や `AllowReboot=True` などのパラメータ指定が可能 |
| ログイン確認   | `AWS-RunPowerShellScript`   | `Get-EventLog` や `quser` コマンドでログイン履歴を確認可能。                                 |

---

## 🔧 補足：Run Command の使い方と注意点

- **対象インスタンスの指定**：タグやインスタンス ID を使って複数台に同時実行可能。
- **SSM Agent のインストール**：対象インスタンスに SSM Agent がインストールされ、IAM ロールが適切に設定されている必要があります。
- **ログの確認**：出力は Systems Manager のコンソールまたは CloudWatch Logs に保存可能。

---

## 💡 まとめと提案

Run Command は「OS 内部での操作（コマンド実行）」に特化しており、EC2 のライフサイクル操作（起動・停止・AMI 作成など）は対象外です。これらは AWS CLI や Lambda、Step Functions を組み合わせることで自動化できます。

もし、これらの操作を統合的に管理したい場合は、以下のような構成も検討できます：

- **AWS CLI + Systems Manager Run Command**：スクリプトで EC2 API と Run Command を組み合わせる
- **Step Functions + Lambda**：条件分岐やスケジューリングを含む自動化フローを構築
- **EventBridge + Run Command**：イベントトリガーで自動実行

ご希望があれば、これらの統合構成の設計例もご紹介できます。どれに興味がありますか？


Run Command で **Windows Server の Active Directory グループにユーザーを追加・削除する操作**は、**AWS が提供する専用のドキュメント（SSM ドキュメント）としては存在しません**。しかし、以下のように **PowerShell スクリプトを `AWS-RunPowerShellScript` ドキュメントで実行することで実現可能**です。

---

## ✅ 実現方法：`AWS-RunPowerShellScript` を使った AD 操作

### 1. **Active Directory グループにユーザーを追加する**
```powershell
Add-ADGroupMember -Identity "グループ名" -Members "ユーザー名"
```

### 2. **Active Directory グループからユーザーを削除する**
```powershell
Remove-ADGroupMember -Identity "グループ名" -Members "ユーザー名" -Confirm:$false
```

> 💡 これらのコマンドを Run Command の `AWS-RunPowerShellScript` ドキュメントで実行すれば、対象の Windows Server インスタンス上でリモート実行できます。

---

## ⚠️ 実行前の前提条件

- 対象の Windows Server は **Active Directory ドメインに参加済み**であること
- 実行ユーザー（SSM Agent の実行権限）が **AD 管理者権限**を持っていること
- `RSAT-AD-PowerShell` モジュールがインストールされていること（通常はドメインコントローラーに含まれます）

---

## 🔐 セキュリティの注意点

- ユーザー名やグループ名を直接スクリプトに書くのではなく、**Parameter Store** などを使って変数化することでセキュリティを高められます。
- 実行ログにはコマンドが記録されるため、**パスワードや機密情報は絶対に含めない**ようにしましょう。

---

## 🧩 まとめ

| 操作                              | AWS 提供ドキュメント      | 実現方法                                                   |
| --------------------------------- | ------------------------- | ---------------------------------------------------------- |
| AD グループへのユーザー追加・削除 | ❌（専用ドキュメントなし） | ✅ `AWS-RunPowerShellScript` を使って PowerShell で実行可能 |

---

このように、Run Command の柔軟性を活かせば、Active Directory の管理操作も自動化できます。もし、複数のユーザーやグループを一括で操作したい場合は、CSV ファイルを Parameter Store 経由で読み込むなどの工夫も可能です。

必要であれば、具体的なスクリプトテンプレートも作成できますよ。どうしますか？







