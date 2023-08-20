import boto3

# Set your AWS credentials (or use other methods like IAM roles)
region = "ap-south-1"
access_key = "#############"
secret_key = "###########################"
db_instance_name = 'myrdsinstance'  # Replace with the RDS instance name

# Initialize Boto3 RDS client
rds_client = boto3.client('rds', aws_access_key_id=access_key, aws_secret_access_key=secret_key, region_name=region)

try:
    # Describe all RDS instances
    response = rds_client.describe_db_instances()

    # Loop through instances and delete each one
    for instance in response['DBInstances']:
        instance_id = instance['DBInstanceIdentifier']

        # Delete the instance
        rds_client.delete_db_instance(DBInstanceIdentifier=instance_id, SkipFinalSnapshot=True)

        print(f"Deleted RDS instance: {instance_id}")

except Exception as e:
    print("An error occurred:", str(e))
