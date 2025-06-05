import { App } from 'cdktf';
import { DynamoStack } from './stacks/dynamo/DynamoStack';
import { ParamStoreStack } from './stacks/param-store/ParamStoreStack';

const app = new App();

new DynamoStack(app, 'dynamo-stack-dev', 'dev');
new ParamStoreStack(app, 'param-store-stack-dev', 'dev');

app.synth();
