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

resource "aws_iam_role_policy_attachment" "basic-exec-role" {
    role       = aws_iam_role.check_file_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy_attachment" "basic-exec-role2" {
    role       = aws_iam_role.get_data_with_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_file" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.check_file_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.check-file-event.arn
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
    function_name = "get_data_with_pandas"
    role = aws_iam_role.get_data_with_lambda.arn
    handler = "get_data_with_pandas.lambda_handler"
    runtime = "python3.8"
    timeout = 20
    source_code_hash = filebase64sha256("check_file_lambda.zip")
}

resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}

 resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   parent_id   = aws_api_gateway_rest_api.example.root_resource_id
   path_part   = "POST"
}

resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.example.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.example.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.check_file_lambda.invoke_arn
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

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.check_file_lambda.invoke_arn
 }

 resource "aws_api_gateway_deployment" "example" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.example.id
   stage_name  = "test"
 }