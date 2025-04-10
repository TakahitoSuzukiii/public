```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": "*"
        }
    ]
}
```

```
import boto3
import logging

# ロガーをセットアップ
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("start")
    
    # セット
    security_group_id = 'sg-06d14cfc87c7cf26a'  # 対象のセキュリティグループID
    ip_protocol = 'tcp'  # IPプロトコル
    port = 4000  # ポート番号（ダミーポート）
    ip_ranges = [
        {'CidrIp': '1.146.165.196/32', 'Description': 'Added for testing A'},
        {'CidrIp': '2.0.113.25/32', 'Description': 'Added for testing B'}
    ]    # CIDRと説明の複数ペア
    logger.info(f"セットした。セキュリティグループID: {security_group_id}, IPプロトコル: {ip_protocol}, ポート: {port}, ip_ranges: {ip_ranges}")
    
    ec2 = boto3.client('ec2')
    result = { 'statusCode': 200, 'body': 'No execute lambda' }
    try:
        logger.info("run try")
        
        # 対象のセキュリティグループの情報取得
        response = ec2.describe_security_groups(GroupIds=[security_group_id])
        logger.info(f"対象のセキュリティグループの情報を取得しました（セキュリティグループID: {security_group_id}, レスポンス: {response}）")

        # CIDRと説明のペアをループしてルールを追加
        ip_permissions = response['SecurityGroups'][0]['IpPermissions']
        for ip_range in ip_ranges:
            cidr_ip = ip_range['CidrIp']  # CIDRを取得
            if not isExistCidrIP(cidr_ip, port, ip_permissions):
                try:
                    logger.info(f"レスポンス4: {ip_range}）")
                    # インバウンドルールを追加
                    response = ec2.authorize_security_group_ingress(
                        GroupId=security_group_id,
                        IpPermissions=[
                            {
                                'IpProtocol': ip_protocol,
                                'FromPort': port,
                                'ToPort': port,
                                'IpRanges': [
                                    {
                                        'CidrIp': cidr_ip,
                                        'Description': ip_range['Description']
                                    }
                                ]
                            }
                        ]
                    )
                    logger.info(f"Rule added: IP {cidr_ip} with description '{ip_range['Description']}'")
                except Exception as add_error:
                    logger.warning(f"Failed to add rule for IP {cidr_ip}: {str(add_error)}")
            else:
                logger.info(f"Rule for IP {cidr_ip} already exists")

        result = { 'statusCode': 200, 'body': f'success result: {response}' }
        logger.info(f"成功しました: {result}")
    except Exception as e:
        result = { 'statusCode': 400, 'body': f'failure result: {str(e)}' }
        logger.error(f"失敗しました: {result}")
        raise e

    logger.info("finished")
    return result

def isExistCidrIP(cidr_ip: str, port: int, ip_permissions: list) -> bool:
    """
    CIDR IPがセキュリティグループのインバウンドルールに存在するかチェックする関数

    Args:
        cidr_ip (str): チェック対象のCIDR IPを含むIPレンジ
        port (int): チェック対象のポート番号
        ip_permissions (list): セキュリティグループのインバウンドルールのリスト

    Returns:
        bool: CIDR IPが存在すればTrue、なければFalse
    """
    return any(
        permission.get('FromPort') == port and
        permission.get('ToPort') == port and
        any(ip_range.get('CidrIp') == cidr_ip for ip_range in permission.get('IpRanges', []))
        for permission in ip_permissions
    )
```