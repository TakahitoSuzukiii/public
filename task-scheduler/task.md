# タスクの作成

## 名前

scheduled_task_start_jenkins_agent
【auto-test】StartJenkinsAgent
【自動テスト】Jenkins エージェントのスケジュール起動

## 説明

平日の朝 8 時 30 分にスケジュール実行で jenkins エージェントを起動する

## タスク実行時に使うユーザーアカウント

jenkins_node

ps:jenkins

## トリガー

毎週：月曜～金曜を選択する

## 操作

プログラムの開始：C:\Windows\System32\cmd.exe
引数の追加：/c
開始（オプション）：LOG_DIR を指定

### **引数の追加**

- **内容**: 実行するプログラムに渡す追加のコマンドライン引数を指定します。
  - 例えば、`/c "echo Hello > C:\example.txt"`と設定すると、タスクが実行される際に以下の動作が行われます：
    - コマンドプロンプトが起動し、`echo Hello > C:\example.txt`というコマンドが実行されます。
  - **引数の例**:
    - `/c`: コマンドを実行して終了する（`cmd.exe`のオプション）。
    - `/k`: コマンドを実行してプロンプトを維持する。

---

### **開始（オプション）**

- **内容**: プログラムの実行時にカレントディレクトリ（作業ディレクトリ）を指定します。
  - このディレクトリは、プログラムがファイルを読み書きする際の基準となります。
  - 例えば、`C:\MyScripts`を指定すると、`cmd.exe`の実行中にこのディレクトリが作業ディレクトリとして使用されます。

---

### test1

'''
for /f "tokens=2 delims==." %A in ('wmic os get localdatetime /value') do set datetime=%A
set LOGFILE=test-create-file-%datetime:~0,8%-%datetime:~8,6%.txt
echo test >> "%USERPROFILE%\Desktop\%LOGFILE%"
'''

### run_event_start_jenkins_agent

'''
@echo off

:: ログファイルを作成
for /f "tokens=2 delims==." %A in ('wmic os get localdatetime /value') do set datetime=%A
set LOGFILE=log-start-jenkins-agent-%datetime:~0,8%-%datetime:~8,6%.txt
echo. > "%USERPROFILE%\Desktop\%LOGFILE%"

:: RDP 接続
echo [%date% %time%] RDP 接続を開始する >> %LOGFILE%
mstsc /v:127.0.0.2 /jenkins_node /w:1024 /h:768

:: Jenkins エージェントの起動
set WORK_DIR="%USERPROFILE%\XXX"
psExec \\127.0.0.2 -u jenkins_node cmd /c "%WORK_DIR%\run_jenkins_agent.bat > %LOGFILE% 2>&1"

:: ログを記録
echo [%date% %time%] Jenkins エージェントを起動した >> %LOGFILE%
pause
'''

https://learn.microsoft.com/en-us/sysinternals/downloads/psexec

'''
@echo off

:: ログファイルを作成
for /f "tokens=2 delims==." %A in ('wmic os get localdatetime /value') do set datetime=%A
set LOGFILE=log-start-jenkins-agent-%datetime:~0,8%-%datetime:~8,6%.txt
echo. >> "%USERPROFILE%\Desktop\%LOGFILE%"

:: RDP 接続
echo [%date% %time%] RDP 接続を開始する >> %LOGFILE%
mstsc /v:127.0.0.2 /jenkins_node /w:1024 /h:768

:: Jenkins エージェントの起動
start mstsc /v:127.0.0.2 /admin

:: ログを記録
echo [%date% %time%] Jenkins エージェントを起動した >> %LOGFILE%
pause
'''

### 自動化の条件をクリアするための手順

1. **リモートホストにスクリプトを配置**：

   - リモートホスト（127.0.0.2）のスタートアップフォルダーに、Jenkins エージェントを起動するためのスクリプト（例: `run_agent.bat`）をコピーします。
     - スタートアップフォルダーのパス：
       ```
       C:\Users\jenkins_node\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
       ```

2. **スクリプト内容**：
   リモートホスト側に配置するスクリプト`run_agent.bat`の内容は以下の通りです：

   ```cmd
   @echo off
   java -jar agent.jar -jnlpUrl http://your-jenkins-url/computer/agent-name/slave-agent.jnlp -secret your-secret-key > "%USERPROFILE%\Desktop\jenkins_agent_log.txt" 2>&1
   ```

3. **RDP セッションの自動化**:
   - ローカルから RDP 接続を開始すると、リモートホストが起動時にスタートアップフォルダー内のバッチスクリプトを実行します。
   - これにより、手動のコマンド実行は不要になります。

## 条件

次の間アイドル状態の場合のみ、タスクを開始する：5 分
タスクを実行するためにスリープを解除する：チェック

## 設定

タスクが失敗した場合の再起動の間隔：5 分間
再起動試行の最大数：10 回
