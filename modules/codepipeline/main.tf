
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.identifier}-codepipeline"
  role_arn = var.iam_role_arn

  artifact_store {
    location = var.s3_artifact_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "App"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        BranchName       = "aws"
        FullRepositoryId = var.source_repository_id
        ConnectionArn    = var.codestar_connection_arn
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${var.identifier}-codebuild"
      }
    }
  }
  tags = merge({ "Name" = "codepipeline" }, var.default_tags)
}
