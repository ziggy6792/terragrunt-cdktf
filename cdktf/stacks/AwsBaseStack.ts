import * as fs from 'fs';
import * as path from 'path';
import { provider } from '@cdktf/provider-aws';
import { S3Backend, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { BACKEND_NAME } from '../config';

export interface AwsBaseStackProps {
  env: 'dev' | 'prod';
}

export class AwsBaseStack extends TerraformStack {
  constructor(scope: Construct, id: string, { env }: AwsBaseStackProps) {
    super(scope, id);

    new provider.AwsProvider(this, 'aws-provider', {
      region: 'ap-southeast-1',
    });

    const prereqStateFile = path.join(process.env.INIT_CWD!, `./terraform.${BACKEND_NAME}-${env}.tfstate`);

    let prereqState = null;
    try {
      prereqState = JSON.parse(fs.readFileSync(prereqStateFile, 'utf-8'));
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        throw new Error(`Could not find prerequisite state file: ${prereqStateFile}`);
      }
      throw error;
    }

    // Only one backend is supported by Terraform
    // S3 Backend - https://www.terraform.io/docs/backends/types/s3.html
    new S3Backend(this, {
      bucket: prereqState.outputs.bucket.value, // Get from output of prerequisite state file
      dynamodbTable: prereqState.outputs.dynamodbTable.value, // Get from output of prerequisite state file
      region: 'ap-southeast-1',
      key: id, // The name of this stack
    });
  }
}
