# リモート環境のセットアップ

1. **SSH サーバーのセットアップ**:
   - リモート側で SSH（OpenSSH など）をインストールし、有効化します。
     ```bash
     sudo apt update
     sudo apt install openssh-server
     ```
   - サーバーの SSH サービスを起動：
     ```bash
     sudo service ssh start
     ```
2. **アクセス権の設定**:
   - ユーザーのホームディレクトリとその内部のパスに適切な読み書き権限を設定します。
     ```bash
     chmod 700 ~/.ssh
     chmod 600 ~/.ssh/authorized_keys
     ```

---

### リモート環境のセットアップ

1. **rsync のインストール**:

   - リモート側で rsync がインストールされていることを確認します。インストールされていない場合：
     ```bash
     sudo apt update
     sudo apt install rsync
     ```

2. **SSH サーバーの準備**:

   - rsync は SSH を利用してデータを転送するため、SSH サーバーが有効であることを確認。
     ```bash
     sudo service ssh start
     ```

3. **接続確認**:

   - ローカルからリモートに SSH 接続できるかテストします：
     ```bash
     ssh user@remote
     ```

4. **ファイル転送先ディレクトリの権限確認**:
   - リモート側の転送先ディレクトリ（例: `/remote/destination`）に書き込み権限があるか確認します：
     ```bash
     chmod 755 /remote/destination
     ```

---

## 3. **WinSCP と rsync のコマンド例**

- WinSCP でリモート同期：

  ```cmd
  winscp.com /command "open sftp://user@remote" "synchronize remote C:\local\source /remote/destination" "exit"
  ```

- rsync でリモート同期：
  ```bash
  rsync -avPzh --delete /local/source/ user@remote:/remote/destination/
  ```
