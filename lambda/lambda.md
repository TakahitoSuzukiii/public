# allow ip

## role
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "arn:aws:ec2:region:account-id:security-group/sg-xxxxxxxxxxxxxxxxx"
        }
    ]
}
```

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

       def rule_exists(permission, ip_address):
            return (
                permission['IpProtocol'] == ip_protocol and
                any(ip_range['CidrIp'] == ip_address for ip_range in permission.get('IpRanges', []))
            )

            {'SecurityGroups': [{'GroupId': 'sg-06d14cfc87c7cf26a', 'IpPermissionsEgress': [{'IpProtocol': '-1', 'UserIdGroupPairs': [], 'IpRanges': [{'CidrIp': '0.0.0.0/0'}], 'Ipv6Ranges': [], 'PrefixListIds': []}], 'Tags': [{'Key': 'name', 'Value': 'test-al2023-alpha-sg-ec2-bastion'}], 'VpcId': 'vpc-05a3d39cdd8209888', 'SecurityGroupArn': 'arn:aws:ec2:ap-northeast-1:211125326284:security-group/sg-06d14cfc87c7cf26a', 'OwnerId': '211125326284', 'GroupName': 'test-al2023-alpha-sg-ec2-bastion', 'Description': 'test-al2023-alpha-sg-ec2-bastion', 'IpPermissions': [{'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'UserIdGroupPairs': [], 'IpRanges': [{'Description': 'SSH', 'CidrIp': '220.146.165.196/32'}], 'Ipv6Ranges': [], 'PrefixListIds': []}, {'IpProtocol': 'icmp', 'FromPort': -1, 'ToPort': -1, 'UserIdGroupPairs': [], 'IpRanges': [{'CidrIp': '0.0.0.0/0'}], 'Ipv6Ranges': [], 'PrefixListIds': []}, {'IpProtocol': 'tcp', 'FromPort': 3389, 'ToPort': 3389, 'UserIdGroupPairs': [], 'IpRanges': [{'Description': 'RDP', 'CidrIp': '220.146.165.196/32'}], 'Ipv6Ranges': [], 'PrefixListIds': []}]}], 'ResponseMetadata': {'RequestId': '2aa5174f-180e-493c-88c5-a4d06a05dce1', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '2aa5174f-180e-493c-88c5-a4d06a05dce1', 'cache-control': 'no-cache, no-store', 'strict-transport-security': 'max-age=31536000; includeSubDomains', 'content-type': 'text/xml;charset=UTF-8', 'content-length': '1536', 'date': 'Thu, 10 Apr 2025 18:17:24 GMT', 'server': 'AmazonEC2'}, 'RetryAttempts': 0}}

            exists = any(
                rule_exists(permission, cidr_ip)
                for permission in response['SecurityGroups'][0]['IpPermissions']
            )

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
    cidr_ip_description_pairs = [  # CIDRと説明のペア
        {'CidrIp': '220.146.165.196/32', 'Description': 'Added for testing A'},
        {'CidrIp': '203.0.113.25/32', 'Description': 'Added for testing B'}
    ]
    port = 4000  # 固定ポート番号

    ec2 = boto3.client('ec2')
    result = {'statusCode': 200, 'body': 'Lambda execution completed'}

    try:
        # セキュリティグループの現在のルールを取得
        response = ec2.describe_security_groups(GroupIds=[security_group_id])
        logger.info("セキュリティグループの情報を取得しました")

        # 現在のルールをチェックするための関数
        def rule_exists(permission, ip_address):
            return (
                permission['IpProtocol'] == ip_protocol and
                any(ip_range['CidrIp'] == ip_address for ip_range in permission.get('IpRanges', []))
            )

        # CIDRと説明のペアをループしてルールを追加
        for pair in cidr_ip_description_pairs:
            cidr_ip = pair['CidrIp']
            description = pair['Description']

            exists = any(
                rule_exists(permission, cidr_ip)
                for permission in response['SecurityGroups'][0]['IpPermissions']
            )

            if not exists:
                try:
                    logger.info(f"Adding rule for IP {cidr_ip} with description '{description}'")
                    ec2.authorize_security_group_ingress(
                        GroupId=security_group_id,
                        IpPermissions=[
                            {
                                'IpProtocol': ip_protocol,
                                'FromPort': port,
                                'ToPort': port,
                                'IpRanges': [
                                    {
                                        'CidrIp': cidr_ip,
                                        'Description': description
                                    }
                                ]
                            }
                        ]
                    )
                    logger.info(f"Rule added: IP {cidr_ip}, Description: {description}")
                except Exception as add_error:
                    logger.error(f"Failed to add rule for IP {cidr_ip}: {str(add_error)}")
            else:
                logger.info(f"Rule for IP {cidr_ip} already exists")

            # Optional: revoke logic
            try:
                logger.info(f"Attempting to revoke rule for IP {cidr_ip}")
                ec2.revoke_security_group_ingress(
                    GroupId=security_group_id,
                    IpPermissions=[
                        {
                            'IpProtocol': ip_protocol,
                            'FromPort': port,
                            'ToPort': port,
                            'IpRanges': [
                                {
                                    'CidrIp': cidr_ip
                                }
                            ]
                        }
                    ]
                )
                logger.info(f"Rule revoked: IP {cidr_ip}")
            except Exception as revoke_error:
                # 例外をスローせず、ログに記録するだけ
                logger.warning(f"Failed to revoke rule for IP {cidr_ip}: {str(revoke_error)}")

    except Exception as e:
        result = {'statusCode': 400, 'body': f"Error occurred: {str(e)}"}
        logger.error(f"失敗しました: {result}")
        raise e

    logger.info("finished")
    return result
========

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
        {'CidrIp': '220.146.165.196/32', 'Description': 'Added for testing A'},
        {'CidrIp': '203.0.113.25/32', 'Description': 'Added for testing B'}
    ]  # CIDRと説明の複数ペア

    ec2 = boto3.client('ec2')
    result = {'statusCode': 200, 'body': 'No execute lambda'}
    try:
        logger.info("run try")
        
        # 対象のセキュリティグループの情報取得
        response = ec2.describe_security_groups(GroupIds=[security_group_id])
        logger.info(f"対象のセキュリティグループの情報を取得しました（セキュリティグループID: {security_group_id}, レスポンス: {response}）")

        # インバウンドルール情報を取得
        ip_permissions = response['SecurityGroups'][0]['IpPermissions']

        # CIDRと説明のペアをループしてルールを追加
        for ip_range in ip_ranges:
            cidr_ip = ip_range['CidrIp']  # CIDRを取得
            if not isExistCidrIP(cidr_ip, ip_permissions):  # 修正済みロジック
                try:
                    logger.info(f"Adding rule for IP {cidr_ip} with description '{ip_range['Description']}'")
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
                    logger.error(f"Failed to add rule for IP {cidr_ip}: {str(add_error)}")
            else:
                logger.info(f"Rule for IP {cidr_ip} already exists")

        result = {'statusCode': 200, 'body': 'All rules processed successfully'}
        logger.info(f"成功しました: {result}")
    except Exception as e:
        result = {'statusCode': 400, 'body': f'failure result: {str(e)}'}
        logger.error(f"失敗しました: {result}")
        raise e

    logger.info("finished")
    return result

def isExistCidrIP(cidr_ip: str, ip_permissions: list) -> bool:
    """
    CIDR IPがセキュリティグループのインバウンドルールに存在するかチェックする関数

    Args:
        cidr_ip (str): チェック対象のCIDR IP
        ip_permissions (list): セキュリティグループのインバウンドルールのリスト

    Returns:
        bool: CIDR IPが存在すればTrue、なければFalse
    """
    return any(
        any(ip_range.get('CidrIp') == cidr_ip for ip_range in permission.get('IpRanges', []))
        for permission in ip_permissions
    )
