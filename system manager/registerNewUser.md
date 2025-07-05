# 🛠️ AWS Systems Manager 自動化タスク構成（2025年版）

## 📁 タスク①：registerNewUser  
新規ユーザーを作成し、指定された公開鍵を `authorized_keys` に登録するAutomationドキュメント。

### ✅ 機能概要

- 任意のユーザー名を指定して作成
- 公開鍵を `.ssh/authorized_keys` に登録
- 所有権とパーミッションを適切に設定

### 🧩 Automation Document（registerNewUser）

```yaml
schemaVersion: '0.3'
description: "Create a new user and register SSH public key"
parameters:
  username:
    type: String
    description: "New user to create"
  sshPublicKey:
    type: String
    description: "SSH public key to add"
mainSteps:
  - name: createUserAndAddKey
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunShellScript
      Parameters:
        commands:
          - |
            set -e
            sudo useradd -m -s /bin/bash {{ username }} || echo "User exists"
            sudo mkdir -p /home/{{ username }}/.ssh
            echo "{{ sshPublicKey }}" | sudo tee /home/{{ username }}/.ssh/authorized_keys
            sudo chown -R {{ username }}:{{ username }} /home/{{ username }}/.ssh
            sudo chmod 700 /home/{{ username }}/.ssh
            sudo chmod 600 /home/{{ username }}/.ssh/authorized_keys
```
---

## 🔁 定期実行の設定（State Manager）

両タスクを定期実行したい場合は、State Managerと組み合わせます。

### 🧩 構成イメージ

```mermaid
flowchart TD
    A[State Manager Association] --> B[Automation Document: registerNewUser]
    A --> C[Schedule: cron or rate()]
    A --> D[対象インスタンス（タグ or ID）]
```

### ✅ 設定手順（例：毎週月曜 3:00 にアップデート）

1. Systems Manager → State Manager → Create Association
2. ドキュメント：`registerNewUser`
3. スケジュール：`cron(0 3 ? * MON *)`
4. パラメータ：`packageName = nginx` など
5. 対象インスタンス：タグ or ID指定

---

## 🧠 管理コンソール完結のポイント

| 操作内容               | 実現手段                          |
| ---------------------- | --------------------------------- |
| ドキュメント作成・編集 | Systems Manager → Documents       |
| 実行                   | Systems Manager → Automation      |
| 定期実行               | Systems Manager → State Manager   |
| 対象インスタンスの指定 | タグ or リソースグループ          |
| 実行結果の確認         | Automation履歴 or CloudWatch Logs |

---

## ✅ まとめ

| タスク名        | 内容                         | 実行方法                      |
| --------------- | ---------------------------- | ----------------------------- |
| registerNewUser | 新規ユーザー作成＋公開鍵登録 | Automation + 任意実行 or 定期 |
