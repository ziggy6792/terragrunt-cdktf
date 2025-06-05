// main.ts
import { App } from 'cdktf';
import { DynamoStack } from './stacks/dynamo/DynamoStack';
import { ParamStoreStack } from './stacks/param-store/ParamStoreStack';
import { stages } from './utils/utils';

const app = new App();

stages.forEach((stage) => {
  const { dynamoTable } = new DynamoStack(app, `dynamo-stack-${stage}`, { stageName: stage });
  new ParamStoreStack(app, `param-store-stack-${stage}`, { stageName: stage, dynamoTable });
});

app.synth();
