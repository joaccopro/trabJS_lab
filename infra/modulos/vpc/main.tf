# 1. VPC Principal (10.0.0.0/16)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "image-processor-vpc-${terraform.workspace}" }
}

# 2. Subredes Públicas (10.0.1.0/24 y 10.0.2.0/24)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags                    = { Name = "public-a-${terraform.workspace}" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags                    = { Name = "public-b-${terraform.workspace}" }
}

# 3. Subredes Privadas (10.0.11.0/24 y 10.0.12.0/24)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "private-a-${terraform.workspace}" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "private-b-${terraform.workspace}" }
}