
variable "identifier" {
  description = "Environment short key for reference"
}

variable "s3_artifact_bucket_name" {
  description = "S3 bucket name for artifacts"
}

variable "iam_role_arn" {
  description = "IAM role ARN for Codebuild"
}

variable "codestar_connection_arn" {

}

variable "source_repository_id" {

}

variable "default_tags" {
  description = "Default tags"
}
