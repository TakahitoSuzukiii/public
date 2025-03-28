# path

C:\Users\TAKAHITO SUZUKI\OneDrive\デスクトップ\dev\al2023

# test-al2023-alpha

i-0ed8be62b1364f3a5 (test-al2023-alpha-ec2-bastion)

# ec2

test-al2023-alpha-ec2-bastion-windows2019-public1-ap-northeast-1a

## user name

Administrator

## local ubuntu

wsl -d Ubuntu

## user

tttsuzukiii

## linux ubuntu

<!-- adduser tttsuzukiii -->

useradd -m tttsuzukiii

<!-- userdel tttsuzukiii -->

<!-- groups root -->

groups tttsuzukiii

<!-- usermod -aG root tttsuzukiii -->

<!-- groups root -->
<!-- groups tttsuzukiii -->

<!-- cat /etc/sudo.conf -->
<!-- vi /etc/sudo.conf -->

<!-- usermod -aG sudo tttsuzukiii -->
<!-- gpasswd -a tttsuzukiii sudo -->

<!-- visudo -->
<!-- tttsuzukiii ALL=(ALL:ALL) ALL -->

usermod -aG wheel tttsuzukiii

<!--  gpasswd -d tttsuzukiii wheel -->

sudo -l

passwd tttsuzukiii

sudo su -
exit

# ssh

mkdir -p ~/.ssh
chmod 700 ~/.ssh

touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

sudo su -

## win powershell

Get-LocalUser
Get-LocalUser | Select-Object Name, Enabled, Description

icacls "id_ed25519_test-al2023-alpha-ec2-bastion-key" /inheritance:r
icacls ".\test-al2023-alpha-ec2-bastion-key-pair.pem" /grant:r "TAKAHITO SUZUKI:(R)"

icacls "C:\Users\TAKAHITO SUZUKI\.ssh\id_ed25519_test-al2023-alpha-ec2-bastion-ssh-keygen"

id_ed25519_test-al2023-alpha-ec2-bastion-ssh-keygen
"C:\Users\TAKAHITO SUZUKI\.ssh\id_ed25519_test-al2023-alpha-ec2-bastion-ssh-keygen"

## chmod

cat ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub

### 秘密鍵

chmod 600 ~/.ssh/id_rsa

### 公開鍵

chmod 644 ~/.ssh/id_rsa.pub

## ssh

ssh -i "id_ed25519_est-al2023-alpha-bastion-sshkey" ec2-user@3.112.46.228

# linux al2 init

dnf update -y
yum update -y

hostnamectl set-hostname bastion01-al2

systemctl list-units --type=service --state=running
systemctl list-unit-files --type=service --state=enabled

# linux al2023 init

## init

hostnamectl
hostnamectl set-hostname bastion01-al2023

localectl status

<!-- localectl set-locale LANG=ja_JP.UTF-8 -->
<!-- source /etc/locale.conf -->

timedatectl
timedatectl set-timezone Asia/Tokyo

cat /etc/logrotate.conf
vi /etc/logrotate.conf
logrotate -d /etc/logrotate.conf

# windows 2019 init

言語を日本語に変更
WindowsUpdate の実施
タイムゾーンの変更

# teraterm5

tail -f log.txt | grep --color=auto -E 'err|warn'
awk '/warn/ {print "\033

err
warn
critical
alert
fail
exception
severe
fatal
abort
urgent
issue
problem
unexpect
significant

tail -f log.txt | grep --color=always -E 'err|warn|critical|alert|fail|exception|severe|fatal|abort|urgent|issue|problem|unexpect|significant'

tail -f log.txt | awk '
/(err|warn|critical|alert|fail)/ {
print "\033

# naming

test-al2023-alpha-ami-bastion-public1-ap-northeast-1a-linux-al2023

ec2-public1-ap-northeast-1a-test-al2023-alpha-bastion-linux-al2
ec2-public1-ap-northeast-1a-test-al2023-alpha-bastion-linux-al2023
ec2-public1-ap-northeast-1a-test-al2023-alpha-bastion-windows-2019

ec2-private1-ap-northeast-1a-test-al2023-alpha-app11-linux-al2023
ec2-private1-ap-northeast-1a-test-al2023-alpha-app21-windows-2019

20250320-ami-public1-ap-northeast-1a-test-al2023-alpha-bastion-linux-al2
20250320-ami-public1-ap-northeast-1a-test-al2023-alpha-bastion-linux-al2023
20250320-ami-public1-ap-northeast-1a-test-al2023-alpha-bastion-windows-2019

# cloud shell

echo $SHELL
cat /etc/os-release

env | grep AWS
aws configure list

export AWS_REGION=ap-northeast-1
export AWS_ACCESS_KEY_ID="set-access-key"
export AWS_SECRET_ACCESS_KEY="set-secret-access-key"
aws configure list

### 一時的に発行される STS (Security Token Service) トークン

export AWS_SESSION_TOKEN="SessionToken"
echo $AWS_SESSION_TOKEN

- [IAM Identity Center を使用する方法](https://zenn.dev/fumi_mizu/articles/a9d67f2d687cf5#8.-%E5%88%A5%E3%82%BF%E3%83%96%E3%81%A7%E3%83%AA%E3%83%AD%E3%83%BC%E3%83%89%E3%81%97%E3%81%A6%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%82%AD%E3%83%BC%E3%82%92%E5%85%A5%E6%89%8B)
- [アクセスキー/シークレットキーが漏洩してしまった！一体何をすればいいの?](https://dev.classmethod.jp/articles/leak-accesskey-what-do-i-do/)
- [【全員必須】GuardDuty がコスパ最強の脅威検知サービスであることを証明してみた](https://dev.classmethod.jp/articles/guardduty-si-strongest-thread-detection/)

## describe instance

'''
aws ec2 describe-instances --output table
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, State.Name]" --output table
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" --output table
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" --output table
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" --output table
'''

aws ec2 describe-instances \
 --instance-ids $(jq -r '.Instances[].InstanceId' ~/cloudshell-work/instance-ids.json) \
 --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" \
 --output text

aws ec2 describe-instances \
 --instance-ids $(jq -r '.Instances[].InstanceId' ~/cloudshell-work/instance-ids.json) \
 --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0], PublicIpAddress, PrivateIpAddress, State.Name]" \
 --output table

## run instance

comming soon.

## start instance

aws ec2 start-instances --instance-ids i-085fd15139ae40837
aws ec2 start-instances --instance-ids i-085fd15139ae40837 --output text

aws ec2 start-instances --instance-ids i-085fd15139ae40837 i-0ed8be62b1364f3a5
aws ec2 start-instances \
 --instance-ids i-085fd15139ae40837 i-0ed8be62b1364f3a5 \
 --output text

aws ec2 start-instances \
 --instance-ids $(jq -r '.Instances[].InstanceId' ~/cloudshell-work/instance-ids.json) \
 --output text

## stop instance

aws ec2 stop-instances --instance-ids i-085fd15139ae40837
aws ec2 stop-instances --instance-ids i-085fd15139ae40837 --output text

aws ec2 stop-instances --instance-ids i-085fd15139ae40837 i-0ed8be62b1364f3a5
aws ec2 stop-instances \
 --instance-ids i-085fd15139ae40837 i-0ed8be62b1364f3a5 \
 --output text

aws ec2 stop-instances \
 --instance-ids $(jq -r '.Instances[].InstanceId' ~/cloudshell-work/instance-ids.json) \
 --output text

## ping

ping -c 4 8.8.8.8
ping -c 4 google.com

## create ami

OK

## describe application load balance rule

ping google.com

nslookup

netstat
