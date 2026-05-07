
# VARIABLES


variable "private_subnets" { type = list(string) }
variable "lambda_sg_id"    { type = string }


# EMPAQUETADO DEL CÓDIGO (ZIPs)


data "archive_file" "upload_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/upload/index.mjs"
  output_path = "${path.module}/upload.zip"
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_file = "${path.root}/../src/crop/index.mjs"
  output_path = "${path.module}/crop.zip"
}


# ROLES Y POLÍTICAS (IAM)


data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ROL UPLOAD
resource "aws_iam_role" "upload_role" {
  name               = "upload-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "upload_s3_limited" {
  name = "s3-upload-only"
  role = aws_iam_role.upload_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "s3:PutObject"
      Effect   = "Allow"
      Resource = "arn:aws:s3:::image-processor-storage-*/uploads/*"
    }]
  })
}

# ROL CROP
resource "aws_iam_role" "crop_role" {
  name               = "crop-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "crop_policy" {
  name = "crop-permissions"
  role = aws_iam_role.crop_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::image-processor-storage-*/uploads/*"
      },
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::image-processor-storage-*/processed/*"
      },
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Permiso básico para Logs (CloudWatch)
resource "aws_iam_role_policy_attachment" "upload_logs_base" {
  role       = aws_iam_role.upload_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_logs_base" {
  role       = aws_iam_role.crop_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permisos para que las Lambdas entren a la VPC 
resource "aws_iam_role_policy_attachment" "upload_vpc_access" {
  role       = aws_iam_role.upload_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_access" {
  role       = aws_iam_role.crop_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# FUNCIONES LAMBDA

resource "aws_lambda_function" "upload" {
  function_name = "upload-lambda"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.upload_role.arn
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 30

  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      BUCKET_NAME = "image-processor-storage-${terraform.workspace}"
    }
  }
}

resource "aws_lambda_function" "crop" {
  function_name = "crop-lambda"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.crop_role.arn
  handler       = "index.handler"
  memory_size   = 512
  timeout       = 60

  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_sg_id]
  }
}

# OBSERVABILITY (Logs 14 días)

resource "aws_cloudwatch_log_group" "upload_logs" {
  name              = "/aws/lambda/upload-lambda"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "crop_logs" {
  name              = "/aws/lambda/crop-lambda"
  retention_in_days = 14
}

# OUTPUTS

output "upload_lambda_invoke_arn" { value = aws_lambda_function.upload.invoke_arn }
output "upload_lambda_name"       { value = aws_lambda_function.upload.function_name }