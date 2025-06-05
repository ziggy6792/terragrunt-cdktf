import { Construct } from 'constructs';
import { AwsBaseStack, AwsBaseStackProps } from '../AwsBaseStack';
import { AwsDynamodbTable } from '../../.gen/modules/aws-dynamodb-table';

export class DynamoStack extends AwsBaseStack {
  public readonly dynamoTable: AwsDynamodbTable;

  constructor(scope: Construct, id: string, props: AwsBaseStackProps) {
    super(scope, id, props);

    this.dynamoTable = new AwsDynamodbTable(this, 'dynamo-table', {
      name: `${props.stageName}-my-dynamodb-table-2`,
      hashKey: 'id',
      billingMode: 'PAY_PER_REQUEST',
      attributes: [{ name: 'id', type: 'S' }],
    });
  }
}
