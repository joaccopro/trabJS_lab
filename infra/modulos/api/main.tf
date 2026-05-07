# infra/modulos/api/main.tf

variable "upload_lambda_invoke_arn" {}
variable "upload_lambda_name" {}

# 1. Definición del API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "main" {
  name          = "image-processor-api-${terraform.workspace}"
  protocol_type = "HTTP"
}

# 2. Stage por defecto
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# 3. Integración con la Lambda de Upload
resource "aws_apigatewayv2_integration" "upload" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.upload_lambda_invoke_arn
}

# 4. Ruta del Endpoint (POST /upload)
resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

# 5. Permiso para que el API Gateway pueda ejecutar la Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# URL final para probar el api
output "api_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}