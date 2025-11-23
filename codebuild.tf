resource "aws_codebuild_project" "build_project" {
  name          = "entrega4-build"
  description   = "Builds the entrega4 project"
  build_timeout = "15"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.app_repo.repository_url
    }
    
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/daanjiri/MISW4304_202515_DevOps.git"
    git_clone_depth = 1
    buildspec       = "buildspec.yml" 
  }
}

data "aws_caller_identity" "current" {}
