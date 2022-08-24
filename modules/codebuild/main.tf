locals {
  subnets = join(",", "${var.subnet_ids}")
}

resource "aws_codebuild_project" "codebuild" {
  name          = "${var.identifier}-codebuild"
  description   = "${var.identifier} Codebuild project"
  build_timeout = "60"
  service_role  = var.iam_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = var.compute_type
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = var.env_vars_plain

      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    dynamic "environment_variable" {
      for_each = var.env_vars_parameter_store

      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "${var.identifier}-codebuild"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = merge({ "Name" = "codebuild" }, var.default_tags)
}
