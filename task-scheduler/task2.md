# タスクの作成

## 名前

StartJenkinsAgent

## 説明

サーバー起動時にJenkinsエージェントを自動起動するタスク

## 全般

- ユーザーアカウント：Administrator
- ログオンにかかわらず実行する

## トリガー

スタートアップ時

## 操作

プログラムの開始：C:\Windows\System32\cmd.exe
引数の追加：/K "C:\Windows\testrun.bat"

## 条件

全てチェックを外す

## 設定

チェックは、3つ。

- タスクを要求時に実行する。チェックあり。
- スケジュールされた時刻にタスクを開始できなかった場合、すぐにタスクを実行する。チェックあり。
- タスクを停止するまでの時間。チェックあり。

# バッチ

## 名前

testrun.bat

## スクリプト

```
@echo off

set LOGFILE=C:\Users\Administrator\Desktop\log.txt
echo LOGFILE: %LOGFILE%

set DATETIME=%date% %time%
echo [%DATETIME%] run jenkins agent >> %LOGFILE%
pause
```

## プロセスの起動確認

```
tasklist | findstr cmd.exe
```

```
wmic process get Name, ProcessId, ExecutablePath, CommandLine
```

```
wmic process where "ProcessId=1964" get Name, ExecutablePath, CommandLine
```

```
wmic process where "Name='cmd.exe'" get ProcessId, CommandLine
```

```
wmic process get Name, WorkingSetSize
```

### 主なプロパティ一覧

- **Name**: プロセス名
- **ProcessId**: プロセスID
- **ParentProcessId**: 親プロセスID
- **WorkingSetSize**: メモリ使用量
- **ExecutablePath**: 実行ファイルのフルパス
- **CommandLine**: 実行時のコマンドライン引数
- **Priority**: プロセスの優先度
- **CreationDate**: プロセスの開始日時
