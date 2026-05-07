module "vpc" {
  source = "./modulos/vpc"
}

module "storage" {
  source = "./modulos/storage"
}

module "compute" {
  source          = "./modulos/compute"
  private_subnets = module.vpc.private_subnets # Conexión mágica
  lambda_sg_id    = module.vpc.lambda_sg_id    # Conexión mágica
}

module "api" {
  source                   = "./modulos/api"
  upload_lambda_invoke_arn = module.compute.upload_lambda_invoke_arn
  upload_lambda_name       = module.compute.upload_lambda_name
}