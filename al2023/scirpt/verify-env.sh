#!/bin/bash

# 開始
echo "- verify shell ---------------------------------"
echo $SHELL

echo ""
echo "- verify os ---------------------------------"
cat /etc/os-release

echo ""
echo "- verify env aws ---------------------------------"
env | grep AWS

echo ""
echo "- verify credentials ---------------------------------"
aws configure list