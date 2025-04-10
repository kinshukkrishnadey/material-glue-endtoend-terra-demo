import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Glue boilerplate
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Read from PostgreSQL using Glue Data Catalog
datasource = glueContext.create_dynamic_frame.from_catalog(
    database = "postgres_catalog",
    table_name = "customers"  # Must match catalog name
)

# Optional: Apply mapping / transformation
mapped = ApplyMapping.apply(
    frame = datasource,
    mappings = [
        ("customerid", "int", "customerid", "int"),
        ("first_name", "string", "first_name", "string"),
        ("last_name", "string", "last_name", "string"),
        ("company", "string", "company", "string"),
        ("country", "string", "country", "string"),
        ("email", "string", "email", "string"),
    ]
)

# Save to S3 in Parquet
glueContext.write_dynamic_frame.from_options(
    frame = mapped,
    connection_type = "s3",
    connection_options = {"path": "s3://my-glue-etl-bucket-demo/output/"},
    format = "parquet"
)

job.commit()
