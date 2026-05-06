
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "dummy_code" {
  type        = "zip"
  output_path = "${path.module}/dummy.zip"
  source {
    content  = "exports.handler = async (event) => { return 'Hola Mundo'; };"
    filename = "index.js"
  }
}


resource "aws_lambda_function" "upload" {
  function_name = "image-processor-upload-${terraform.workspace}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.dummy_code.output_path
  source_code_hash = data.archive_file.dummy_code.output_base64sha256

  tags = { Name = "lambda-upload-${terraform.workspace}" }
}


resource "aws_lambda_function" "crop" {
  function_name = "image-processor-crop-${terraform.workspace}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  memory_size = 512 # Requisito exacto del diagrama
  timeout     = 60  # 1 minuto de espera máxima

  filename         = data.archive_file.dummy_code.output_path
  source_code_hash = data.archive_file.dummy_code.output_base64sha256

  tags = { Name = "lambda-crop-${terraform.workspace}" }
}