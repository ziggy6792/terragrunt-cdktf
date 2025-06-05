import { Construct } from 'constructs';
import {
  lambdaFunction,
  apiGatewayRestApi,
  apiGatewayDeployment,
  apiGatewayResource,
  apiGatewayMethod,
  apiGatewayIntegration,
  lambdaPermission,
} from '@cdktf/provider-aws';
import { getConstructName } from '../utils/utils';

interface LambdaRestApiProps {
  handler: lambdaFunction.LambdaFunction;
  stageName: string;
}

export class LambdaRestApi extends Construct {
  public readonly url: string;

  constructor(scope: Construct, id: string, { handler, stageName }: LambdaRestApiProps) {
    super(scope, id);

    const restApi = new apiGatewayRestApi.ApiGatewayRestApi(this, 'rest-api', {
      name: getConstructName(this, 'rest-api'),
    });

    this.createApiGatewayLambdaMethod('root', restApi, restApi.rootResourceId, handler);

    const proxyResource = new apiGatewayResource.ApiGatewayResource(this, 'proxy-resource', {
      restApiId: restApi.id,
      parentId: restApi.rootResourceId,
      pathPart: '{proxy+}',
    });

    this.createApiGatewayLambdaMethod('proxy-resource', restApi, proxyResource.id, handler);

    // Add Lambda permission to allow API Gateway to invoke the Lambda function
    new lambdaPermission.LambdaPermission(this, 'api-gateway-permission', {
      action: 'lambda:InvokeFunction',
      functionName: handler.functionName,
      principal: 'apigateway.amazonaws.com',
      sourceArn: `${restApi.executionArn}/*/*`,
    });

    const deployment = new apiGatewayDeployment.ApiGatewayDeployment(this, 'deployment', {
      restApiId: restApi.id,
      stageName,
      dependsOn: [proxyResource, handler],
    });

    this.url = deployment.invokeUrl;
  }

  private createApiGatewayLambdaMethod(
    idPrefix: string,
    restApi: apiGatewayRestApi.ApiGatewayRestApi,
    resourceId: string,
    apiLambda: lambdaFunction.LambdaFunction
  ) {
    new apiGatewayMethod.ApiGatewayMethod(this, `${idPrefix}-method`, {
      restApiId: restApi.id,
      resourceId,
      httpMethod: 'ANY',
      authorization: 'NONE',
    });

    new apiGatewayIntegration.ApiGatewayIntegration(this, `${idPrefix}-lambda-integration`, {
      restApiId: restApi.id,
      resourceId,
      httpMethod: 'ANY',
      integrationHttpMethod: 'POST',
      type: 'AWS_PROXY',
      uri: apiLambda.invokeArn,
    });
  }
}
