# user-migration

設定確認
- バックアップを取る（新規のal2023）
- 新規のal2023でコマンドを実行し、出力を確認する
- エラーワードの有無をチェックする

Linuxアカウント移行
- 新規のal2023から1ユーザー（takahisu）を削除する
- （踏み台でコマンドを実行し、出力を確認する）
- 1ユーザー（takahisu）だけ移行する（踏み台→新規のal2023）

設定確認
- 作業内容を確認する
- 既存のal2でコマンドを実行し、出力を確認する
- エラーワードの有無をチェックする
- 1ユーザー（takahisu）だけ移行する（踏み台→既存のal2）

Linuxアカウント移行
- （踏み台でコマンドを実行し、出力を確認する）
- エラーワードの有無をチェックする
- 全ユーザーを移行する（既存のal2→新規のal2023）

## Linuxの設定確認

[【参考】Linux OSを移行する時に確認する設定をまとめてみた](https://dev.classmethod.jp/articles/linux-os-migration-checklist/)

### OSバージョン
```bash
cat /etc/os-release
```

### カーネルバージョン
```bash
cat /proc/version
uname -a
```

### OSホスト名
```bash
cat /etc/hostname
hostnamectl
hostname
```

### /etc/hosts
```bash
cat /etc/hosts
```

### 参照しているDNSサーバー
```bash
cat /etc/resolv.conf
```

```bash
dig
```
※Route 53 Resolverを使用する予定の場合は現在参照しているDNSサーバーの条件付きフォワーダーも確認しておくと良い

### /etc/nsswitch.conf
```bash
cat /etc/nsswitch.conf
```
※場合によっては以下記事で紹介しているようにsystemd-resolvedによる名前解決を実施している場合もある
- [[Amazon Linux 2023版] DHCP option setsで設定したDNSサーバー以外のDNSサーバーを指定する方法](https://dev.classmethod.jp/articles/amazon-linux-2023-static-dns/)

### 参照しているNTPサーバー
```bash
chronyc sources -v
cat /etc/chrony.conf
```
※場合によってはntpdかもしれない

### タイムゾーン
```bash
cat /etc/localtime
timedatectl
date
```

### システムロケール
```bash
cat /etc/locale.conf
localectl
```

### NIC毎のIPアドレスとMTU
  NIC毎のIPアドレスとMTUの確認
```bash
ifconfig -a
```


### ネットワークインターフェースの設定ファイル
```bash
ls -l /etc/sysconfig/network-scripts/ifcfg-*
cat /etc/sysconfig/network-scripts/ifcfg-eth0
```

### 静的ルート
```bash
ls -l /etc/sysconfig/network-scripts/route-*
cat /etc/sysconfig/network-scripts/route-eth0
route -n
ip route show
ip route show table all
routel
```

### マウントしている領域
```bash
cat /etc/fstab
df -h
findmnt
mount
```

### デバイスパーティション
```bash
parted -l
lsblk
```

### swap設定
```bash
swapon -s
cat /proc/swaps
```

### OSユーザー と OSグループ
```bash
cat /etc/passwd
cat /etc/group
```

### sudores設定
```bash
cat /etc/sudoers
ls -lR /etc/sudoers.d/
cat /etc/sudoers.d/90-cloud-init-users
```

### .bash_profile と .bashrc
  各OSユーザーで設定している環境変数やエイリアスの確認
```bash
ls -l /home/*/.bash*
```
※上記で確認し結果、/homeをtarで固めた方が良いかもしれない
```bash
cat /home/ec2-user/.bash_profile
cat /home/ec2-user/.bashrc
```

### SSH設定
```bash
cat /etc/ssh/sshd_config
ls -l /home/*/.ssh/authorized_keys
cat /home/ec2-user/.ssh/authorized_keys
```

### PAM
```bash
ls -l /etc/pam.d
cat /etc/pam.d/sshd
```

### サービス　※要確認
```bash
for service in $(systemctl list-unit-files --type=service --no-legend | awk '{print $1}'); do
    current=$(systemctl list-unit-files "$service" --no-legend | awk '{print $2}')
    preset=$(systemctl is-enabled "$service" 2>&1)
    if [[ "$preset" == *"enable"* ]]; then
      preset_state="enable"
    elif [[ "$preset" == *"disable"* ]]; then
      preset_state="disable"
    else
      preset_state="unknown"
    fi
    printf "%-40s %-15s %s\n" "$service" "$current" "$preset_state"
  done
```
```bash
ls -l /etc/systemd/system
cat /etc/systemd/system/amazon-ssm-agent.service
```

### /etc/init.dなどの起動スクリプトで実行している処理
```bash
ls -l /etc/init.d/
```

### /opt/配下
```bash
ls -lR /opt
```

### プロセス一覧
```bash
ps -ej uf
```

### 使用しているポート一覧
```bash
ss -antup
netstat -antup
```

### 各種ミドルウェアの設定
  インストールしているソフトウェア次第。
  サービス一覧やプロセス、空いているポートなどからどのようなミドルウェアが動作しているのかアタリを付け、設定を確認する

### logrorate
```bash
cat /etc/logrotate.conf
ls -l /etc/logrotate.d/
cat /etc/logrotate.d/syslog
```

### rsyslog
```bash
cat /etc/rsyslog.conf
ls -l /etc/rsyslog.d/
cat /etc/rsyslog.d/21-cloudinit.conf
cat /etc/rsyslog.d/listen.conf
```

### cronやsystemd-timerで定期実行している処理
```bash
cat /var/spool/cron/*
cat /etc/crontab
ls -l /etc/cron.*
```
```bash
systemctl list-timers
```

### iptablesやfirewalldによるファイアウォール設定
```bash
iptables -L
firewall-cmd --state
firewall-cmd --list-all-zones
```

### /etc/hosts.allow と /etc/hosts.deny
```bash
cat /etc/hosts.allow
cat /etc/hosts.deny
```

### SELinux
```bash
cat /etc/selinux/config
getenforce
sestatus
```

### 参照しているリポジトリ
```bash
yum repolist -v
dnf repolist -v
```

### 各種カーネルパラメーター
```bash
cat /etc/sysctl.conf
ls -l /etc/sysctl.d/
cat /etc/sysctl.d/00-defaults.conf
sysctl -a
```

### リソース制限
```bash
ls -l /etc/security/limits.*
cat /etc/security/limits.conf
```

### 追加の確認事項　※必要に応じて確認
#### 自分でビルドしたバイナリ
```bash
/usr/local/bin/
```

#### rootから2階層分のディレクトリ
```bash
tree / -d -l -L 2
```

## バックアップ

### イメージ取得

### 操作対象のファイルのバックアップ

#### グループ1
- /etc/passwd
- /etc/group
- /etc/shadow
- /etc/gshadow

#### グループ2
- /home/userディレクトリ
- /var/spool/mailディレクトリ

### 移行したいアカウントファイルの作成

#### 既存と新規の/etc/passwdの差分を確認
  ※移行したいアカウントのみ抽出する
```bash
etc_passwd_migrationYYYYMMDD.txt
```

#### 新規サーバの/etc/passwdへの追記
```bash
cat etc_passwd_migrationYYYYMMDD.txt >> /etc/passwd
```
　
#### /etc/shadowの更新
```bash
pwconv
```

#### パスワードファイルのチェック
```bash
pwck
```

#### 既存と新規の/etc/groupの差分を確認
  ※移行したいアカウントのみ抽出する
```bash
etc_group_migrationYYYYMMDD.txt
```

#### 新規サーバの/etc/groupへの追記
```bash
cat etc_group_migrationYYYYMMDD.txt >> /etc/group
```
　
#### /etc/shadowの更新
```bash
grpconv
```

#### パスワードファイルのチェック
```bash
grpck
```

# 20250502追記

## network

```bash
ip
ip route
ip neigh
ss
```

```bash
ip a
ip addr show
ip route show
ip neigh show
ss -tulnp
```
