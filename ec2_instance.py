import boto3

# Set your AWS credentials (or use other methods like IAM roles)
aws_access_key = '#############'
aws_secret_key = '###########################'
region_name = 'ap-south-1'  # Change to your desired AWS region

# Initialize Boto3 EC2 client
ec2_client = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=region_name)

def stop_running_instances():
    try:
        # Describe instances with 'running' state
        response = ec2_client.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

        # Extract instance IDs from the response
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])

        if not instance_ids:
            print("No running instances found.")
            return

        print(f"Found {len(instance_ids)} running instances. Stopping...")

        # Stop the instances
        ec2_client.terminate_instances(InstanceIds=instance_ids)
        print("Instances stopped successfully.")

    except Exception as e:
        print("An error occurred:", str(e))

if __name__ == "__main__":
    stop_running_instances()
