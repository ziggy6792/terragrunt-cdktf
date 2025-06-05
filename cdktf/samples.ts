// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
// Use this for make code look pretty and formated
export {};

// Start
import { Construct } from 'constructs';
import { App, TerraformStack, TerraformOutput } from 'cdktf';

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // define resources here
    new TerraformOutput(this, 'lets-go', { value: 'lets go!' });
  }
}

const app = new App();
new MyStack(app, 'cdktf-name-picker');
app.synth();

// Slide 17

// import { provider } from '@cdktf/provider-aws';

// Import the AWS provider

new provider.AwsProvider(this, 'aws-provider', {
  region: 'us-east-1',
});

// Slide 20

const lambdaRole = new iamRole.IamRole(this, 'lambda-execution-role', {
  name: `cdktf-name-picker-api-execution-role`,
  assumeRolePolicy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [],
  }),
});

// Slide 29

const lambdaRole = new iamRole.IamRole(this, 'lambda-execution-role', {
  name: `name-picker-execution-role`,
  assumeRolePolicy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Principal: {
          Service: 'lambda.amazonaws.com',
        },
        Action: 'sts:AssumeRole',
      },
    ],
  }),
});

// Slide 40

import { iamRole } from '@cdktf/provider-aws';
import { Construct } from 'constructs';

interface LambdaFunctionProps {
  functionName: string;
}

export class LambdaFunction extends Construct {
  constructor(scope: Construct, id: string, { functionName }: LambdaFunctionProps) {
    super(scope, id);

    // Create IAM role for Lambda
    const lambdaRole = new iamRole.IamRole(this, 'lambda-execution-role', {
      name: `${functionName}-execution-role`,
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: 'lambda.amazonaws.com',
            },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
    });

    // ToDo: Attach policy to the role
    // This policy attachment grants Lambda function basic required permissions (e.g: Logging in CloudWach):
    // policyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',

    // ToDo: Create Lambda function
  }
}
// Copy to main
new LambdaFunction(this, 'lambda-function', {
  functionName: 'cdktf-name-picker-api',
});

// Fill in ToDos
import { lambdaFunction, iamRole, iamRolePolicyAttachment } from '@cdktf/provider-aws';
import { LambdaFunctionConfig } from '@cdktf/provider-aws/lib/lambda-function';
import { Construct } from 'constructs';
import { get } from 'http';

interface LambdaFunctionProps extends Omit<LambdaFunctionConfig, 'role'> {
  functionName: string;
}

export class LambdaFunction extends Construct {
  public readonly lambdaFunction: lambdaFunction.LambdaFunction;

  constructor(scope: Construct, id: string, { functionName, filename, ...rest }: LambdaFunctionProps) {
    super(scope, id);

    // Create IAM role for Lambda
    const lambdaRole = new iamRole.IamRole(this, 'lambda-execution-role', {
      name: `${functionName}-execution-role`,
      assumeRolePolicy: JSON.stringify({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: 'lambda.amazonaws.com',
            },
            Action: 'sts:AssumeRole',
          },
        ],
      }),
    });

    // Attach policy to the role
    new iamRolePolicyAttachment.IamRolePolicyAttachment(this, 'LambdaExecutionRolePolicy', {
      role: lambdaRole.name,
      policyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
    });

    this.lambdaFunction = new lambdaFunction.LambdaFunction(this, 'lambda-function', {
      functionName,
      role: lambdaRole.arn,
      runtime: 'nodejs18.x',
      filename,
      timeout: 30,
      ...rest,
    });
  }
}

// Copy to main
new LambdaFunction(this, 'lambda-function', {
  filename: path.join(process.env.INIT_CWD!, './function-name-picker/index.js.zip'),
  functionName: getConstructName(this, 'api'),
  handler: 'index.handler',
});

// Slide 46

// ToDo
// Recieve bundle prop insead
interface LambdaFunctionProps extends Omit<LambdaFunctionConfig, 'role' | 'filename'> {
  bundle: string;
  functionName: string;
}

// ToDo:
// Zip the bundle using execSync
// rm -rf ./out && mkdir -p ./out && cd BUNDLE_FOLDER && zip -r FILENAME .

// Slide 55

// Create a Terraform asset for the Lambda code
const asset = new TerraformAsset(this, `lambda-asset`, {
  path: path.join(process.env.INIT_CWD!, bundle), // Path to the folder containing the Lambda code
  type: AssetType.ARCHIVE, // This will package the folder as a ZIP archive
});

filename: asset.path; // Use the path of the Terraform asset

// Slide 64

import { Construct } from 'constructs';
import {
  lambdaFunction,
  apiGatewayRestApi,
  apiGatewayDeployment,
  apiGatewayResource,
  apiGatewayMethod,
  apiGatewayIntegration,
  lambdaPermission,
} from '@cdktf/provider-aws';
import { getConstructName } from '../utils/utils';

interface LambdaRestApiProps {
  handler: lambdaFunction.LambdaFunction;
  stageName: string;
}

export class LambdaRestApi extends Construct {
  constructor(scope: Construct, id: string, { handler, stageName }: LambdaRestApiProps) {
    super(scope, id);

    const restApi = new apiGatewayRestApi.ApiGatewayRestApi(this, 'rest-api', {
      name: getConstructName(this, 'rest-api'),
    });

    this.createApiGatewayLambdaMethod('root', restApi, restApi.rootResourceId, handler);

    const proxyResource = new apiGatewayResource.ApiGatewayResource(this, 'proxy-resource', {
      restApiId: restApi.id,
      parentId: restApi.rootResourceId,
      pathPart: '{proxy+}',
    });

    this.createApiGatewayLambdaMethod('proxy-resource', restApi, proxyResource.id, handler);

    // Add Lambda permission to allow API Gateway to invoke the Lambda function
    new lambdaPermission.LambdaPermission(this, 'api-gateway-permission', {
      action: 'lambda:InvokeFunction',
      functionName: handler.functionName,
      principal: 'apigateway.amazonaws.com',
      sourceArn: `${restApi.executionArn}/*/*`,
    });

    const deployment = new apiGatewayDeployment.ApiGatewayDeployment(this, 'deployment', {
      restApiId: restApi.id,
      stageName,
      dependsOn: [proxyResource, handler],
    });

    // ToDo
    // Expose the URL of the API Gateway as a string property
  }

  // ToDo
  // Implement this function
  // Add apiGatewayMethod.ApiGatewayMethod with id `${idPrefix}-method`
  // Add apiGatewayIntegration.ApiGatewayIntegration with id `${idPrefix}-method`
  private createApiGatewayLambdaMethod(
    idPrefix: string,
    restApi: apiGatewayRestApi.ApiGatewayRestApi,
    resourceId: string,
    apiLambda: lambdaFunction.LambdaFunction
  ) {}
}
