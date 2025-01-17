resource "aws_codepipeline" "permission_sets_pipeline" {
  name     = "${local.prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  tags     = local.common_tags

  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
  }

  stage {
    name = "Clone"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      input_artifacts  = []
      version          = "1"
      output_artifacts = ["CodeWorkspace"]

      configuration = {
        RepositoryName       = local.permission_sets_repository_name
        BranchName           = local.permission_sets_listen_branch_name
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Plan"

    action {
      run_order        = 1
      name             = "Terraform-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["CodeWorkspace"]
      output_artifacts = ["TerraformPlanFile"]
      version          = "1"

      configuration = {
        ProjectName          = aws_codebuild_project.terraform_plan.name
        EnvironmentVariables = jsonencode([
          {
            name  = "PIPELINE_EXECUTION_ID"
            value = "#{codepipeline.PipelineExecutionId}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Manual-Approval"

    action {
      run_order = 1
      name             = "AWS-Admin-Approval"
      category         = "Approval"
      owner            = "AWS"
      provider         = "Manual"
      version          = "1"
      input_artifacts  = []
      output_artifacts = []

      configuration = {
        CustomData = "Please verify the terraform plan output on the Plan stage and only approve this step if you see expected changes!"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      run_order        = 1
      name             = "Terraform-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["CodeWorkspace", "TerraformPlanFile"]
      output_artifacts = []
      version          = "1"

      configuration = {
        ProjectName          = aws_codebuild_project.terraform_apply.name
        PrimarySource        = "CodeWorkspace"
        EnvironmentVariables = jsonencode([
          {
            name  = "PIPELINE_EXECUTION_ID"
            value = "#{codepipeline.PipelineExecutionId}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}