# **ユーザー削除シナリオ**

目的は、S3にアップロードされたJSONファイルからユーザーリストを取得し、指定されたADグループからそれらのユーザーを削除することです。

---

## 🧾 削除処理用 SSM Document（YAML形式）

このRunbookは、以下のように動作します：

- S3からJSONファイルを取得
- JSONに記載されたユーザーを `$GroupName` から削除
- `-DisablePermissiveModify $true` により、存在しないユーザーを削除しようとするとエラー
- 成功・失敗の結果をログに記録し、SNSで通知

```yaml
schemaVersion: '2.2'
description: "Remove users from AD group using PowerShell and JSON from S3, then notify via SNS"
parameters:
  S3Bucket:
    type: String
    description: "S3 bucket name"
  S3Key:
    type: String
    description: "S3 object key"
  GroupName:
    type: String
    description: "AD group name to remove users from"
  SourceInstanceId:
    type: String
    description: "踏み台EC2インスタンスID"
  SNSTopicArn:
    type: String
    description: "SNS Topic ARN for notification"
mainSteps:
  - action: aws:runPowerShellScript
    name: RemoveUsersFromADGroup
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
                  Remove-ADGroupMember -Identity $GroupName -Members $user -DisablePermissiveModify $true -Confirm:$false
                  $resultLog += "$user　削除成功"
              } catch {
                  $resultLog += "$user　削除失敗　$_"
              }
          }

          $resultText = "ＡＤユーザーの削除結果`n" + ($resultLog -join "`n")
          Set-Content -Path "C:\Temp\remove_result.txt" -Value $resultText
      targets:
        - Key: InstanceIds
          Values:
            - "{{ SourceInstanceId }}"

  - name: notifyRemoveResult
    action: aws:runPowerShellScript
    inputs:
      runCommand:
        - |
          param (
              [string]$TopicArn = "{{ SNSTopicArn }}"
          )

          $message = Get-Content -Path "C:\Temp\remove_result.txt" -Raw
          aws sns publish --topic-arn $TopicArn --message "$message" --region ap-northeast-1
    targets:
      - Key: InstanceIds
        Values:
          - "{{ SourceInstanceId }}"
```

---

## 📂 JSONファイルの構造（同じ形式）

```json
{
  "Domain": "corp.example.local",
  "Group": "SalesTeam",
  "Users": ["user01", "user02", "user03"]
}
```

※ `Group` はパラメータで受け取るため、JSON内の `Group` は使わなくても構いません。

---

## ✅ このシナリオの特徴

| 特徴                             | 説明                               |
| -------------------------------- | ---------------------------------- |
| `Remove-ADGroupMember`           | ユーザーをADグループから削除       |
| `-DisablePermissiveModify $true` | 存在しないユーザー削除時にエラー   |
| `-Confirm:$false`                | 対話なしで削除実行                 |
| SNS通知                          | 削除結果を一覧で通知（成功／失敗） |
