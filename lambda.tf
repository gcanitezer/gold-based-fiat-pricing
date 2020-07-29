data "archive_file" "lambda-archive" {
  type        = "zip"
  source_file = "lambda/src/main.py"
  output_path = "lambda/packages/lambda_function.zip"
}

resource "aws_lambda_function" "lambda-function" {
  filename         = "lambda/packages/lambda_function.zip"
  function_name    = "layered-test"
  role             = aws_iam_role.lambda_execution_iam_role.arn
  handler          = "main.handle"
  source_code_hash = data.archive_file.lambda-archive.output_base64sha256
  runtime          = "python3.8"
  timeout          = 15
  memory_size      = 128
  layers           = [aws_lambda_layer_version.python38-pandas-layer.arn]
}

resource "aws_lambda_layer_version" "python38-pandas-layer" {
  filename            = "lambda/packages/Python3-pandas.zip"
  layer_name          = "Python3-pandas"
  source_code_hash    = filebase64sha256("lambda/packages/Python3-pandas.zip")
  compatible_runtimes = ["python3.7", "python3.8"]
}