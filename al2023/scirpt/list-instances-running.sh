#!/bin/bash

# 開始
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], State.Name, PublicIpAddress, PrivateIpAddress]" --output text