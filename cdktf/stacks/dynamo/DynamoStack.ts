import { Construct } from 'constructs';
import { TerraformOutput } from 'cdktf';
import { AwsBaseStack } from '../AwsBaseStack';
import { AwsDynamodbTable } from '../../.gen/modules/aws-dynamodb-table';

export class DynamoStack extends AwsBaseStack {
  constructor(scope: Construct, id: string, stageName: 'dev' | 'prod' = 'dev') {
    super(scope, id, stageName);

    const dynamoTable = new AwsDynamodbTable(this, 'dynamo-table', {
      name: `${stageName}-my-dynamodb-table-2`,
      hashKey: 'id',
      billingMode: 'PAY_PER_REQUEST',
      attributes: [{ name: 'id', type: 'S' }],
    });
  }
}
