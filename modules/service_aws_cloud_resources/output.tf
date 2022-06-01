output "eks_cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster id"
}
output "eks_cluster_endpoint" {
  value       = data.aws_eks_cluster.cluster.endpoint
  description = "EKS cluster endpoint"
}

output "eks_cluster_token" {
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
  description = "EKS cluster token"
}

output "eks_certificate_authority" {
  value       = data.aws_eks_cluster.cluster.certificate_authority.0.data
  description = "EKS cluster certificate authority"
}

output "eks_cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "EKS oidc provider url"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS oidc provider arn"
}

output "efs_id" {
  value       = module.efs.id
  description = "EFS storage id"
}

output "s3_access_user_key_id" {
  value       = aws_iam_access_key.s3_access_user_key.id
  description = "S3 acces user key id"
}

output "s3_access_user_key_secret" {
  value       = aws_iam_access_key.s3_access_user_key.secret
  description = "S3 acces user key id"
}

output "s3_access_role_arn" {
  value       = aws_iam_role.s3_access_role.arn
  description = "S3 storage acces role"
}

output "s3_bucket_id" {
  value       = local.s3_bucket_id
  description = "S3 bucket id"
}

output "db_instance_endpoint" {
  value       = module.db.db_instance_endpoint
  description = "RDS instance endpoint"
}

output "db_instance_password" {
  value       = module.db.db_instance_password
  description = "RDS instance password"
}