resource "aws_api_gateway_rest_api" "restApi" {
  name        = "${local.serviceName}"
  description = "${local.DefaultDesc}"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.restApi.id}"
  parent_id   = "${aws_api_gateway_rest_api.restApi.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.restApi.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.restApi.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambdaFunction.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.restApi.id}"
  resource_id   = "${aws_api_gateway_rest_api.restApi.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.restApi.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambdaFunction.invoke_arn}"
}

resource "aws_api_gateway_deployment" "test" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.restApi.id}"
  stage_name  = "test"
}
resource "aws_api_gateway_usage_plan" "apiGatewayUsagePlan" {
  name         = "${local.serviceName}-UsagePlan"
  description  = "${local.DefaultDesc}"
  product_code = "MYCODE"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.restApi.id}"
    stage  = "${aws_api_gateway_deployment.test.stage_name}"
  }
  throttle_settings {
    burst_limit = 5
    rate_limit  = 5
  }
}

output "base_url" {
  value = "${aws_api_gateway_deployment.test.invoke_url}"
}
