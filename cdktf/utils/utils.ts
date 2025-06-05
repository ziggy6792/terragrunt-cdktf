import { TerraformStack } from 'cdktf';
import { Construct } from 'constructs';

export const getConstructName = (scope: Construct, id: string) => `${TerraformStack.of(scope)}-${id}`.toLowerCase();

export type Stage = 'dev' | 'prod';

export const stages: Stage[] = ['dev'];

export const prereqStackNames = stages.reduce((acc, stage) => {
  acc[stage] = `cdktf-prereq-${stage}`;
  return acc;
}, {} as Record<Stage, string>);
