#!/bin/bash

# 開始
CLOUDSHELL_WORK_DIR="$HOME/cloudshell-work"
CREATE_AMI_WORK_FILE="$CLOUDSHELL_WORK_DIR/instance-ids-details_$(date +'%Y%m%d_%H%M%S').txt"
CREATE_AMI_PREFIX="$(date +'%Y%m%d')-ami-"
JSON_INSTANCE_IDS=~/cloudshell-work/instance-ids.json

# インスタンス詳細の取得
aws ec2 describe-instances \
  --instance-ids $(jq -r '.Instances[].InstanceId' $JSON_INSTANCE_IDS) \
  --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0]]" \
  --output text > "$CREATE_AMI_WORK_FILE"
echo ""

# 結果をループで処理
while IFS=$'\t' read -r INSTANCE_ID INSTANCE_NAME; do
  # AMI名のセット
  CREATE_AMI_NAME="$CREATE_AMI_PREFIX$INSTANCE_NAME"
  
  # AMI作成
  CREATED_AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "$CREATE_AMI_NAME" \
    --no-reboot \
    --query "ImageId" \
    --output text)
  
  # 結果出力
  echo "Instance: $INSTANCE_NAME (ID: $INSTANCE_ID), Created Ami: $CREATE_AMI_NAME (Ami ID: $CREATED_AMI_ID)"
done < $CREATE_AMI_WORK_FILE
