# RED BASE (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Requisito del diagrama
  enable_dns_support   = true # Requisito del diagrama

  tags = { Name = "main-vpc" }
}

# SUBREDES PRIVADAS (Multi-AZ para Alta Disponibilidad)

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "private-subnet-az-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "private-subnet-az-b" }
}


# SECURITY GROUPS (Seguridad de Red)


# SG para las Lambdas
resource "aws_security_group" "lambda_sg" {
  name = "lambda-sg"
  description = "Security group para lambdas en red privada"
  vpc_id      = aws_vpc.main.id

  # Salida total (necesaria para hablar con los Endpoints)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-lambda" }
}

# SG para el Endpoint de SQS (Solo permite tráfico de las lambdas)
resource "aws_security_group" "vpce_sqs_sg" {
  name = "vpce-sqs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  tags = { Name = "sg-vpce-sqs" }
}

# VPC ENDPOINTS (Conexión privada a AWS)


# S3 Gateway Endpoint (Gratuito y seguro)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  # Se inyecta automáticamente en las tablas de rutas
  route_table_ids = [aws_vpc.main.default_route_table_id]

  tags = { Name = "vpce-s3" }
}

# SQS Interface Endpoint (Multi-AZ)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpce_sqs_sg.id]

  tags = { Name = "vpce-sqs" }
}