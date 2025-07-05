# 🧾 Automation ドキュメント YAMLテンプレート解説  
（Windows Server 更新プログラム自動化タスク用）

---

## 📌 ドキュメント全体の構造

Automation ドキュメントは以下のような構成で記述されます：

```yaml
schemaVersion: '0.3'
description: "説明文"
parameters: {...}
mainSteps:
  - name: ステップ名
    action: アクションタイプ（例：aws:runCommand）
    inputs: {...}
    outputs: [...]  # 任意
```

---

## 🧩 パラメータ定義（parameters）

```yaml
parameters:
  instanceCsv:
    type: String
    description: "Comma-separated list of instance IDs"
  snsTopicArn:
    type: String
    description: "SNS topic ARN for notification"
```

- Automation 実行時に入力する値を定義します。
- 文字列、リスト、Boolean などの型が使えます。

---

## 🧠 ステップ構成（mainSteps）

以下に、代表的なステップの記述例と解説を示します。

---

### 🧮 ステップ1：インスタンスIDのCSVを分解

```yaml
- name: parseInstanceIds
  action: aws:executeScript
  inputs:
    Runtime: python3.8
    Handler: handler
    Script: |
      def handler(events, context):
          return events['instanceCsv'].split(',')
    InputPayload:
      instanceCsv: "{{ instanceCsv }}"
```

- CSV形式のインスタンスIDをリストに変換します。
- この出力は他のステップで `{{ parseInstanceIds.Output }}` として参照できます。

---

### 📶 ステップ2：疎通確認（ping）

```yaml
- name: pingCheck
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunPowerShellScript
    InstanceIds: "{{ parseInstanceIds.Output }}"
    Parameters:
      commands:
        - Test-Connection -ComputerName $env:COMPUTERNAME -Count 2
```

- PowerShell で ping を実行します。
- 成功/失敗は後続の通知に反映可能です。

---

### 📴 ステップ3：インスタンス停止

```yaml
- name: stopInstances
  action: aws:changeInstanceState
  inputs:
    InstanceIds: "{{ parseInstanceIds.Output }}"
    DesiredState: stopped
```

- EC2インスタンスを停止します。

---

### 📸 ステップ4：AMI作成

```yaml
- name: createAmi
  action: aws:createImage
  inputs:
    InstanceId: "{{ parseInstanceIds.Output[0] }}"  # 複数対応にはループが必要
    ImageName: "Backup-{{ global:DATE_TIME }}"
    NoReboot: true
```

- 各インスタンスのAMIを作成します。
- 複数インスタンスに対応するには `aws:loop` を使います（後述）。

---

### ⏳ ステップ5：スナップショットサイズ確認 + 待機

```yaml
- name: waitForSnapshot
  action: aws:sleep
  inputs:
    Duration: PT3M
```

- AMI作成後のスナップショットが安定するまで3分待機します。
- より厳密にスナップショットサイズを確認したい場合は、Lambdaでチェックする構成も可能です。

---

### 🔄 ステップ6：インスタンス起動

```yaml
- name: startInstances
  action: aws:changeInstanceState
  inputs:
    InstanceIds: "{{ parseInstanceIds.Output }}"
    DesiredState: running
```

---

### 🪟 ステップ7：Windows Update 実行

```yaml
- name: runWindowsUpdate
  action: aws:runCommand
  outputs:
    - Name: CommandId
      Selector: $.Command.CommandId
      Type: String
  inputs:
    DocumentName: AWS-InstallWindowsUpdates
    InstanceIds: "{{ parseInstanceIds.Output }}"
    Parameters:
      IncludeKbs: []
      ExcludeKbs: []
      CategoryNames: ["SecurityUpdates"]
```

- AWS提供の `AWS-InstallWindowsUpdates` ドキュメントを使用します。
- カテゴリやKB番号でフィルタ可能です。

---

### ✅ ステップ8：更新完了確認

```yaml
- name: checkUpdateStatus
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunPowerShellScript
    InstanceIds: "{{ parseInstanceIds.Output }}"
    Parameters:
      commands:
        - Get-WindowsUpdateLog
```

- 更新ログを取得して確認します。
- より厳密な確認には `Get-HotFix` や `Get-WUHistory` を使うことも可能です。

---

### 🔁 ステップ9〜11：再起動とログイン確認

```yaml
- name: rebootInstances
  action: aws:changeInstanceState
  inputs:
    InstanceIds: "{{ parseInstanceIds.Output }}"
    DesiredState: reboot
```

```yaml
- name: sleepAfterReboot
  action: aws:sleep
  inputs:
    Duration: PT1M
```

```yaml
- name: loginCheck
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunPowerShellScript
    InstanceIds: "{{ parseInstanceIds.Output }}"
    Parameters:
      commands:
        - whoami
```

---

### 📬 ステップ12：通知送信

```yaml
- name: notifyCompletion
  action: aws:invokeLambdaFunction
  inputs:
    FunctionName: "SendSSMNotificationWithResults"
    Payload:
      taskName: "WindowsUpdate自動化"
      instanceCsv: "{{ instanceCsv }}"
      snsTopicArn: "{{ snsTopicArn }}"
      commandId: "{{ runWindowsUpdate.CommandId }}"
```

- Lambda関数で SNS + Teams に通知を送信します。
- 各ステップの成功/失敗を集約してメッセージに含めます。

---

## 🔁 補足：ループ処理（複数AMI作成など）

Automation ドキュメントでは `aws:loop` を使って、複数のインスタンスに対して順次処理を行うことができます：

```yaml
- name: createAmiLoop
  action: aws:loop
  inputs:
    Iterator:
      List: "{{ parseInstanceIds.Output }}"
      ElementName: instanceId
    Steps:
      - name: createAmi
        action: aws:createImage
        inputs:
          InstanceId: "{{ instanceId }}"
          ImageName: "Backup-{{ instanceId }}-{{ global:DATE_TIME }}"
          NoReboot: true
```

---

## ✅ まとめ

| 要素          | 内容                                                                              |
| ------------- | --------------------------------------------------------------------------------- |
| schemaVersion | 常に `'0.3'` を使用                                                               |
| parameters    | 実行時に入力する変数を定義                                                        |
| mainSteps     | ステップごとに順序通りに処理を記述                                                |
| actionタイプ  | `aws:runCommand`, `aws:createImage`, `aws:sleep`, `aws:invokeLambdaFunction` など |
| ループ処理    | `aws:loop` で複数リソースに順次処理                                               |
| 通知          | Lambda関数でSNS + Teamsに送信                                                     |
