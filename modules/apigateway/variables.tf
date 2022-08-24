
variable "identifier" {
  description = "Environment short key for reference"
}
variable "name" {
  description = "API Gateway name"
}
variable "endpoint_type" {
  description = "API Gateway endpoint type"
}

variable "stage" {
  description = "API Gateway deployment stage name"
}

variable "cloudwatch_role_arn" {}

variable "default_tags" {
  description = "Default tags"
}
