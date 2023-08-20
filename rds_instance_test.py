import boto3

# Set your AWS credentials (or use other methods like IAM roles)
region = "ap-south-1"
access_key = "#############"
secret_key = "###########################"
db_instance_name = 'myrdsinstance'  # Replace with the RDS instance name


# Initialize Boto3 RDS client
rds_client = boto3.client('rds', aws_access_key_id=access_key, aws_secret_access_key=secret_key, region_name=region)

try:
    # Describe the RDS instance
    response = rds_client.describe_db_instances(DBInstanceIdentifier=db_instance_name)
    print(response,"response")

    # Check if the instance exists
    if len(response['DBInstances']) > 0:
        instance = response['DBInstances'][0]
        status = instance['DBInstanceStatus']

        print(f"Instance {db_instance_name} exists and is in '{status}' state.")

    else:
        print(f"Instance {db_instance_name} does not exist.")

except Exception as e:
    print("An error occurred:", str(e))
