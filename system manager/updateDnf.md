## 📁 タスク②：モジュールアップデート2025年〇月  
指定されたパッケージを `dnf update` で更新するAutomationドキュメント。

### ✅ 機能概要

- パッケージ名を指定して `dnf update` を実行
- AL2023に対応
- 複数台に同時適用可能

### 🧩 Automation Document（モジュールアップデート2025年〇月）

```yaml
schemaVersion: '0.3'
description: "Update specific package using dnf on AL2023"
parameters:
  packageName:
    type: String
    description: "Package to update"
mainSteps:
  - name: updatePackage
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunShellScript
      Parameters:
        commands:
          - |
            set -e
            echo "Updating package: {{ packageName }}"
            sudo dnf update -y {{ packageName }}
```

---

## 🔁 定期実行の設定（State Manager）

両タスクを定期実行したい場合は、State Managerと組み合わせます。

### 🧩 構成イメージ

```mermaid
flowchart TD
    A[State Manager Association] --> B[Automation Document: registerNewUser]
    A --> C[Automation Document: モジュールアップデート2025年〇月]
    A --> D[Schedule: cron or rate()]
    A --> E[対象インスタンス（タグ or ID）]
```

### ✅ 設定手順（例：毎週月曜 3:00 にアップデート）

1. Systems Manager → State Manager → Create Association
2. ドキュメント：`モジュールアップデート2025年〇月`
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

| タスク名                         | 内容                       | 実行方法              |
| -------------------------------- | -------------------------- | --------------------- |
| モジュールアップデート2025年〇月 | 指定パッケージのdnf update | Automation + 定期実行 |

