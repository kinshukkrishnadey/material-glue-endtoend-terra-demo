provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "glue_output" {
  bucket = var.s3_bucket
  force_destroy = true
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.glue_output.id
  key    = "scripts/etl_script.py"
  source = "${path.module}/glue_job/etl_script.py"
  etag   = filemd5("${path.module}/glue_job/etl_script.py")
}

# Glue IAM Role
resource "aws_iam_role" "glue_service_role" {
  name = "glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWS managed policies to Glue role
resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_console_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_glue_catalog_database" "catalog_db" {
  name = var.glue_catalog_database
}

resource "aws_glue_job" "glue_etl_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_output.bucket}/scripts/etl_script.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"          = "s3://${aws_s3_bucket.glue_output.bucket}/temp/"
    "--job-language"     = "python"
    "--enable-metrics"   = "true"
  }

  glue_version = "4.0"
  max_capacity = 2
}

