import { provider } from '@cdktf/provider-aws';
import { DataAwsCallerIdentity } from '@cdktf/provider-aws/lib/data-aws-caller-identity';
import { TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { S3DynamodbRemoteBackend } from '../.gen/modules/s3-dynamodb-remote-backend';

export interface PreReqStackProps {
  backendName: string;
}

export class PreReqStack extends TerraformStack {
  constructor(scope: Construct, id: string, { backendName }: PreReqStackProps) {
    super(scope, id);

    const currentAccount = new DataAwsCallerIdentity(this, 'current-account', {});

    new provider.AwsProvider(this, 'aws-provider', {
      region: 'ap-southeast-1',
    });

    const bakend = new S3DynamodbRemoteBackend(this, 's3-dynamodb-remote-backend', {
      bucket: `${backendName}-${currentAccount.accountId}`,
      dynamodbTable: backendName,
    });

    new TerraformOutput(this, 'bucket', {
      value: bakend.bucket,
    });

    new TerraformOutput(this, 'dynamodbTable', {
      value: bakend.dynamodbTable,
    });
  }
}
