# sudo

- [知らないとおじさん？なLinuxコマンド 3選【もう古い】](https://staffblog.amelieff.jp/entry/2021/11/08/110000)
- [sudo su とかしてる人はだいたいおっさん](https://zenn.dev/tmtms/articles/202105-sudo-su#%E3%81%BE%E3%81%A8%E3%82%81)

## 1. 古いLinuxコマンドとその代替
### tarコマンドの使い方
従来の方法:
```bash
tar xzvf ABC.tar.gz
```
オプション:
- `x` : ファイルを展開
- `z` : gzip形式で圧縮・展開
- `v` : 詳細なログを出力
- `f` : ファイル名を指定

**新しい方法:**  
GNU tarのアップデートにより、ファイル形式の自動判別機能が追加され、`z`オプションは不要に。
```bash
tar xvf ABC.tar.gz
```
また、オプションには `-` を付けるのが推奨される。
```bash
tar -xvf ABC.tar.gz
```

### sudo su の代替
従来の方法:
```bash
sudo su
```
これはログインユーザのsudo権限を使ってrootユーザに切り替えるが、現在は `sudo -s` の使用が推奨される。
```bash
sudo -s
```
違い:
- `sudo su` はログインユーザのデフォルトシェルを使用
- `sudo -s` は現在の環境変数 `$SHELL` を使用

また、ログインシェルとして実行する場合は `sudo su -` ではなく `sudo -i` を使うのが推奨される。
```bash
sudo -i
```
違い:
- `sudo su -` は環境変数をクリアするが、`TERM` は保持
- `sudo -i` も環境変数をクリアするが、より適切なログインシェルの動作をする

### ifconfig の代替
従来の方法:
```bash
ifconfig
```
このコマンドは現在非推奨であり、代わりに `ip` コマンドを使用する。
```bash
ip a
```
その他のネットワーク関連コマンドも `ip` コマンドで代用可能。

## 2. sudoコマンドの詳細な挙動
### su コマンドの動作
```bash
su
```
- rootユーザになる場合は `su` のみ
- 特定のユーザに切り替える場合は `su ユーザ名`
- `su -` を使うとログインシェルとして実行され、環境変数がクリアされる

### sudo コマンドの動作
```bash
sudo コマンド
```
- `su` はシェルを起動するが、`sudo` は指定したコマンドのみを実行
- `sudo su` は `sudo -s` とほぼ同じだが、シェルの動作が異なる
- `sudo su -` は `sudo -i` とほぼ同じだが、環境変数のクリアが強い

## まとめ
- `tar` の `z` オプションは不要
- `sudo su` より `sudo -s` や `sudo -i` を使用
- `ifconfig` は `ip` コマンドで代用
