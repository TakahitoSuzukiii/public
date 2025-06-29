## 2. **rsync を使用する場合のセットアップ**

### ローカル環境のセットアップ

1. **rsync のインストール**:

   - Windows では、rsync は標準で含まれていないため、以下のいずれかをセットアップします:
     - **Cygwin**をインストールして`rsync`を有効にする。
     - **Windows Subsystem for Linux (WSL)**をインストールし、Ubuntu や Debian などの Linux 環境を使用。

   **Cygwin のインストール手順**:

   - [Cygwin 公式サイト](https://www.cygwin.com/)からセットアップツールをダウンロード。
   - セットアップ中に`rsync`を選択してインストール。

   **WSL のセットアップ手順**:

   - PowerShell で以下のコマンドを実行：
     ```powershell
     wsl --install -d Ubuntu
     ```
   - WSL 内で`rsync`をインストール：
     ```bash
     sudo apt update
     sudo apt install rsync
     ```

2. **パス形式の注意**:
   - Windows のファイルパスを適切に変換（例: `C:\local\source` → `/mnt/c/local/source`）。

以下に、Windows Server 2019 と Amazon Linux 2023 の環境で、`rsync`や`WinSCP`を利用するセットアップ方法を詳しく説明します。

---

## **1. Windows Server 2019 のセットアップ**

### **rsync のセットアップ**

Windows Server には`rsync`がデフォルトでインストールされていませんので、以下の手順で環境を整えます。

#### 手順

1. **Windows Subsystem for Linux (WSL)を有効化**:

   - PowerShell を管理者権限で開きます。
   - 次のコマンドを実行して WSL を有効化：
     ```powershell
     dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
     ```
   - 再起動後、以下で Ubuntu などの Linux ディストリビューションをインストール：
     ```powershell
     wsl --install -d Ubuntu
     ```

2. **rsync のインストール**:

   - WSL 内で以下のコマンドを実行し、`rsync`をインストールします：
     ```bash
     sudo apt update
     sudo apt install rsync
     ```

3. **SSH キーの生成（オプション）**:

   - `rsync`を SSH 経由で利用する場合、ローカルで SSH キーを作成し、リモートサーバーにコピーします：
     ```bash
     ssh-keygen -t rsa
     ssh-copy-id user@remote
     ```

4. **実行例**:
   - 次のように Windows パスを Linux 形式に変換して実行します：
     ```bash
     rsync -avPzh --delete /mnt/c/local/source/ user@remote:/remote/destination/
     ```

### **WinSCP のセットアップ**

1. **WinSCP のダウンロードとインストール**:

   - [公式サイト](https://winscp.net)から WinSCP をダウンロードしインストールします。

2. **GUI で接続設定**:

   - サーバーホスト名、ポート、ユーザー名、パスワードを入力して接続を設定。

3. **コマンドラインの利用（オプション）**:
   - WinSCP CLI を利用してスクリプト操作が可能：
     ```cmd
     winscp.com /log="C:\Logs\WinSCP.log" /command ^
         "open sftp://user@remote" ^
         "synchronize remote C:\local\source /remote/destination" ^
         "exit"
     ```

---

## **2. Amazon Linux 2023 のセットアップ**

### **rsync のセットアップ**

Amazon Linux は`rsync`がデフォルトで用意されています。必要に応じて以下の手順で設定を行います。

#### 手順

1. **rsync のインストールと確認**:

   - まず、rsync がインストールされているか確認します：
     ```bash
     rsync --version
     ```
   - インストールされていない場合：
     ```bash
     sudo yum update -y
     sudo yum install -y rsync
     ```

2. **SSH の設定**:

   - サーバーの SSH を有効化（通常デフォルトで有効）：
     ```bash
     sudo systemctl start sshd
     sudo systemctl enable sshd
     ```

3. **rsync の基本実行例**:
   - ファイルをリモートから取得：
     ```bash
     rsync -avPzh user@local:/local/source/ /remote/destination/
     ```
   - ファイルをリモートに送信：
     ```bash
     rsync -avPzh --delete /local/source/ user@remote:/remote/destination/
     ```

### **WinSCP のセットアップ**

Amazon Linux は Linux 環境であるため、WinSCP をクライアントとして接続する使い方が一般的です。

1. **WinSCP をクライアントとして使用**:

   - Windows 側で WinSCP を設定して、Amazon Linux のサーバーに SFTP 接続。
   - Amazon Linux 側で必要なディレクトリ権限を設定：
     ```bash
     sudo chmod 755 /destination/directory
     ```

2. **ログイン情報の設定**:
   - Amazon Linux のパブリック IP アドレスまたはホスト名、ポート番号（通常 22）、ユーザー名、秘密鍵（またはパスワード）を設定して接続。

---

## **注意点**

- **Windows Server 2019**:

  - WSL 環境を整えると、Linux コマンドが活用できるため、`rsync`がスムーズに動作します。
  - WinSCP は直感的なインターフェースでセットアップが簡単です。

- **Amazon Linux 2023**:
  - `rsync`と SSH のセットアップが比較的簡単であり、効率的なファイル同期が可能。
  - Amazon Linux に適切な権限設定が必要。

両環境のセットアップが完了すれば、効率的なファイル転送が可能です。他に詳しく知りたいことがあれば教えてください！ 😊

---

もちろん！`rsync` の `--dry-run` オプションは、**実際にはファイルをコピー・削除せずに、何が起こるかをシミュレーションする**ための非常に便利な機能です。

---

### 🔍 `--dry-run` の基本

```bash
rsync -av --delete --dry-run /source/ /destination/
```

このコマンドは、実際には `/destination/` に何も変更を加えず、**「このまま実行したらこうなりますよ」**という内容を表示してくれます。

---

### 🧠 使いどころ

- **削除を伴う操作の事前確認**（`--delete` と併用）
- **転送対象ファイルの確認**
- **スクリプトのテスト**
- **誤操作の防止**

---

### ✅ よく使う組み合わせ

| オプション  | 説明                                                             |
| ----------- | ---------------------------------------------------------------- |
| `-a`        | アーカイブモード（再帰・パーミッション・タイムスタンプ保持など） |
| `-v`        | 詳細表示（何が転送されるか見える）                               |
| `--delete`  | 転送元にないファイルを転送先から削除                             |
| `--dry-run` | 実行せずに内容だけ表示（安全確認）                               |

---

### 📌 実例

```bash
rsync -av --delete --dry-run /home/operation/host1/ /var/www/host1/
```

この出力には、以下のような行が表示されます：

```
deleting old_file.html
sending incremental file list
index.html
style.css
```

- `deleting` 行 → 削除される予定のファイル
- その他の行 → コピー・更新される予定のファイル

---

### ⚠️ 注意点

- `--dry-run` は**安全確認のための必須ステップ**。特に `--delete` を使うときは、**必ず一度は `--dry-run` を付けて確認**しましょう。
- `--dry-run` を外すと、実際にファイルが削除・上書きされます。

---

もっと高度な使い方（除外パターンやログ出力など）もできますよ。必要ならそのあたりも掘り下げます！【[参考](https://bytexd.com/how-to-use-rsync-dry-run-with-examples/)】