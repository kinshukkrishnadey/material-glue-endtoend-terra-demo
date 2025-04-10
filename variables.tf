variable "aws_region" {
  default = "us-east-1"
}

variable "s3_bucket" {
  default = "my-glue-etl-bucket-demo"
}

variable "glue_catalog_database" {
  default = "postgres_catalog"
}

variable "glue_catalog_table" {
  default = "postgres_table"
}

variable "glue_job_name" {
  default = "postgres-to-parquet-etl"
}

variable "glue_connection_name" {
  default     = "Jdbc connection"
}
