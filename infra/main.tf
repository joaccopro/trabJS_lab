module "vpc" {
  source = "./modulos/vpc"
}

module "storage" {
  source = "./modulos/storage"
}

module "compute" {
  source = "./modulos/compute"
}

module "api" {
  source                   = "./modulos/api"
  upload_lambda_invoke_arn = module.compute.upload_lambda_invoke_arn
  upload_lambda_name       = module.compute.upload_lambda_name
}