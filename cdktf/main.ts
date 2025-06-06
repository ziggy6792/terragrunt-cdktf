// main.ts
import { App } from 'cdktf';
import { DynamoStack } from './stacks/dynamo/DynamoStack';
import { ParamStoreStack } from './stacks/param-store/ParamStoreStack';
import { envs } from './utils/utils';

const app = new App();

envs.forEach((env) => {
  const { dynamoTable } = new DynamoStack(app, `dynamo-stack-${env}`, { env });
  new ParamStoreStack(app, `param-store-stack-${env}`, { env, dynamoTable });
});

app.synth();
