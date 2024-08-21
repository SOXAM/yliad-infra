provider "aws" {
  region = var.region
  profile = var.profile
}

data "aws_availability_zones" "available" {}

locals {
  name   = "yliad-rds"
  region = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Repository = "https://github.com/SOXAM/yliad-infra/terraform/rds"
  }
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}"

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.micro"

  allocated_storage = 20

  publicly_accessible = true

  db_name  = "yliad"
  username = "admin"
  password = "yliad-rds"
  port     = 3306

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]
  skip_final_snapshot    = true

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = ["ap-northeast-2a", "ap-northeast-2c"] #가용영역 지정
  public_subnets  = ["10.0.10.0/24", "10.0.20.0/24"]  #공개 서브넷
  private_subnets = ["10.0.11.0/24", "10.0.21.0/24"] #비공개 서브넷
  database_subnets = ["10.0.12.0/24", "10.0.22.0/24"] #데이터베이스 서브넷
 
  enable_nat_gateway = true			#NAT Gateway 활성
  single_nat_gateway = true         #단일 NAT Gateway 설정
  one_nat_gateway_per_az = false    #단일 NAT 설정 시 false로 비활성화
  
  
  create_database_subnet_group = true    #RDS용 서브넷 구성
  create_database_subnet_route_table = true    #RDS용 서브넷의 라우팅 테이블 구성
  create_database_internet_gateway_route = true    #RDS용 라우팅 테이블에 인터넷 게이트웨이 연결 설정 여부

  enable_dns_hostnames = "true"  #DNS Hostname Enable
  enable_dns_support = "true"   #DNS Support Enable

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Complete MySQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}
