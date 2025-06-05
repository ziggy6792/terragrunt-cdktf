import { Construct } from 'constructs';
import { App, TerraformStack } from 'cdktf';
import { provider, s3Bucket } from '@cdktf/provider-aws';
import * as random from '@cdktf/provider-random';
// import { ImportedS3BucketWithEnvTag } from './.gen/modules/imported-s3-bucket-with-env-tag';

interface S3BucketWithEnvTagProps {
  env: 'dev' | 'prod';
  name: string;
}

class S3BucketWithEnvTag extends Construct {
  constructor(scope: Construct, id: string, { env, name }: S3BucketWithEnvTagProps) {
    super(scope, id);

    // Create the S3 bucket
    new s3Bucket.S3Bucket(this, 's3-bucket', {
      bucket: name,
      objectLockEnabled: true,
      tags: {
        env: env,
      },
    });
  }
}

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Configure the AWS provider
    new provider.AwsProvider(this, 'aws-provider', {
      region: 'ap-southeast-1', // change to your preferred region
    });

    // Configure the random provider
    new random.provider.RandomProvider(this, 'random-provider');

    const randomId = new random.id.Id(this, 'random-id', {
      byteLength: 4,
    });

    // Create the S3 bucket
    new s3Bucket.S3Bucket(this, 's3-bucket', {
      bucket: `cdktf-demo-bucket-1-${randomId.hex}`,
      objectLockEnabled: true,
    });

    new S3BucketWithEnvTag(this, 's3-bucket-with-env-tag', {
      name: `cdktf-demo-bucket-2-${randomId.hex}`,
      env: 'dev',
    });

    // new ImportedS3BucketWithEnvTag(this, 'imported-s3-bucket-with-env-tag', {
    //   env: 'dev',
    //   name: `cdktf-demo-bucket-3-${randomId.hex}`,
    // });
  }
}

const app = new App();
new MyStack(app, 'cdktf-demo');
app.synth();
