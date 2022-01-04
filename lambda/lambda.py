import logging
import boto3

s3 = boto3.client("s3")
src_key = "my-key"
src_bucket = "my-bucket"
s3.copy_object(Key=src_key, Bucket=src_bucket,
               CopySource={"Bucket": src_bucket, "Key": src_key},
               Metadata={"my_new_key": "my_new_val"},
               MetadataDirective="REPLACE")