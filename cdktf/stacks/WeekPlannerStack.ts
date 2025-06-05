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
