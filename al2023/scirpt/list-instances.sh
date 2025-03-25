#!/bin/bash

# 開始
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" --output text