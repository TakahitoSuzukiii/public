

## ⚙️ Automation ドキュメント構成（YAML）

```yaml
schemaVersion: '0.3'
description: "Upload user list CSV from bastion EC2 to S3"
parameters:
  SourceInstanceId:
    type: String
    description: "踏み台EC2インスタンスID"
  SourceFilePath:
    type: String
    description: "Dドライブ上のCSVパス（例：D:\\UserSync\\AddUsers.csv）"
  S3BucketName:
    type: String
    description: "アップロード先のS3バケット名"
  S3KeyPrefix:
    type: String
    description: "S3キーのプレフィックス（例：userlists/add/）"
mainSteps:
  - name: readAndUploadCSV
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunPowerShellScript
      Parameters:
        commands:
          - |
            $csvPath = "{{ SourceFilePath }}"
            $bucket = "{{ S3BucketName }}"
            $keyPrefix = "{{ S3KeyPrefix }}"
            $fileName = Split-Path $csvPath -Leaf
            Write-S3Object -BucketName $bucket -File $csvPath -Key "$keyPrefix/$fileName"
            Write-Output "Uploaded $csvPath to s3://$bucket/$keyPrefix/$fileName"
    targets:
      - Key: InstanceIds
        Values:
          - "{{ SourceInstanceId }}"
- name: notifyUploadResult
  action: aws:executeAwsApi
  inputs:
    Service: sns
    Api: Publish
    Parameters:
      TopicArn: "{{ SNSTopicArn }}"
      Message: "Add User list uploaded to s3://{{ S3BucketName }}/{{ S3KeyPrefix }} successfully."
```