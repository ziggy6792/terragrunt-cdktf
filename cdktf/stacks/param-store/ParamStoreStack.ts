import { Construct } from 'constructs';
import { AwsBaseStack, AwsBaseStackProps } from '../AwsBaseStack';
import { AwsSsmParameter } from '../../.gen/modules/aws-ssm-parameter';
import { AwsDynamodbTable } from '../../.gen/modules/aws-dynamodb-table';

interface ParamStoreStackProps extends AwsBaseStackProps {
  dynamoTable: AwsDynamodbTable;
}

export class ParamStoreStack extends AwsBaseStack {
  constructor(scope: Construct, id: string, props: ParamStoreStackProps) {
    super(scope, id, props);

    // const dynamoStack = this.context.getStack(DynamoStack);

    const paramStore = new AwsSsmParameter(this, 'param-store', {
      name: `/my-app-2/${props.stageName}/dynamo-table-id`,
      value: props.dynamoTable.dynamodbTableIdOutput,
      type: 'String',
    });
  }
}
