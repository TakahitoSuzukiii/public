#!/bin/bash

# 開始
CLOUDSHELL_LOG_DIR="$HOME/cloudshell-logs"
CLOUDSHELL_LOG_FILE="$CLOUDSHELL_LOG_DIR/$(date +'%Y%m%d_%H%M%S').txt"
mkdir -p $CLOUDSHELL_LOG_DIR
# touch "$CLOUDSHELL_LOG_FILE"
script -q -a $CLOUDSHELL_LOG_FILE

CLOUDSHELL_WORK_DIR="$HOME/cloudshell-work"
mkdir -p $CLOUDSHELL_WORK_DIR