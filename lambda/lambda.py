import logging
import boto3
import json
from botocore.exceptions import ClientError

def lambda_handler(event, context):
# Retrieve the list of existing buckets
    s3 = boto3.client('s3')
    response = s3.list_buckets()
    
# This Outputs all the bucket names
# print('Existing buckets:')
    
# This prints the name of needed Bucket.   
# for bucket in response['Buckets']:
# print(f'  {bucket["Name"]}')
    
        
    bucket_name = event["S3Bucket"]
    key = event["S3Prefix"]
    s3_object = s3.get_object(Bucket=bucket_name, Key=key)
    body = json.loads(s3_object['Body'].read())
    
    for pet in body["pets"]:
        name=pet["name"]
        if name == event["PetName"]:
            favouriteFoods=",".join(pet['favFoods'])
            print(name + " Favourite Foods Are: " + favouriteFoods)
            