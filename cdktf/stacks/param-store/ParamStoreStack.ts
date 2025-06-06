import { Construct } from 'constructs';
import { AwsDynamodbTable } from '../../.gen/modules/aws-dynamodb-table';
import { AwsSsmParameter } from '../../.gen/modules/aws-ssm-parameter';
import { AwsBaseStack, AwsBaseStackProps } from '../AwsBaseStack';

interface ParamStoreStackProps extends AwsBaseStackProps {
  dynamoTable: AwsDynamodbTable;
}

export class ParamStoreStack extends AwsBaseStack {
  constructor(scope: Construct, id: string, props: ParamStoreStackProps) {
    super(scope, id, props);

    // const dynamoStack = this.context.getStack(DynamoStack);

    new AwsSsmParameter(this, 'param-store', {
      name: `/my-app-2/${props.env}/dynamo-table-id`,
      value: props.dynamoTable.dynamodbTableIdOutput,
      type: 'String',
    });
  }
}
