# Linuxサーバーのメモリ管理

## **メモリ不足（Out of Memory, OOM）**
Linuxでは、プロセスがメモリを要求すると、カーネルが適切なメモリ領域を割り当てます。しかし、物理メモリやスワップ領域が枯渇すると、システムはメモリ不足（OOM）状態になります。OOM状態になると、システムの動作が不安定になり、フリーズやハングアップが発生する可能性があります。

## **OOM Killer**
OOM Killerは、Linuxカーネルに組み込まれたメモリ管理機能で、システムがOOM状態になった際に、特定のプロセスを強制終了することでシステムの安定性を維持します。OOM Killerは、メモリ消費量が多く、優先度が低いプロセスを選んで終了させます。

### **OOM Killerが発動する条件**
- システムの物理メモリとスワップ領域が枯渇した場合
- メモリのオーバーコミットが発生し、複数のプロセスが同時にメモリを使用し始めた場合
- メモリリークが発生し、特定のプロセスが大量のメモリを消費した場合

### **OOM Killerの対策**
- スワップ領域を増やす
- メモリを増設する
- OOM Killerの優先度を設定し、重要なプロセスが終了しないようにする

## **フリーズとハングアップ**
フリーズとは、システムが一時的に応答しなくなる状態を指します。ハングアップは、システムが完全に停止し、操作を受け付けなくなる状態です。

### **フリーズ・ハングアップの原因**
- メモリ不足によるプロセスの停止
- CPU負荷の急激な増加
- ディスクI/Oの過負荷
- カーネルのバグやドライバの問題

### **フリーズ・ハングアップ時の対処**
- `top` や `htop` コマンドで負荷の高いプロセスを特定し、不要なプロセスを終了する
- `dmesg` コマンドでカーネルログを確認し、異常がないか調査する
- システムが完全に応答しない場合は、強制再起動を行う

## **カーネルパニック**
カーネルパニックは、Linuxカーネルが致命的なエラーを検出し、システムの動作を停止する状態です。通常、カーネルパニックが発生すると、画面にエラーメッセージが表示され、システムが再起動するか完全に停止します。

### **カーネルパニックの原因**
- メモリ不足による異常動作
- ハードウェアの故障
- カーネルモジュールの不具合
- ファイルシステムの破損

### **カーネルパニックの対策**
- `journalctl -k` コマンドでカーネルログを確認し、原因を特定する
- ハードウェアの診断を行い、異常がないか確認する
- カーネルのアップデートを行い、バグを修正する

Linuxサーバーのメモリ管理は、システムの安定性に直結する重要な要素です。OOM Killerの動作を理解し、適切な対策を講じることで、フリーズやカーネルパニックを防ぐことができます。詳細な設定方法については、[こちら](https://www.oracle.com/jp/technical-resources/articles/it-infrastructure/dev-oom-killer.html)を参考にしてください。

---

# Linuxでメモリの使用状況を確認するための主要なコマンド

## **1. `top` コマンド**
`top` は、システムのプロセスとリソース使用状況をリアルタイムで監視するためのコマンドです。

### **主なオプション**
- `-b` : バッチモードで出力（スクリプトで利用可能）
- `-n <回数>` : 指定した回数だけ更新して終了
- `-o <項目>` : 指定した項目でソート（例: `-o %MEM` でメモリ使用率順）

### **使い方**
```bash
top
```
リアルタイムでCPUやメモリ使用状況を確認できます。

```bash
top -b -n 1 | head -20
```
1回だけ情報を取得し、最初の20行を表示。

## **2. `htop` コマンド**
`htop` は `top` の強化版で、視覚的にわかりやすいインターフェースを提供します。

### **主なオプション**
- `-d <秒>` : 更新間隔を指定
- `-u <ユーザー>` : 指定したユーザーのプロセスのみ表示
- `-s <項目>` : 指定した項目でソート（例: `-s MEM`）

### **使い方**
```bash
htop
```
カラフルなUIでプロセスを管理できます。

```bash
htop -u root
```
rootユーザーのプロセスのみ表示。

## **3. `dmesg` コマンド**
`dmesg` は、カーネルのログを表示するコマンドで、メモリ関連のエラーを確認できます。

### **主なオプション**
- `-T` : タイムスタンプを人間が読みやすい形式で表示
- `| grep -i oom` : OOM（Out of Memory）関連のログを抽出

### **使い方**
```bash
dmesg | grep -i oom
```
OOM Killerが発動したログを確認。

```bash
dmesg -T | tail -20
```
最新のカーネルログを20行表示。

## **4. `vmstat` コマンド**
`vmstat` は、メモリやCPU、I/Oの統計情報を表示するコマンドです。

### **主なオプション**
- `-s` : メモリの詳細情報を表示
- `-d` : ディスクI/Oの統計情報を表示
- `-t` : タイムスタンプ付きで表示

### **使い方**
```bash
vmstat 1 10
```
1秒ごとに10回のメモリ使用状況を表示。

```bash
vmstat -s
```
メモリの詳細情報を確認。

## **5. `free` コマンド**
`free` は、システムのメモリ使用状況を簡単に確認できるコマンドです。

### **主なオプション**
- `-m` : メモリ使用量をMB単位で表示
- `-g` : メモリ使用量をGB単位で表示
- `-t` : メモリとスワップの合計を表示

### **使い方**
```bash
free -m
```
MB単位でメモリ使用状況を表示。

```bash
free -t
```
メモリとスワップの合計を表示。

これらのコマンドを適切に活用することで、Linuxのメモリ使用状況を詳細に把握し、問題の特定やパフォーマンスの最適化が可能になります。さらに詳しい情報は、[こちら](https://performance.oreda.net/linux/check/memory)を参考にしてください。

---

# LinuxでOOM（Out of Memory）、フリーズ、ハングアップが発生した際に、`top`、`htop`、`dmesg`、`vmstat`、`free` などのコマンドを実行すると、特定のメッセージやキーワードが表示されることがあります。以下に、それぞれのコマンドで確認できる代表的なメッセージとキーワードを紹介します。

# **OOM（Out of Memory）関連のメッセージ**
OOMが発生すると、`dmesg` コマンドで以下のようなメッセージが確認できます：
- `Out of memory: Kill process <PID> (<process_name>) score <score> or sacrifice child`
- `Killed process <PID> (<process_name>)`
- `oom-killer: gfp_mask=0x... order=0 oom_score_adj=...`
- `Memory cgroup out of memory: Kill process <PID> (<process_name>)`

**代表的なキーワード**
- `OOM`
- `Killed process`
- `oom-killer`
- `memory cgroup out of memory`

# **フリーズ・ハングアップ関連のメッセージ**
システムがフリーズやハングアップすると、`dmesg` や `vmstat` で以下のようなメッセージが確認できます：
- `Task <process_name> blocked for more than 120 seconds`
- `INFO: task <process_name> blocked`
- `soft lockup - CPU#<N> stuck for <time> seconds`
- `hard lockup - CPU#<N> stuck`
- `BUG: unable to handle kernel NULL pointer dereference`
- `Kernel panic - not syncing: Fatal exception`

**代表的なキーワード**
- `blocked`
- `soft lockup`
- `hard lockup`
- `kernel panic`
- `NULL pointer dereference`

# **メモリ不足関連のメッセージ**
`free` や `vmstat` コマンドを実行すると、メモリ不足の兆候を確認できます：
- `Mem: total=<value> used=<value> free=<value>`
- `Swap: total=<value> used=<value> free=<value>`
- `procs blocked`
- `high CPU usage`

**代表的なキーワード**
- `used`
- `free`
- `swap`
- `blocked`
- `high CPU usage`

これらのメッセージやキーワードを監視することで、OOMやフリーズ、ハングアップの兆候を早期に検出し、適切な対策を講じることができます。さらに詳しい情報は、[こちら](https://qiita.com/rarul/items/843e05a7bc18278e3188) や [こちら](https://zenn.dev/satoru_takeuchi/articles/bdbdeceea00a2888c580) を参考にしてください。

---

# Linuxでスワップ領域を設定する方法

## **スワップ領域の確認**
まず、現在のスワップ領域の状況を確認しましょう。

```bash
free -h
```
または

```bash
swapon --show
```
これにより、現在のスワップ領域のサイズや場所が表示されます。

## **スワップファイルの作成**
スワップ領域を追加する場合、スワップファイルを作成します。

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
```
このコマンドは、`/swapfile` に **1GB（1024MB）** のスワップファイルを作成します。  
2GB追加したい場合は、`count=2048` に変更してください。

## **スワップファイルのアクセス権限の変更**
スワップファイルは、セキュリティ上の理由から他のユーザーにアクセスされないようにする必要があります。

```bash
sudo chmod 600 /swapfile
```
これにより、スワップファイルのアクセス権限が変更されます。

## **スワップファイルをスワップ領域として設定**
作成したスワップファイルをスワップ領域として設定します。

```bash
sudo mkswap /swapfile
```
これにより、スワップファイルがスワップ領域としてフォーマットされます。

## **スワップファイルの有効化**
作成したスワップファイルをシステムに有効化させます。

```bash
sudo swapon /swapfile
```
これで、システムがスワップファイルを使用するようになります。

## **スワップファイルの永続化**
システム起動時にスワップファイルが自動的に有効化されるように、`/etc/fstab` にエントリを追加します。

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
これにより、スワップファイルが永続化され、再起動後も有効になります。

## **スワップ領域の確認**
最後に、新しく作成されたスワップ領域が正しく設定されているか確認しましょう。

```bash
free -h
```
または

```bash
swapon --show
```
これで、スワップ領域が作成され、システムがそれを使用するように設定されました。

スワップ領域の設定についてさらに詳しく知りたい場合は、[こちら](https://qiita.com/youareyouya/items/1f76fd8de74346130395) や [こちら](https://www.wakuwakubank.com/posts/685-linux-swap/) を参考にしてください。

---

# LinuxでOOM（Out of Memory）、フリーズ、ハングアップ、シャットダウン、再起動の実行を確認するためのコマンドとそのオプション、重要なキーワードについて

## **1. OOM（Out of Memory）の確認**
OOMが発生したかどうかを確認するには、`dmesg` コマンドを使用します。

### **コマンド**
```bash
dmesg | grep -i oom
```
### **主なオプション**
- `-T` : タイムスタンプを人間が読みやすい形式で表示
- `| grep -i oom` : OOM関連のログを抽出

#### **重要なキーワード**
- `Out of memory`
- `Killed process`
- `oom-killer`
- `memory cgroup out of memory`

## **2. フリーズ・ハングアップの確認**
システムがフリーズやハングアップしているかを確認するには、`dmesg` や `vmstat` を使用します。

### **コマンド**
```bash
dmesg | grep -i "task blocked"
vmstat 1 10
```
### **主なオプション**
- `| grep -i "task blocked"` : フリーズやハングアップの兆候を確認
- `vmstat 1 10` : 1秒ごとに10回のメモリ使用状況を表示

#### **重要なキーワード**
- `Task blocked`
- `soft lockup`
- `hard lockup`
- `kernel panic`
- `NULL pointer dereference`

## **3. シャットダウンの確認**
システムがシャットダウンした履歴を確認するには、`last` コマンドを使用します。

### **コマンド**
```bash
last -x shutdown reboot
```
### **主なオプション**
- `-x` : シャットダウンや再起動の履歴を表示
- `shutdown reboot` : シャットダウンと再起動のイベントを抽出

#### **重要なキーワード**
- `shutdown`
- `reboot`
- `system halted`
- `power off`

## **4. 再起動の確認**
システムが再起動した履歴を確認するには、`journalctl` を使用します。

### **コマンド**
```bash
journalctl -b -1 | grep -i "reboot"
```
### **主なオプション**
- `-b -1` : 前回のブートログを表示
- `| grep -i "reboot"` : 再起動のログを抽出

#### **重要なキーワード**
- `reboot`
- `systemd-shutdown`
- `Restarting system`
- `system boot`

これらのコマンドを活用することで、OOMやフリーズ、ハングアップ、シャットダウン、再起動の発生状況を詳細に確認できます。さらに詳しい情報は、[こちら](https://qiita.com/reiko_s/items/bee5e0259bd4d4e5394f) や [こちら](https://eng-entrance.com/linux-termination) を参考にしてください。

---

# Linuxのフリーズやハングアップの原因と、それに関連するエラーについて

## **フリーズとハングアップ**
フリーズとは、システムが一時的に応答しなくなる状態を指します。ハングアップは、システムが完全に停止し、操作を受け付けなくなる状態です。

### **主な原因**
- **メモリ不足**: OOM（Out of Memory）が発生し、プロセスが強制終了される。
- **CPU負荷の急増**: 高負荷のプロセスがCPUを占有し、システムが応答しなくなる。
- **ディスクI/Oの過負荷**: ストレージのアクセスが遅くなり、システム全体の動作が停止する。
- **カーネルのバグ**: カーネルやドライバの問題により、システムが異常動作する。

## **Blocked（タスクのブロック）**
Linuxでは、プロセスがリソースを待機している間、`blocked` 状態になります。  
例えば、ディスクI/Oの遅延やメモリ不足が原因で、プロセスが長時間ブロックされることがあります。

### **代表的なエラーメッセージ**
- `Task <process_name> blocked for more than 120 seconds`
- `INFO: task <process_name> blocked`
- `blocked tasks`

#### **対策**
- `dmesg | grep -i "task blocked"` でブロックされたプロセスを確認
- `iotop` でディスクI/Oの負荷を調査
- `kill -9 <PID>` で問題のあるプロセスを強制終了

## **Lockup（ソフトロックアップ・ハードロックアップ）**
**ソフトロックアップ** は、CPUが長時間割り込みを処理できない状態を指します。  
**ハードロックアップ** は、CPUが完全に停止し、システムが応答しなくなる状態です。

### **代表的なエラーメッセージ**
- `soft lockup - CPU#<N> stuck for <time> seconds`
- `hard lockup - CPU#<N> stuck`

#### **対策**
- `journalctl -k | grep -i "lockup"` でログを確認
- `top` や `htop` でCPU使用率を監視
- `sysctl -w kernel.watchdog_thresh=30` で監視時間を調整

## **Kernel Panic（カーネルパニック）**
カーネルパニックは、Linuxカーネルが致命的なエラーを検出し、システムの動作を停止する状態です。

### **代表的なエラーメッセージ**
- `Kernel panic - not syncing: Fatal exception`
- `Kernel panic - not syncing: hung_task: blocked tasks`
- `Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)`

#### **対策**
- `journalctl -k | grep -i "kernel panic"` でログを確認
- `sysctl -w kernel.panic=10` で自動再起動を設定
- カーネルのアップデートを実施

## **NULL Pointer Dereference（ヌルポインタ参照）**
カーネルやアプリケーションが、無効なメモリアドレスを参照すると発生するエラーです。

### **代表的なエラーメッセージ**
- `BUG: unable to handle kernel NULL pointer dereference`
- `Unable to handle kernel paging request`

#### **対策**
- `dmesg | grep -i "NULL pointer"` でログを確認
- カーネルモジュールの更新
- メモリ診断ツール（`memtest86+`）でハードウェアの問題をチェック

これらのエラーを監視し、適切な対策を講じることで、Linuxシステムの安定性を向上させることができます。さらに詳しい情報は、[こちら](https://cloud.google.com/compute/docs/troubleshooting/kernel-panic?hl=ja) や [こちら](https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/spurious-soft-lockups-in-virtualized-environments_keeping-kernel-panic-parameters-disabled-in-virtualized-environments) を参考にしてください。

---

# **NULLポインタデリファレンス（Null Pointer Dereference）とは？**
NULLポインタデリファレンスとは、プログラムが **NULL（無効なメモリアドレス）** を指すポインタを逆参照（dereference）しようとすることで発生するエラーです。  
このエラーが発生すると、プログラムがクラッシュしたり、予期しない動作を引き起こす可能性があります。

## **NULLポインタデリファレンスの原因**
- **未初期化ポインタの使用**: ポインタが適切なメモリアドレスを指していない状態でアクセスする。
- **メモリ解放後のポインタ使用**: `free()` で解放されたメモリを再度参照する。
- **関数の戻り値がNULL**: メモリ割り当てに失敗した場合、`malloc()` や `calloc()` が `NULL` を返すが、それをチェックせずに使用する。

#### **代表的なエラーメッセージ**
- `Segmentation fault (core dumped)`
- `BUG: unable to handle kernel NULL pointer dereference`
- `Null pointer exception`

## **デリファレンス（Dereference）とは？**
デリファレンス（dereference）とは、ポインタが指し示すメモリアドレスの値を取得する操作のことです。  
例えば、C言語では以下のようにデリファレンスを行います。

```c
int a = 10;
int *ptr = &a;  // ptrは変数aのアドレスを指す
printf("%d\n", *ptr);  // デリファレンスしてaの値を取得
```

この場合、`*ptr` によって `ptr` が指すメモリアドレスの値（`a` の値）を取得できます。

### **NULLポインタのデリファレンスの危険性**
```c
int *ptr = NULL;
printf("%d\n", *ptr);  // NULLポインタをデリファレンス → クラッシュ
```
このコードでは、`ptr` が `NULL` を指しているため、デリファレンスすると **セグメンテーションフォルト** が発生します。

## **NULLポインタデリファレンスの対策**
1. **ポインタの初期化**
   ```c
   int *ptr = NULL;  // 初期化しておく
   ```
2. **NULLチェック**
   ```c
   if (ptr != NULL) {
       printf("%d\n", *ptr);
   }
   ```
3. **メモリ解放後のポインタをNULLに設定**
   ```c
   free(ptr);
   ptr = NULL;
   ```

NULLポインタデリファレンスは、適切なチェックを行うことで防ぐことができます。  
さらに詳しい情報は、[こちら](https://wa3.i-3-i.info/word12818.html) や [こちら](https://af-e.net/c-language-null-pointers/) を参考にしてください。

---



