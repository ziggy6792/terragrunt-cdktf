import { Construct } from 'constructs';
import { TerraformOutput } from 'cdktf';
import { LambdaFunction } from '../constructs/LambdaFunction';
import { LambdaRestApi } from '../constructs/LambdaRestApi';
import { getConstructName } from '../utils/utils';
import { AwsBaseStack } from './AwsBaseStack';

export class NamePickerStack extends AwsBaseStack {
  constructor(scope: Construct, id: string, stageName: 'dev' | 'prod' = 'dev') {
    super(scope, id);

    for (const type of ['roulette', 'shuffle'] as const) {
      // Adding 'as const' gives us type safety
      const functionNamePicker = new LambdaFunction(this, `lambda-function-${type}`, {
        bundle: './function-name-picker', // Path to the folder containing the Lambda code
        functionName: getConstructName(this, `api-${type}`),
        handler: 'index.handler',
        environment: {
          variables: {
            SHUFFLE: type === 'shuffle' ? 'true' : 'false',
          },
        },
      });

      const lambdaRestApi = new LambdaRestApi(this, `lambda-rest-api-${type}`, {
        handler: functionNamePicker.lambdaFunction,
        stageName: stageName,
      });

      new TerraformOutput(this, `namePickerApiUrl-${type}`, {
        value: lambdaRestApi.url,
      });
    }
  }
}
