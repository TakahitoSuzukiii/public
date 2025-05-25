# CloudFormation

- リソース
- テンプレート
- スタック
- StackSet

## 環境構築

[AWS コマンドラインインターフェイス](https://aws.amazon.com/jp/cli)

## cli

https://docs.aws.amazon.com/cli/latest/reference/cloudformation/#cli-aws-cloudformation

### [describe-stacks](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/describe-stacks.html)

```bash
aws cloudformation describe-stacks --stack-name myteststack
```

### [create-stack](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudformation/create-stack.html)

```bash
aws cloudformation create-stack --stack-name myteststack --template-body file://sampletemplate.json --parameters ParameterKey=KeyPairName,ParameterValue=TestKey ParameterKey=SubnetIDs,ParameterValue=SubnetID1\\,SubnetID2
```
