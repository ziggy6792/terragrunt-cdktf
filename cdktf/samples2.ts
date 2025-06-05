// @ts-nocheck
export {};

// Slide 73

// Add to main
new S3Backend(this, {
  bucket: 'cdktf-name-picker-backend', // We need to create this somehow
  dynamodbTable: 'cdktf-name-picker-locks', // We need to create this somehow
  region: 'us-east-1',
  key: 'state-file',
});


// Slide 82


https://developer.hashicorp.com/terraform/cdktf/concepts/modules 

https://registry.terraform.io/modules/my-devops-way/s3-dynamodb-remote-backend/aws/0.0.1?tab=outputs


// Add to cdktf.json
"terraformModules": [
  {
    "name": "s3-dynamodb-remote-backend",
    "source": "my-devops-way/s3-dynamodb-remote-backend/aws"
  }
],

// Add to main.ts
const bakend = new S3DynamodbRemoteBackend(this, 's3-dynamodb-remote-backend', {
  bucket: 'cdktf-name-picker-backend',
  dynamodbTable: 'cdktf-name-picker-locks',
});


// Slide 85

// Copy out name picker stack from main.ts


// Create PreReqStack.ts
import { Construct } from 'constructs';
import { TerraformOutput, TerraformStack } from 'cdktf';
import { provider } from '@cdktf/provider-aws';
import { DataAwsCallerIdentity } from '@cdktf/provider-aws/lib/data-aws-caller-identity';
import { S3DynamodbRemoteBackend } from '../.gen/modules/s3-dynamodb-remote-backend';

export interface PreReqStackProps {
  backendName: string;
}

export class PreReqStack extends TerraformStack {
  constructor(scope: Construct, id: string, { backendName }: PreReqStackProps) {
    super(scope, id);

    const currentAccount = new DataAwsCallerIdentity(this, 'current-account', {});

    new provider.AwsProvider(this, 'aws-provider', {
      region: 'us-east-1',
    });

    // ToDo
    // Add S3DynamodbRemoteBackend
    // Use accountId in bucket name
    // Output
    // bucket = bakend.bucket
    // dynamodbTable = bakend.dynamodbTable   
  }
}

// Copy in 
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



// Add condig.ts (type it out)
export const PROJECT_NAME = 'cdktf-name-picker';
export const BACKEND_NAME = `${PROJECT_NAME}-prereq`;

// Add prereq.ts (type it out)
import { App } from 'cdktf';
import { PreReqStack } from './stacks/PreReqStack';
import { BACKEND_NAME } from './config';

const app = new App();

new PreReqStack(app, BACKEND_NAME, { backendName: BACKEND_NAME });

app.synth();

// Say: now i need to deploy the prereq
// In package.json
{
"deploy:prereq": "cdktf deploy --app='yarn ts-node prereq.ts'",
}

`yarn deploy:prereq`
// Run command (refer to slide)
// Show it exists in console?


`
pick up 34:54
`

//  AwsBaseStack.ts copy in

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
      region: 'us-east-1',
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
    // ToDo
    // Add S3Backend
  }
}

// Type in
new S3Backend(this, {
  bucket: prereqState.outputs.bucket.value, // Get from output of prerequisite state file
  dynamodbTable: prereqState.outputs.dynamodbTable.value, // Get from output of prerequisite state file
  region: 'us-east-1',
  key: id, // The name of this stack
});



`
Delete S3Backend
Extend in NamePickerStack.ts + remove provider (not yet)

Now we are migrating state to remote backend
This is complicated
Normally you don't need to do this

deploy local again (coz shared state gen folder, i think would not be needed if in monorepo)

now switch it over to AwsBaseStack
yarn synth (Refer to slide)

cd cdktf.out/stacks/cdktf-name-picker //Just like any other terraform project (do for all stacks)
terraform init -migrate-state
(show in console)

cd to root
yarn deploy (Refer to slide)

Delete local state

Finish slides
`


// Slide 94

import { Construct } from 'constructs';
import { TerraformOutput } from 'cdktf';
import { AwsBaseStack } from './AwsBaseStack';

export class WeekPlannerStack extends AwsBaseStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new TerraformOutput(this, 'weekPickerApiUrl', {
      value: 'https://example.com',
    });
  }
}

// main.ts
new WeekPlannerStack(app, 'cdktf-week-planner')

// Show bucket in console

new NamePickerStack(app, PROJECT_NAME + '-prod', 'prod');

// Back up lab

// End. Reset the lab 




// Redo

`
yarn cdktf get

deploy local (remove AWSBaseStack)
deploy:prereq
`




`


pick up 34:54

Now we are migrating state to remote backend
This is complicated
Normally you don't need to do this

deploy local again (coz shared state gen folder, i think would not be needed if in monorepo)

cd cdktf.out/stacks/cdktf-name-picker //Just like any other terraform project (do for all stacks)
terraform init -migrate-state
(show in console)

cd to root
yarn deploy


'pick up 3:00'

`

// Slide 94

import { Construct } from 'constructs';
import { TerraformOutput } from 'cdktf';
import { AwsBaseStack } from './AwsBaseStack';

export class WeekPlannerStack extends AwsBaseStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new TerraformOutput(this, 'weekPickerApiUrl', {
      value: 'https://example.com',
    });
  }
}

// main.ts
new WeekPlannerStack(app, 'cdktf-week-planner')


`
Show prod deploy
`
new NamePickerStack(app, PROJECT_NAME + '-prod');
`yarn deploy`
// Show in console

'Re-record final demo'
// Curl, show bug, still says /dev (q2 of lab will fix this)
// Tips for lab
// Show configure names (from ts and from console)
