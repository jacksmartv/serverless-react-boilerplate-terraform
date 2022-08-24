
variable "identifier" {
  description = "Environment identifier"
}
variable "bucket_name" {}

variable "s3_log_bucket_name" {}

variable "enable_encryption" {
  default = false
}

variable "enable_logging" {
  default = false
}

variable "account_number" {}

variable "region" {}

variable "default_tags" {}
