import { Construct } from 'constructs';
import { TerraformOutput } from 'cdktf';
import { AwsBaseStack } from '../AwsBaseStack';
import { AwsSsmParameter } from '../../.gen/modules/aws-ssm-parameter';

export class ParamStoreStack extends AwsBaseStack {
  constructor(scope: Construct, id: string, stageName: 'dev' | 'prod' = 'dev') {
    super(scope, id);

    const paramStore = new AwsSsmParameter(this, 'param-store', {
      name: `/my-app-2/${stageName}/dynamo-table-id`,
      value: '123',
      type: 'String',
    });
  }
}
