module "vpc" {
  source = "./modulos/vpc"
}

module "storage" {
  source = "./modulos/storage"
}

module "compute" {
  source = "./modulos/compute"
}