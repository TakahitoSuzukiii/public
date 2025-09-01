もちろんです、崇史さん。以下に、CloudWatch Logsのメトリクスフィルターとアラーム設計について、月1回実行のLambda関数ユースケースに最適化した内容を**Markdown形式**で再整理しました。

---

# 📘 CloudWatch Logs メトリクスフィルターとアラーム設計書（再整理版）

## 🧭 全体構成

```text
Lambda → CloudWatch Logs → メトリクスフィルター → CloudWatch アラーム → SNS通知（ops-prod）
```

Lambda関数が出力するログに `"ERROR"` を含むメッセージをCloudWatch Logsが検出し、メトリクスに変換 → アラーム発火 → SNSトピック `ops-prod` に通知します。

---

## 🔍 ログメッセージ設計

### ✅ 検出しやすいログ形式のベストプラクティス

| ログ形式                               | 検出性 | 備考                                                                  |
| -------------------------------------- | ------ | --------------------------------------------------------------------- |
| `"ERROR: CSVファイルが存在しません"`   | ◎      | `"ERROR:"` で明確に検出可能                                           |
| `"ERROR [S3Access] ファイル取得失敗"`  | ◎      | `"ERROR"` + コンテキストタグ                                          |
| `"RuntimeError: ユーザー一覧が空です"` | ○      | `"RuntimeError"` でも検出可能だが `"ERROR"` に統一推奨                |
| `"error: lowercase"`                   | ×      | メトリクスフィルターは大文字小文字を区別するため `"ERROR"` に統一推奨 |

### 🎯 推奨ログ出力例（Lambda内）

```python
logger.error("ERROR: CSVファイルが存在しません: s3://{bucket}/{key}")
logger.error("ERROR [CSVValidation] 空ファイルのため処理終了")
```

---

## 📊 メトリクスフィルター設定手順

### ✅ AWS管理コンソール手順

1. CloudWatch → [ロググループ] → `/aws/lambda/your-function-name` を選択  
2. [メトリクスフィルター] タブ → [メトリクスフィルターを作成]  
3. フィルターパターン：`"ERROR"`  
4. メトリクス詳細設定：
   - フィルター名：`ErrorFilter`
   - 名前空間：`LambdaMonitoring`
   - メトリクス名：`LambdaErrorCount`
   - メトリクス値：`1`
   - デフォルト値：`0`
   - 単位：`Count`
5. [作成] をクリック

### ✅ CloudShell（CLI）手順

```bash
aws logs put-metric-filter \
  --log-group-name "/aws/lambda/your-function-name" \
  --filter-name "ErrorFilter" \
  --filter-pattern '"ERROR"' \
  --metric-transformations \
    metricName="LambdaErrorCount",metricNamespace="LambdaMonitoring",metricValue="1"
```

---

## 🚨 CloudWatch アラーム設定手順

### ✅ AWS管理コンソール手順

1. CloudWatch → [アラーム] → [アラームを作成]  
2. メトリクス選択：名前空間 `LambdaMonitoring` → メトリクス `LambdaErrorCount`  
3. 条件設定：
   - 統計：`合計 (Sum)`
   - 期間：`3600秒（1時間）`
   - 評価期間：`1`
   - データポイント：`1`
   - しきい値：`>= 1`
4. 通知設定：
   - SNSトピック：`ops-prod`
5. アラーム名：`MonthlyLambdaErrorAlarm`  
6. [作成] をクリック

### ✅ CloudShell（CLI）手順

```bash
aws cloudwatch put-alarm \
  --alarm-name "MonthlyLambdaErrorAlarm" \
  --metric-name "LambdaErrorCount" \
  --namespace "LambdaMonitoring" \
  --statistic Sum \
  --period 3600 \
  --evaluation-periods 1 \
  --datapoints-to-alarm 1 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions arn:aws:sns:ap-northeast-1:123456789012:ops-prod \
  --actions-enabled
```

---

## 🧠 メトリクスフィルター設計オプション

| 項目               | 説明                 | 推奨値             |
| ------------------ | -------------------- | ------------------ |
| フィルターパターン | 検出対象の語句       | `"ERROR"`          |
| 名前空間           | メトリクスの分類     | `LambdaMonitoring` |
| メトリクス名       | メトリクスの識別名   | `LambdaErrorCount` |
| メトリクス値       | 一致時に加算する数値 | `1`                |
| デフォルト値       | 一致しない場合の値   | `0`                |
| 単位               | メトリクスの単位     | `Count`            |

---

## 🧠 CloudWatch アラーム設計オプション

| 項目           | 説明                     | 推奨値          |
| -------------- | ------------------------ | --------------- |
| 統計           | メトリクスの集計方法     | `Sum`           |
| 期間           | 評価間隔（秒）           | `3600`（1時間） |
| 評価期間       | 何回連続で条件を満たすか | `1`             |
| データポイント | 発火に必要な一致回数     | `1`             |
| しきい値       | 通知条件                 | `>= 1`          |
| 通知先         | SNSトピック              | `ops-prod`      |

---

## 📌 月1回実行ユースケースに最適な評価設計

| パラメータ          | 値     | 理由                                  |
| ------------------- | ------ | ------------------------------------- |
| `Period`            | `3600` | 月1回の実行に対して過剰な頻度を避ける |
| `EvaluationPeriods` | `1`    | 単発実行なので1回で十分               |
| `DatapointsToAlarm` | `1`    | 1回のエラーで即通知                   |
| `Threshold`         | `>= 1` | エラーが1件以上あれば通知             |

---

この設計なら、Lambdaが月末月初に1回だけ実行される場合でも、**実行直後の1時間だけ評価され、確実にエラーを検出して通知**できます。  
次は、Slack通知のWebhook設計や、CloudWatch Logs Insightsによる月次レポート化も一緒に整備してみましょうか。