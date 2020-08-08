# If archive file is changed, updates zip to S3 repository
resource "aws_s3_bucket" "layer_bucket_goldstock" {
  bucket = "layer-bucket-goldstock"
  acl = "private"
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_object" "object_lambda_common_layer" {
  bucket = aws_s3_bucket.layer_bucket_goldstock.bucket
  key = "lambda_common_layer.zip"
  source = data.archive_file.layer_zip_lambda_common_layer.output_path
  depends_on = [
    data.archive_file.layer_zip_lambda_common_layer]
}

data "archive_file" "layer_zip_lambda_common_layer" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda_common_layer.zip"
}

data "archive_file" "lambda-archive" {
  type        = "zip"
  source_file  = "lambda/src/main.py"
  output_path = "lambda/packages/main_function.zip"
}

resource "aws_lambda_function" "lambda-function" {
  filename         = "lambda/packages/main_function.zip"
  function_name    = "main"
  role             = aws_iam_role.lambda_execution_iam_role.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda-archive.output_base64sha256
  runtime          = "python3.8"
  timeout          = 15
  memory_size      = 128
  layers           = [aws_lambda_layer_version.lambda_common_layer.arn]
}

data "archive_file" "lambda-archive-yahoo" {
  type        = "zip"
  source_file  = "lambda/src/get_data_from_yahoo.py"
  output_path = "lambda/packages/get_data_from_yahoo.zip"
}

resource "aws_lambda_function" "lambda-function-get_data_from_yahoo" {
  filename         = "lambda/packages/get_data_from_yahoo.zip"
  function_name    = "new_get_data_from_yahoo"
  role             = aws_iam_role.lambda_execution_iam_role.arn
  handler          = "get_data_from_yahoo.lambda_handler"
  source_code_hash = data.archive_file.lambda-archive.output_base64sha256
  runtime          = "python3.8"
  timeout          = 15
  memory_size      = 128
  layers           = [aws_lambda_layer_version.lambda_common_layer.arn]
}

resource "aws_lambda_layer_version" "lambda_common_layer" {
  layer_name = "lambda_common_layer"
  s3_bucket = aws_s3_bucket_object.object_lambda_common_layer.bucket
  s3_key = aws_s3_bucket_object.object_lambda_common_layer.key
  s3_object_version = aws_s3_bucket_object.object_lambda_common_layer.version_id
  description = "Common layer providing logging"
  compatible_runtimes = ["python3.8"]
}