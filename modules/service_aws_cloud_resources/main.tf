
terraform {
  required_providers {
    aws = ">= 3.13"
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
data "aws_availability_zones" "available" {
}

locals {
  name         = var.name
  dbname       = local.name
  cluster_name = local.name
  tags         = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name                 = "k8s-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  database_subnets     = ["172.16.7.0/24", "172.16.8.0/24", "172.16.9.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true


  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  subnet_ids      = module.vpc.private_subnets
  enable_irsa     = true

  vpc_id = module.vpc.vpc_id

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    main = {
      min_size     = 3
      max_size     = 10
      desired_size = 3

      instance_types = ["t3.large"]
      labels = {
        assignment = "main"
      }
    },
    secondary = {
      min_size     = 3
      max_size     = 10
      desired_size = 3

      instance_types = ["t3.medium"]
      taints = [
        {
          key    = "assignment"
          value  = "agent"
          effect = "NO_SCHEDULE"
        }
      ]
      labels = {
        assignment = "secondary"
      }
    }
  }
  node_security_group_additional_rules = {
    ingress_all = {
      description      = "Node all ingress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.dbname

  engine               = "postgres"
  engine_version       = "14.1"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.medium"

  allocated_storage     = 20
  max_allocated_storage = 40

  db_name  = local.dbname
  username = local.dbname
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.eks.node_security_group_id]

  publicly_accessible = true
  maintenance_window  = "Mon:00:00-Mon:03:00"
  backup_window       = "03:00-06:00"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
}

module "efs" {
  source    = "cloudposse/efs/aws"
  namespace = "${local.name}efs"
  stage     = "demo"
  name      = local.name
  region    = var.region
  vpc_id    = module.vpc.vpc_id
  subnets   = module.vpc.private_subnets

  allowed_security_group_ids = [module.eks.node_security_group_id]
}

resource "random_pet" "bucket" {
  prefix = local.name
  length = 3
}

locals {
  s3_bucket_id = random_pet.bucket.id
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.s3_bucket_id
  acl    = "private"

  versioning = {
    enabled = true
  }
}

resource "aws_iam_user" "s3_access_user" {
  name = "${local.name}-s3-access-user"
  path = "/${local.name}/"
}

resource "aws_iam_access_key" "s3_access_user_key" {
  user = aws_iam_user.s3_access_user.name
}

resource "aws_iam_policy" "s3access" {
  name        = "${local.name}-custom-bucket-access"
  path        = "/"
  description = "Artifacts bucket acees for identity provider role"

  policy = <<EOT
{
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "${module.s3_bucket.s3_bucket_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${module.s3_bucket.s3_bucket_arn}/*"
            ]
        }
    ],
    "Version": "2012-10-17"
}
EOT
}

resource "aws_iam_role" "s3_access_role" {
  name = "${local.name}-custom-bucket-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          "Federated" = module.eks.oidc_provider_arn
        },
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:${local.name}:${local.name}"
          }
        }
      },
    ]
  })
  depends_on = [
    module.eks
  ]
}

resource "aws_iam_policy_attachment" "s3_access_role_policy" {
  name       = "s3_access_role_policy"
  roles      = [aws_iam_role.s3_access_role.name]
  users      = [aws_iam_user.s3_access_user.name]
  policy_arn = aws_iam_policy.s3access.arn
}