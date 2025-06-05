import { App } from 'cdktf';
import { NamePickerStack } from './stacks/NamePickerStack';
import { WeekPlannerStack } from './stacks/WeekPlannerStack';
import { PROJECT_NAME } from './config';

const app = new App();

new NamePickerStack(app, PROJECT_NAME);
new NamePickerStack(app, PROJECT_NAME + '-prod', 'prod');

app.synth();
