
variable "identifier" {
  description = "Environment short key for reference"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "List of subnets"
}

variable "security_group_ids" {
  description = "Security group IDs"
}

variable "account_number" {
  description = "AWS account number"
}

variable "s3_artifact_bucket_arn" {
  description = "S3 bucket ARN for artifacts"
}

variable "env_vars_plain" {
  description = "Plain text Environment variables"
}
variable "env_vars_parameter_store" {
  description = "Parameter store Environment variables"
}

variable "iam_role_arn" {
  description = "IAM role ARN for Codebuild"
}

variable "default_tags" {
  description = "Default tags"
}

variable "compute_type" {
  description = "Size of the compute instance"
  default     = "BUILD_GENERAL1_MEDIUM"
}
