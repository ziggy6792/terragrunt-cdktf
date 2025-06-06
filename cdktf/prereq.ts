import { App } from 'cdktf';
import { PreReqStack } from './stacks/PreReqStack';
import { BACKEND_NAME, PROJECT_NAME } from './config';
import { envs } from './utils/utils';

const app = new App();

envs.forEach((env) => {
  new PreReqStack(app, `${BACKEND_NAME}-${env}`, { backendName: `${PROJECT_NAME}-${env}` });
});

app.synth();
