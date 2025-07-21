# cli実行

もちろん、崇史さん。AWS Systems Manager Automation Document（ランブック）を AWS CLI で実行する際に、**さまざまなオプションを指定する方法**を詳しく解説します。

---

### 🛠️ 基本コマンド構文

```bash
aws ssm start-automation-execution \
  --document-name "ドキュメント名" \
  --parameters "パラメータ名1=値1,パラメータ名2=値2" \
  --targets "Key=タグキー,Values=タグ値" \
  --target-maps '[{"Key":"タグキー","Values":["タグ値"]}]' \
  --automation-assume-role "IAMロールARN" \
  --document-version "バージョン番号" \
  --mode "Auto|Interactive"
```

---

### 🔍 オプション詳細

| オプション名               | 説明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| `--document-name`          | 実行する Automation Document の名前（例: `MyAutomationDoc`） |
| `--parameters`             | ドキュメントで定義された入力パラメータを指定（JSON形式も可） |
| `--targets`                | タグベースで対象リソースを指定（RunCommandと同様）           |
| `--target-maps`            | 複数のタグ条件を組み合わせて対象を指定                       |
| `--automation-assume-role` | 実行時に使用する IAM ロールの ARN                            |
| `--document-version`       | 実行するドキュメントのバージョン（省略時は最新）             |
| `--mode`                   | `Auto`（自動）または `Interactive`（手動ステップ実行）       |

---

### 🧪 実行例

#### EC2インスタンスを再起動する Automation Document を実行する例：

```bash
aws ssm start-automation-execution \
  --document-name "AWS-RestartEC2Instance" \
  --parameters "InstanceId=i-0123456789abcdef0" \
  --automation-assume-role "arn:aws:iam::123456789012:role/MyAutomationRole"
```

#### 複数パラメータを JSON 形式で渡す例：

```bash
aws ssm start-automation-execution \
  --document-name "MyCustomAutomation" \
  --parameters file://params.json
```

`params.json` の例：

```json
{
  "BucketName": ["my-bucket"],
  "UserListKey": ["users.json"]
}
```

---

### 📊 実行ステータス確認

```bash
aws ssm describe-automation-executions \
  --filters "Key=ExecutionId,Values=実行ID"
```

またはステップ単位で確認：

```bash
aws ssm describe-automation-step-executions \
  --automation-execution-id 実行ID
```

---

### 💡補足ポイント

- `--mode Interactive` を使うと、ステップごとに手動で進行できます。
- `--automation-assume-role` を指定しない場合、実行ユーザーの権限で動作しますが、12時間以上の実行にはロール指定が必須です。
- `--targets` や `--target-maps` は、複数インスタンスへの一括実行に便利です。

---

もちろん、崇史さん。AWS Systems Manager Automation Document（ランブック）を AWS CLI で実行する際に、**さまざまなオプションを指定する方法**を詳しく解説します。

---

### 🛠️ 基本コマンド構文

```bash
aws ssm start-automation-execution \
  --document-name "ドキュメント名" \
  --parameters "パラメータ名1=値1,パラメータ名2=値2" \
  --targets "Key=タグキー,Values=タグ値" \
  --target-maps '[{"Key":"タグキー","Values":["タグ値"]}]' \
  --automation-assume-role "IAMロールARN" \
  --document-version "バージョン番号" \
  --mode "Auto|Interactive"
```

---

### 🔍 オプション詳細

| オプション名               | 説明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| `--document-name`          | 実行する Automation Document の名前（例: `MyAutomationDoc`） |
| `--parameters`             | ドキュメントで定義された入力パラメータを指定（JSON形式も可） |
| `--targets`                | タグベースで対象リソースを指定（RunCommandと同様）           |
| `--target-maps`            | 複数のタグ条件を組み合わせて対象を指定                       |
| `--automation-assume-role` | 実行時に使用する IAM ロールの ARN                            |
| `--document-version`       | 実行するドキュメントのバージョン（省略時は最新）             |
| `--mode`                   | `Auto`（自動）または `Interactive`（手動ステップ実行）       |

---

### 🧪 実行例

#### EC2インスタンスを再起動する Automation Document を実行する例：

```bash
aws ssm start-automation-execution \
  --document-name "AWS-RestartEC2Instance" \
  --parameters "InstanceId=i-0123456789abcdef0" \
  --automation-assume-role "arn:aws:iam::123456789012:role/MyAutomationRole"
```

#### 複数パラメータを JSON 形式で渡す例：

```bash
aws ssm start-automation-execution \
  --document-name "MyCustomAutomation" \
  --parameters file://params.json
```

`params.json` の例：

```json
{
  "BucketName": ["my-bucket"],
  "UserListKey": ["users.json"]
}
```

---

### 📊 実行ステータス確認

```bash
aws ssm describe-automation-executions \
  --filters "Key=ExecutionId,Values=実行ID"
```

またはステップ単位で確認：

```bash
aws ssm describe-automation-step-executions \
  --automation-execution-id 実行ID
```

---

### 💡補足ポイント

- `--mode Interactive` を使うと、ステップごとに手動で進行できます。
- `--automation-assume-role` を指定しない場合、実行ユーザーの権限で動作しますが、12時間以上の実行にはロール指定が必須です。
- `--targets` や `--target-maps` は、複数インスタンスへの一括実行に便利です。

---

もちろんです、崇史さん。`--mode Interactive` を使うと、Automation Document（ランブック）の各ステップを**手動で進行**できます。これにより、ステップ2の完了後に**任意の時間待ってからステップ3を実行**することが可能です。

---

### 🧭 `--mode Interactive` の基本動作

- Automation は **ステップ1だけを実行**して停止します。
- 次のステップを進めるには、明示的に `send-automation-signal` コマンドを使って指示します。
- 各ステップの間に **任意の待機時間**を設けることができます（30分でも1時間でもOK）。

---

### 🛠️ 実行手順の例（ステップ1〜3）

#### ① Automation を `Interactive` モードで開始

```bash
aws ssm start-automation-execution \
  --document-name "MyAutomationDoc" \
  --mode Interactive \
  --parameters file://params.json
```

出力される `AutomationExecutionId` を控えておきます。

---

#### ② ステップ1を実行

```bash
aws ssm send-automation-signal \
  --automation-execution-id "実行ID" \
  --signal-type StartStep \
  --payload StepName="Step1"
```

---

#### ③ ステップ2を実行（ここで処理が完了したら、**待機**）

```bash
aws ssm send-automation-signal \
  --automation-execution-id "実行ID" \
  --signal-type StartStep \
  --payload StepName="Step2"
```

🕒 この後、**30分〜1時間待機**します。待機は手動で時間を空けるだけでOKです。もし自動で待機させたい場合は、`aws:sleep` ステップをランブックに組み込むこともできます。

---

#### ④ ステップ3を手動で実行

```bash
aws ssm send-automation-signal \
  --automation-execution-id "実行ID" \
  --signal-type StartStep \
  --payload StepName="Step3"
```

---

### 📋 ステップの状態確認

```bash
aws ssm describe-automation-step-executions \
  --automation-execution-id "実行ID"
```

これで各ステップの進行状況や待機状態を確認できます。

---

### 💡補足

- `send-automation-signal` の `StepName` は、Automation Document の `mainSteps` に定義された名前と一致させる必要があります。
- ステップ間の待機は、**人が時間を空けてコマンドを打つ**ことで実現できます。
- 自動化したい場合は、EventBridge や `aws:sleep` を組み合わせると柔軟に制御できます。

