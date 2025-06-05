import { App } from 'cdktf';
import { PreReqStack } from './stacks/PreReqStack';
import { BACKEND_NAME, PROJECT_NAME } from './config';
import { stages } from './utils/utils';

const app = new App();

stages.forEach((stage) => {
  new PreReqStack(app, `${BACKEND_NAME}-${stage}`, { backendName: `${PROJECT_NAME}-${stage}` });
});

app.synth();
