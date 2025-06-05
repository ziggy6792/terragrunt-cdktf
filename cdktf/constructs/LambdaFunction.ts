import { lambdaFunction, iamRole, iamRolePolicyAttachment } from '@cdktf/provider-aws';
import { LambdaFunctionConfig } from '@cdktf/provider-aws/lib/lambda-function';
import { Construct } from 'constructs';
import { TerraformAsset, AssetType, Fn } from 'cdktf';
import * as path from 'path';

interface LambdaFunctionProps extends Omit<LambdaFunctionConfig, 'role' | 'filename'> {
  bundle: string;
  functionName: string;
}

export class LambdaFunction extends Construct {
  public readonly lambdaFunction: lambdaFunction.LambdaFunction;

  constructor(scope: Construct, id: string, { bundle, functionName, ...rest }: LambdaFunctionProps) {
    super(scope, id);

    // Create a Terraform asset for the Lambda code
    const asset = new TerraformAsset(this, `lambda-asset`, {
      path: path.join(process.env.INIT_CWD!, bundle), // Path to the folder containing the Lambda code
      type: AssetType.ARCHIVE, // This will package the folder as a ZIP archive
    });

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

    // Use the asset for Lambda function deployment
    this.lambdaFunction = new lambdaFunction.LambdaFunction(this, 'lambda-function', {
      functionName,
      role: lambdaRole.arn,
      runtime: 'nodejs18.x',
      filename: asset.path, // Use the path of the Terraform asset
      timeout: 30,
      ...rest,
    });
  }
}
