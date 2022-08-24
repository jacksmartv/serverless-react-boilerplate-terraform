
provider "aws" {
  region = var.region
}

locals {
  default_tags = {
    "Source"      = "Terraform"
    "Environment" = var.identifier
  }
  s3_bucket_name                     = "${var.identifier}-sls-test"
  s3_log_bucket_name                 = "${var.identifier}-sls-test-logs"
  iam_codepipeline_role_name         = "${var.identifier}-codepipeline-role"
  iam_codebuild_role_name            = "${var.identifier}-codebuild-role"
  iam_cloudformation_stack_role_name = "${var.identifier}-cfn-role"
  codebuild_project_name             = "${var.identifier}-codebuild"
  codepipeline_name                  = "${var.identifier}-codepipeline"
  apigateway_name                    = "${var.identifier}-apigw"
  cloudformation_stack_name          = "${var.identifier}-cf-stack"
}

module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = var.vpc_cidr
  region       = var.region
  identifier   = var.identifier
  default_tags = local.default_tags
}

module "s3" {
  source             = "./modules/s3"
  bucket_name        = local.s3_bucket_name
  enable_encryption  = false
  enable_logging     = false
  s3_log_bucket_name = local.s3_log_bucket_name
  account_number     = var.account_number
  identifier         = var.identifier
  region             = var.region
  default_tags       = local.default_tags
}

module "iam_lambdaexec_role" {
  source             = "./modules/iam"
  name               = "${var.identifier}-lambdaexec-role"
  default_tags       = local.default_tags
  description        = ""
  assume_role_policy = <<-DOC
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  DOC
  identifier         = var.identifier
  policy             = <<-DOC
  {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Terraform0",
                "Effect": "Allow",
                "Action": [
                    "s3:*"
                ],
                "Resource": [
                    "arn:aws:s3:::${local.s3_bucket_name}",
                    "arn:aws:s3:::${local.s3_bucket_name}/*"
                ]
            },
            {
                "Sid": "Terraform1",
                "Effect": "Allow",
                "Action": [
                    "lambda:InvokeFunction",
                    "lambda:GetFunctionEventInvokeConfig",
                    "lambda:InvokeAsync"
                ],
                "Resource": [
                    "arn:aws:lambda:${var.region}:${var.account_number}:function:*"
                ]
            },
            {
                "Sid": "Terraform2",
                "Effect": "Allow",
                "Action": [
                    "logs:PutLogEvents",
                    "logs:CreateLogStream"
                ],
                "Resource": [
                  "arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/lambda/serverlessapp-${var.identifier}*:*",
                  "arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/lambda/serverlessapp-${var.identifier}*:*:*",
                  "arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/lambda/${var.identifier}*:*:*"
                ]
            },
            {
                "Sid": "Terraform3",
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateNetworkInterface",
                    "xray:PutTelemetryRecords",
                    "ec2:DescribeNetworkInterfaces",
                    "ec2:DeleteNetworkInterface",
                    "xray:PutTraceSegments",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ],
                "Resource": "*"
            }
        ]
    }
  DOC
}

module "iam_cloudformation_stack_role" {
  source             = "./modules/iam"
  name               = local.iam_cloudformation_stack_role_name
  default_tags       = local.default_tags
  description        = ""
  assume_role_policy = <<-DOC
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "cloudformation.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        },
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "${module.iam_codebuild_role.arn}"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  DOC
  identifier         = var.identifier
  policy             = <<-DOC
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Terraform0",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CancelUpdateStack",
                "apigateway:*",
                "cloudformation:DescribeStackInstance",
                "cloudformation:UpdateStackSet",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeStacks",
                "s3:GetObject",
                "iam:PassRole",
                "cloudformation:GetStackPolicy",
                "cloudformation:DescribeStackSet",
                "cloudformation:ListStackSets",
                "cloudformation:GetTemplate",
                "cloudformation:DeleteStack",
                "cloudformation:UpdateStack",
                "cloudformation:StopStackSetOperation",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:ListChangeSets"
            ],
            "Resource": [
                "arn:aws:s3:::${local.s3_bucket_name}",
                "arn:aws:s3:::${local.s3_bucket_name}/*",
                "${module.iam_lambdaexec_role.arn}",
                "arn:aws:apigateway:${var.region}::/restapis/${module.apigateway.id}/*",
                "arn:aws:cloudformation:${var.region}:${var.account_number}:stack/serverlessapp-${var.identifier}*/*",
                "arn:aws:cloudformation:${var.region}:${var.account_number}:stackset/*/*",
                "arn:aws:iam::${var.account_number}:role/aws-service-role/lambda.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_LambdaConcurrency"
            ]
        },
        {
            "Sid": "Terraform2",
            "Effect": "Allow",
            "Action": [
                "lambda:*",
                "logs:DescribeLogGroups",
                "logs:DeleteLogGroup",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:PutSubscriptionFilter",
                "logs:DeleteSubscriptionFilter",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs",
                "logs:DeleteLogGroup",
                "logs:DeleteLogStream",
                "logs:PutRetentionPolicy",
                "ec2:DescribeNetworkInterfaces",
                "events:*",
                "application-autoscaling:RegisterScalableTarget",
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:DeregisterScalableTarget",
                "application-autoscaling:PutScalingPolicy",
                "application-autoscaling:DescribeScalingPolicies",
                "application-autoscaling:DescribeScalingActivities",
                "application-autoscaling:DeleteScalingPolicy",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/lambda.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_LambdaConcurrency",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName":"lambda.application-autoscaling.amazonaws.com"
                }
            }
        }
    ]
    }
  DOC
}

module "iam_apigw_cw_role" {
  source             = "./modules/iam"
  name               = "${var.identifier}-apigatewayCW-role"
  default_tags       = local.default_tags
  description        = ""
  assume_role_policy = <<-DOC
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  DOC
  identifier         = var.identifier
  policy             = <<-DOC
  {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Terraform2",
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams",
                    "logs:PutLogEvents",
                    "logs:GetLogEvents",
                    "logs:FilterLogEvents"
                ],
                "Resource": "*"
            }
        ]
    }
  DOC
}

module "apigateway" {
  source              = "./modules/apigateway"
  endpoint_type       = "REGIONAL"
  identifier          = var.identifier
  name                = local.apigateway_name
  stage               = var.stage
  cloudwatch_role_arn = module.iam_apigw_cw_role.arn
  default_tags        = local.default_tags
}

locals {
  subnets = join("\",\"", formatlist("arn:aws:ec2:${var.region}:${var.account_number}:subnet/%s", module.networking.private_subnet_ids))
}

module "iam_codebuild_role" {
  source             = "./modules/iam"
  name               = local.iam_codebuild_role_name
  default_tags       = local.default_tags
  description        = ""
  assume_role_policy = <<-DOC
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "codebuild.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  DOC
  identifier         = var.identifier
  policy             = <<-DOC
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterfacePermission"
          ],
          "Resource": [
            "arn:aws:ec2:${var.region}:${var.account_number}:network-interface/*"
          ],
          "Condition": {
            "StringEquals": {
              "ec2:Subnet": ["${local.subnets}"],
              "ec2:AuthorizedService": "codebuild.amazonaws.com"
            }
          }
        },
        {
          "Effect": "Allow",
          "Action": [
            "iam:PassRole",
            "cloudformation:UpdateStack",
            "cloudformation:DescribeStackSet",
            "cloudformation:DescribeChangeSet",
            "cloudformation:DeleteStack",
            "cloudformation:DeleteChangeSet",
            "cloudformation:UpdateStackSet",
            "cloudformation:TagResource",
            "cloudformation:UntagResource",
            "cloudformation:DescribeStackEvents",
            "cloudformation:DescribeStackInstance",
            "cloudformation:DescribeStackResourceDrifts",
            "cloudformation:DescribeStackResource",
            "cloudformation:DescribeStackResources",
            "cloudformation:ListStackResources",
            "cloudformation:CreateChangeSet",
            "cloudformation:ExecuteChangeSet",
            "logs:PutRetentionPolicy"
          ],
          "Resource": [
              "arn:aws:iam::${var.account_number}:role/${local.iam_cloudformation_stack_role_name}",
              "arn:aws:cloudformation:${var.region}:${var.account_number}:stack/serverlessapp-${var.identifier}*/*",
              "arn:aws:cloudformation:${var.region}:${var.account_number}:stackset/*/*",
              "arn:aws:logs:${var.region}:${var.account_number}:log-group:/aws/lambda/serverlessapp-${var.identifier}*"
            ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "cloudformation:ValidateTemplate",
            "cloudformation:GetTemplate",
            "cloudformation:GetTemplateSummary",
            "cloudformation:DescribeStacks",
            "cloudformation:CreateStack",
            "cloudformation:CreateStackSet",
            "cloudformation:ListStacks",
            "s3:ListAllMyBuckets",
            "lambda:GetFunctionEventInvokeConfig",
            "lambda:InvokeAsync",
            "lambda:InvokeFunction",
            "lambda:PublishLayerVersion",
            "lambda:GetFunction"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": [
            "arn:aws:s3:::${local.s3_bucket_name}",
            "arn:aws:s3:::${local.s3_bucket_name}/*"
          ]
        }
      ]
    }
  DOC
}

module "iam_codepipeline_role" {
  source             = "./modules/iam"
  name               = local.iam_codepipeline_role_name
  default_tags       = local.default_tags
  description        = ""
  assume_role_policy = <<-DOC
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": ["codepipeline.amazonaws.com"]
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  DOC
  identifier         = var.identifier
  policy             = <<-DOC
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect":"Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject",
            "codestar-connections:UseConnection",
            "codestar-connections:GetConnection",
            "codestar-connections:PassConnection"
          ],
          "Resource": [
            "arn:aws:s3:::${local.s3_bucket_name}",
            "arn:aws:s3:::${local.s3_bucket_name}/*",
            "${var.codestar_connection_arn}"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "lambda:*"
          ],
          "Resource": "*"
        }
      ]
    }
  DOC
}

module "codebuild" {
  source                 = "./modules/codebuild"
  identifier             = var.identifier
  vpc_id                 = module.networking.vpc_id
  subnet_ids             = module.networking.private_subnet_ids
  security_group_ids     = [module.networking.private_security_group_id]
  account_number         = var.account_number
  s3_artifact_bucket_arn = module.s3.arn
  iam_role_arn           = module.iam_codebuild_role.arn
  env_vars_plain = {
    s3_bucket                 = local.s3_bucket_name
    dist_bucket_url           = "https://s3.${var.region}.amazonaws.com/${local.s3_bucket_name}"
    lambda_role_arn           = module.iam_lambdaexec_role.arn
    security_group            = module.networking.private_security_group_id
    subnet_1                  = module.networking.private_subnet_ids.0
    subnet_2                  = module.networking.private_subnet_ids.1
    rest_api_id               = module.apigateway.id
    rest_api_root_resource_id = module.apigateway.root_resource_id
    stage                     = var.stage
    api_name                  = local.apigateway_name
    region                    = var.region
    identifier                = var.identifier
    cloudformation_role       = module.iam_cloudformation_stack_role.arn
  }
  env_vars_parameter_store = {

  }
  default_tags = local.default_tags
}

module "codepipeline" {
  source                  = "./modules/codepipeline"
  identifier              = var.identifier
  s3_artifact_bucket_name = local.s3_bucket_name
  iam_role_arn            = module.iam_codepipeline_role.arn
  codestar_connection_arn = var.codestar_connection_arn
  source_repository_id    = var.source_repository_id
  default_tags            = local.default_tags
}
