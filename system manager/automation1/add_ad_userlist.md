# **ユーザー追加シナリオ**

目的は、S3にアップロードされたJSONファイルからユーザーリストを取得し、指定されたADグループにそれらのユーザーを追加することです。

---

## ✅ 最終版 SSM Document（SNS通知に東京リージョン指定）

```yaml
schemaVersion: '2.2'
description: "Add users to AD group using PowerShell and JSON from S3, then notify via SNS"
parameters:
  S3Bucket:
    type: String
    description: "S3 bucket name"
  S3Key:
    type: String
    description: "S3 object key"
  GroupName:
    type: String
    description: "AD group name to add users to"
  SourceInstanceId:
    type: String
    description: "踏み台EC2インスタンスID"
  SNSTopicArn:
    type: String
    description: "SNS Topic ARN for notification"
mainSteps:
  - action: aws:runPowerShellScript
    name: AddUsersToADGroup
    inputs:
      runCommand:
        - |
          param (
              [string]$S3Bucket = "{{ S3Bucket }}",
              [string]$S3Key = "{{ S3Key }}",
              [string]$GroupName = "{{ GroupName }}"
          )

          $localPath = "C:\Temp\group_users.json"
          Read-S3Object -BucketName $S3Bucket -Key $S3Key -File $localPath

          $json = Get-Content $localPath | ConvertFrom-Json
          $users = $json.Users

          $resultLog = @()
          foreach ($user in $users) {
              try {
                  Add-ADGroupMember -Identity $GroupName -Members $user -DisablePermissiveModify $true
                  $resultLog += "$user　成功"
              } catch {
                  $resultLog += "$user　失敗　$_"
              }
          }

          $resultText = "ＡＤユーザーの追加結果`n" + ($resultLog -join "`n")
          Set-Content -Path "C:\Temp\add_result.txt" -Value $resultText
      targets:
        - Key: InstanceIds
          Values:
            - "{{ SourceInstanceId }}"
  - name: notifyUploadResult
    action: aws:runPowerShellScript
    inputs:
      runCommand:
        - |
          param (
              [string]$TopicArn = "{{ SNSTopicArn }}"
          )

          $message = Get-Content -Path "C:\Temp\add_result.txt" -Raw

          # SNS通知（AWS CLI + 東京リージョン指定）
          aws sns publish --topic-arn $TopicArn --message "$message" --region ap-northeast-1
    targets:
      - Key: InstanceIds
        Values:
          - "{{ SourceInstanceId }}"
```

---

## ✅ IAMロールの確認ポイント

対象インスタンスにアタッチされたIAMロールには、以下の権限が必要です：

```json
{
  "Effect": "Allow",
  "Action": "sns:Publish",
  "Resource": "*"
}
```

※ `Resource` は `SNSTopicArn` に絞るのがベストです。

とても鋭いご質問です、崇史さん。

「`Resource` は `SNSTopicArn` に絞るのがベストです」というのは、**IAMポリシーのセキュリティ設計において、アクセス対象を最小限に限定するべき**という意味です。

---

## 🔐 なぜ絞るべきか？

IAMポリシーで `Resource: "*"` を指定すると、**すべてのSNSトピックに対して Publish が可能**になります。これは便利ですが、以下のリスクがあります：

- 誤って別のトピックに通知してしまう
- 他のシステムのトピックに干渉する可能性がある
- セキュリティ監査で「過剰な権限」と判断される

---

## ✅ 絞るべき書き方（例）

例えば、通知対象のSNSトピックが以下だとします：

```
arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults
```

この場合、IAMポリシーは以下のように書くのが理想です：

```json
{
  "Effect": "Allow",
  "Action": "sns:Publish",
  "Resource": "arn:aws:sns:ap-northeast-1:123456789012:NotifyADResults"
}
```

---

## 🧠 ベストプラクティス

| ポリシー                    | 説明                                        |
| --------------------------- | ------------------------------------------- |
| `"Resource": "*"`           | すべてのSNSトピックに対して許可（広すぎる） |
| `"Resource": "<特定のARN>"` | 必要なトピックだけに限定（推奨）            |
