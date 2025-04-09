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

resource "aws_iam_role" "glue_service_role" {
  name = "glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_catalog_database" "catalog_db" {
  name = var.glue_catalog_database
}

resource "aws_glue_catalog_table" "source_table" {
  name          = var.glue_catalog_table
  database_name = aws_glue_catalog_database.catalog_db.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    columns
      columns{
        name = "customerid"
        type = "int"
      }
      columns{
        name = "first_name"
        type = "string"
      }
      columns{
        name = "last_name"
        type = "string"
      }
      columns{
        name = "company"
        type = "string"
      }
      columns{
        name = "country"
        type = "string"
      }
      columns{
        name = "email"
        type = "string"
      }


    location      = "jdbc:postgresql://postgredb-instance.cyjq2iau4tvi.us-east-1.rds.amazonaws.com:5432/postgredb_demo/customers"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    serde_info {
      name                  = "serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
  }
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

