/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable import/no-dynamic-require */
import { Construct } from 'constructs';
import { S3Backend, TerraformStack } from 'cdktf';
import { provider } from '@cdktf/provider-aws';
import * as path from 'path';
import * as fs from 'fs';
import { BACKEND_NAME } from '../config';

export class AwsBaseStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new provider.AwsProvider(this, 'aws-provider', {
      region: 'ap-southeast-1',
    });

    const prereqStateFile = path.join(process.env.INIT_CWD!, `./terraform.${BACKEND_NAME}.tfstate`);

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
