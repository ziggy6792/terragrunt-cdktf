import { App } from 'cdktf';
import { DynamoStack } from './stacks/dynamo/DynamoStack';
import { ParamStoreStack } from './stacks/param-store/ParamStoreStack';
import { stages } from './utils/utils';

const app = new App();

stages.forEach((stage) => {
  new DynamoStack(app, `dynamo-stack-${stage}`, stage);
  new ParamStoreStack(app, `param-store-stack-${stage}`, stage);
});

app.synth();
