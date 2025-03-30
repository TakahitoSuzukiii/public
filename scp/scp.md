# SCP (Secure Copy Protocol)

## linux

### scp ※【注意】非推奨

```
scp local_file username@remote_host:/remote/directory
scp [転送するファイル] ログイン名@サーバアドレス:[サーバ側のコピー先絶対パス]
```

### rsync ※推奨

ファイルやディレクトリを効率的にコピー・同期するためのツール

```bash
rsync [オプション] コピー元 コピー先
```

## 主なオプション一覧

- `-a`：アーカイブモード（再帰的コピー、パーミッション保持など）。
- `-h`：人間が読みやすい形式（例：ファイルサイズを KB/MB/GB 単位で表示）で出力します。
- `-r`：ディレクトリの再帰的コピーを有効化。
- `-P`：転送の進行状況を表示し、転送が中断した場合の再開を可能にします。
- `-v`：詳細な出力を表示。
- `-u`：既存のファイルより新しいファイルのみをコピー。
- `-z`：データを圧縮して転送します（特にリモート転送で有用）。
- `--delete`：コピー元に存在しないファイルをコピー先から削除。
- `--exclude=PATTERN`：特定のファイルやディレクトリを除外。
- `--dry-run`：実際のコピーを行わず、動作をシミュレーション（確認用）。

## 末尾のスラッシュの重要性

`rsync`や`scp`を使用する際、送り元と送り先のディレクトリ指定における末尾のスラッシュ（ケツスラ）は、転送の挙動に影響を与えます。

### 挙動の違い

- **スラッシュあり**:

  ```bash
  rsync -avPzh /source/ user@remote:/destination/
  ```

  - `/source/`の中身のみが`/destination/`に転送されます。

- **スラッシュなし**:
  ```bash
  rsync -avPzh /source user@remote:/destination/
  ```
  - `/source`ディレクトリそのものが`/destination/source/`として転送されます。

### 推奨事項

- 明示的にスラッシュを付けるかどうかを指定し、意図した転送を行う。
- 特に`--delete`オプションを使用する場合、慎重に指定する。

| パターン                              | ローカルパス指定      | リモートパス指定                     |
| ------------------------------------- | --------------------- | ------------------------------------ |
| ローカル: Linux → リモート: Linux     | `/local/source/`      | `user@remote:/remote/destination/`   |
| ローカル: Linux → リモート: Windows   | `/local/source/`      | `user@remote:/remote\\destination\\` |
| ローカル: Windows → リモート: Linux   | `C:\\local\\source\\` | `user@remote:/remote/destination/`   |
| ローカル: Windows → リモート: Windows | `C:\\local\\source\\` | `user@remote:/remote\\destination\\` |

---

## 使用例

```bash
rsync -avPzh --delete /local/source/ user@remote:/remote/destination/
```

```bash
rsync -avPzh --delete --dry-run /local/source/ user@remote:/remote/destination/
```

- **`/local/source/`**: ローカルのソースディレクトリ。末尾のスラッシュに注意してください。これにより、ディレクトリの中身が転送されます。
- **`user@remote:/remote/destination/`**: リモートサーバーの宛先ディレクトリ。
- **`--delete`**: コピー元に存在しないファイルをコピー先から削除します。

### ローカル間のコピー

```bash
rsync -avPzh /source/ /destination/
```

- アーカイブモードでコピーし、進行状況を表示、人間が読みやすい形式で表示、さらにデータを圧縮して転送します。

### リモートサーバーへのコピー

```bash
rsync -avPzh /source/ user@remote:/destination/
```

- ローカルからリモートサーバーへの効率的なデータ転送。

### リモートサーバーからのコピー

```bash
rsync -avPzh user@remote:/source/ /destination/
```

---

#### チートシート

- **特定のファイルを除外して同期**

  ```bash
  rsync -avPzh --exclude='*.log' /source/ /destination/
  ```

- **コピー元に存在しないファイルをコピー先から削除**

  ```bash
  rsync -avPzh --delete /source/ /destination/
  ```

- **大きなファイルを圧縮しつつ同期**

  ```bash
  rsync -avPzh /bigfile /destination/
  ```

- **ディレクトリをミラーリング**

  ```bash
  rsync -avPzh --delete /source/ /destination/
  ```

## windows

### rsync の動作を WinSCP で再現するコマンド（ログ出力を追加）

#### コマンド 1: `rsync -avPzh --delete /local/source/ user@remote:/remote/destination/`

ログ出力を有効にし、詳細なログを記録する WinSCP スクリプト：

```cmd
winscp.com /log="C:\Logs\WinSCP.log" /loglevel=2 /command ^
    "open sftp://user@remote" ^
    "synchronize remote -delete C:\local\source /remote/destination" ^
    "exit"
```

**説明**:

- `/log="C:\Logs\WinSCP.log"`: ログファイルの保存先を指定（ファイルパスは必要に応じて変更）。
- `/loglevel=2`: ログレベルを詳細に設定（2 が最高レベルで、最も詳しい情報が記録されます）。
- `synchronize remote`: ローカル → リモートへの同期。
- `-delete`: リモート側で存在しないファイルを削除。
- `C:\local\source`: ローカルのソースディレクトリ（Windows パス形式）。
- `/remote/destination`: リモートの宛先ディレクトリ。

---

#### コマンド 2: `rsync -avPzh --delete --dry-run /local/source/ user@remote:/remote/destination/`

ログ出力を有効にし、詳細なログと`--dry-run`を再現する WinSCP スクリプト：

```cmd
winscp.com /log="C:\Logs\WinSCP_preview.log" /loglevel=2 /command ^
    "open sftp://user@remote" ^
    "synchronize remote -delete -preview C:\local\source /remote/destination" ^
    "exit"
```

**説明**:

- `/log="C:\Logs\WinSCP_preview.log"`: ログファイル名を変更してプレビュー操作のログを保存。
- `/loglevel=2`: 最も詳細なログを記録。
- `-preview`: 操作のシミュレーションを実行（`rsync`の`--dry-run`に相当）。
- `synchronize remote`: ローカル → リモートの同期操作をシミュレーション。

---

### 注意事項

1. **ログ出力のファイルパスを確認**:

   - ファイルの保存先に書き込み権限があることを確認してください（例: `C:\Logs\`）。
   - ディレクトリが存在しない場合は事前に作成する必要があります。

2. **ログレベルについて**:

   - `/loglevel=0`: 最小限のログ情報。
   - `/loglevel=1`: 通常のログ情報。
   - `/loglevel=2`: 詳細なログ情報（デバッグレベル）。

3. **WinSCP のログ内容**:
   - 転送されたファイルの名前、サイズ、転送時間。
   - 転送の成功／失敗ステータス。
   - エラーが発生した場合の詳細情報。
