provider "aws" {
    region = var.aws_region
}

resource "aws_cloudwatch_event_rule" "check-file-event" {
    name = "check-file-event"
    description = "check-file-event"
    schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "check-file-event-lambda-target" {
    target_id = "check-file-event-lambda-target"
    rule = aws_cloudwatch_event_rule.check-file-event.name
    arn = aws_lambda_function.check_file_lambda.arn
    input = <<EOF
{
  "bucket": "my_bucket",
  "file_path": "path/to/file"
}
EOF
}

resource "aws_cloudwatch_event_rule" "update-gold-event" {
    name = "update-gold-event"
    description = "update-gold-event"
    schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "update-gold-event-lambda-target" {
    target_id = "update-gold-event-lambda-target"
    rule = aws_cloudwatch_event_rule.update-gold-event.name
    arn = aws_lambda_function.get_data_with_lambda.arn
    input = <<EOF
{
  "bucket": "goldstat-stocks",
  "file_path": "USD"
}
EOF
}

resource "aws_cloudwatch_event_rule" "update-fiats-event" {
    name = "update-fiats-event"
    description = "update-fiats-event"
    schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "update-fiats-event-lambda-target" {
    target_id = "update-fiats-event-lambda-target"
    rule = aws_cloudwatch_event_rule.update-fiats-event.name
    arn = aws_lambda_function.update_fiat_data_from_source.arn
    input = <<EOF
{
  "stock":"GBPUSD=X",
  "bucket": "goldstat-stocks",
  "file_path": "GBP"}
EOF
}

resource "aws_cloudwatch_event_target" "update-fiats-event-lambda-target-EUR" {
    target_id = "update-fiats-event-lambda-target-EUR"
    rule = aws_cloudwatch_event_rule.update-fiats-event.name
    arn = aws_lambda_function.update_fiat_data_from_source.arn
    input = <<EOF
{
  "stock":"EURUSD=X",
  "bucket": "goldstat-stocks",
  "file_path": "EUR"}
EOF
}

resource "aws_iam_role" "check_file_lambda" {
    name = "check_file_lambda"
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

resource "aws_iam_role" "lambda_execution_iam_role" {
    name = "lambda_execution_iam_role"
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
resource "aws_iam_role" "get_data_with_lambda" {
    name = "get_data_with_lambda"
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
data "aws_iam_policy_document" "s3-access-ro" {
    statement {
        actions = [
            "s3:GetObject",
            "s3:ListBucket",
        ]
        resources = [
            "arn:aws:s3:::*",
        ]
    }
}

resource "aws_iam_policy" "s3-access-ro" {
    name = "s3-access-ro"
    path = "/"
    policy = data.aws_iam_policy_document.s3-access-ro.json
}

resource "aws_iam_role_policy_attachment" "s3-access-ro" {
    role       = aws_iam_role.check_file_lambda.name
    policy_arn = aws_iam_policy.s3-access-ro.arn
}

resource "aws_iam_role_policy_attachment" "s3-historic-access" {
    role       = aws_iam_role.lambda_execution_iam_role.name
    policy_arn = aws_iam_policy.s3-access-ro.arn
}

resource "aws_iam_role_policy_attachment" "basic-exec-role" {
    role       = aws_iam_role.check_file_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy_attachment" "basic-exec-role2" {
    role       = aws_iam_role.lambda_execution_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "basic-exec-role3" {
    role       = aws_iam_role.lambda_execution_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_file" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.check_file_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.check-file-event.arn
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_get_data_with_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.get_data_with_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.update-gold-event.arn
}

resource "aws_lambda_function" "check_file_lambda" {
    filename = "check_file_lambda.zip"
    function_name = "check_file_lambda"
    role = aws_iam_role.check_file_lambda.arn
    handler = "check_file_lambda.handler"
    runtime = "python3.8"
    timeout = 10
    source_code_hash = filebase64sha256("check_file_lambda.zip")
}

resource "aws_lambda_function" "get_data_with_lambda" {
    filename = "check_file_lambda.zip"
    function_name = "historical_stock_data"
    role = aws_iam_role.lambda_execution_iam_role.arn
    handler = "historical_stock_data.lambda_handler"
    runtime = "python3.8"
    timeout = 20
    source_code_hash = filebase64sha256("check_file_lambda.zip")
}

resource "aws_lambda_function" "update_fiat_data_from_source" {
    filename = "check_file_lambda.zip"
    function_name = "update_fiat_data_from_source"
    role = aws_iam_role.lambda_execution_iam_role.arn
    handler = "update_fiat_data_from_source.lambda_handler"
    runtime = "python3.8"
    timeout = 20
    source_code_hash = filebase64sha256("check_file_lambda.zip")
}

resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}


resource "aws_api_gateway_resource" "stock" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   parent_id   = aws_api_gateway_rest_api.example.root_resource_id
   path_part   = "{stock}"
}
resource "aws_api_gateway_resource" "startdate" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   parent_id   = aws_api_gateway_resource.stock.id
   path_part   = "{startdate}"
}
resource "aws_api_gateway_resource" "enddate" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   parent_id   = aws_api_gateway_resource.startdate.id
   path_part   = "{enddate}"
}
resource "aws_api_gateway_method" "fiatget" {
   rest_api_id   = aws_api_gateway_rest_api.example.id
   resource_id   = aws_api_gateway_resource.enddate.id
   http_method   = "GET"
   authorization = "NONE"
   request_parameters= { "method.request.path.enddate"= true
     "method.request.path.startdate"= true
     "method.request.path.stock"= true
   }
 }

 resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   resource_id = aws_api_gateway_method.fiatget.resource_id
   http_method = aws_api_gateway_method.fiatget.http_method

   integration_http_method = "POST"
   type = "AWS"
   uri = aws_lambda_function.get_data_with_lambda.invoke_arn
   request_templates = {

     "application/json" =<<EOF
{   "stock": "$input.params('stock')",
    "startdate": "$input.params('startdate')",
    "enddate": "$input.params('enddate')"
}
EOF
   }
 }

 resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.example.id
   resource_id   = aws_api_gateway_rest_api.example.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "GET"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.get_data_with_lambda.invoke_arn
 }

 resource "aws_api_gateway_deployment" "example" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.example.id
   stage_name  = "test"
 }

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.get_data_with_lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
 }

output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}