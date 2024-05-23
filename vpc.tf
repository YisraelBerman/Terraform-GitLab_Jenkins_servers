module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.gitlab_project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = [var.public_subnet_cidr]
  private_subnets = [var.private_subnet_cidr]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "${var.gitlab_project_name}-public-subnet"
  }

  private_subnet_tags = {
    Name = "${var.gitlab_project_name}-private-subnet"
  }

  tags = {
    Name = "${var.gitlab_project_name}-vpc"
  }
}

