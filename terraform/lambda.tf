resource "aws_lambda_function" "lambdaFunction" {
  function_name = "${local.serviceName}"
  description = "${local.DefaultDesc}"
	filename         = "../lambda-code/example.zip"
  source_code_hash = "${base64sha256(file("../lambda-code/example.zip"))}"
  handler = "main.handler"
  runtime = "nodejs10.x"
  role = "${aws_iam_role.lambda_exec.arn}"
  depends_on    = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.lambdaLogGroup"]
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "${local.serviceName}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambdaFunction.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_deployment.test.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allowCloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambdaFunction.arn}"
  principal     = "logs.us-west-2.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "lambdaLogGroup" {
  name              = "/aws/lambda/${local.serviceName}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambdaLoggingPolicy" {
  name = "lambdaLoggingPolicy"
  path = "/"
  description = "${local.DefaultDesc}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambdaLoggingPolicy.arn}"
}
