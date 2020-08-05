data "archive_file" "lambda-archive" {
  type        = "zip"
  source_file = "lambda/src/main.py"
  output_path = "lambda/packages/lambda_function.zip"
}

resource "aws_lambda_function" "lambda-function" {
  filename         = "lambda/packages/lambda_function.zip"
  function_name    = "layered-test"
  role             = aws_iam_role.lambda_execution_iam_role.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda-archive.output_base64sha256
  runtime          = "python3.8"
  timeout          = 15
  memory_size      = 128
  layers           = [aws_lambda_layer_version.pandas-layer.arn, 
                      aws_lambda_layer_version.numpy-layer.arn, 
                      aws_lambda_layer_version.pytz-layer.arn]
}

resource "aws_lambda_layer_version" "pandas-layer" {
  filename            = "lambda/layers/pandas/pandas_layer.zip"
  layer_name          = "pandas-layer"
  source_code_hash    = filebase64sha256("lambda/layers/pandas/pandas_layer.zip")
  compatible_runtimes = ["python3.6", "python3.7", "python3.8"]
}

resource "aws_lambda_layer_version" "numpy-layer" {
  filename            = "lambda/layers/numpy/numpy_layer.zip"
  layer_name          = "numpy-layer"
  source_code_hash    = filebase64sha256("lambda/layers/numpy/numpy_layer.zip")
  compatible_runtimes = ["python3.6", "python3.7", "python3.8"]
}

resource "aws_lambda_layer_version" "pytz-layer" {
  filename            = "lambda/layers/pytz/pytz_layer.zip"
  layer_name          = "pytz-layer"
  source_code_hash    = filebase64sha256("lambda/layers/pytz/pytz_layer.zip")
  compatible_runtimes = ["python3.6", "python3.7", "python3.8"]
}