variable "identifier" {
  description = "Environment identifier"
}
variable "name" {
  description = "IAM Role name"
}
variable "description" {
  description = "IAM role description"
}

variable "policy" {
  description = "IAM role policy"
}

variable "assume_role_policy" {
  description = "IAM assume role policy"
}
variable "is_instance_profile" {
  default = 0
}
variable "default_tags" {
  description = "Default tags"
}
