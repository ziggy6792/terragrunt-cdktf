import { TerraformStack } from 'cdktf';
import { Construct } from 'constructs';

export const getConstructName = (scope: Construct, id: string) => `${TerraformStack.of(scope)}-${id}`.toLowerCase();

export type Env = 'dev' | 'prod';

export const envs: Env[] = ['dev', 'prod'];
