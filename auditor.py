import boto3
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    sns = boto3.client('sns')
    
    # We will pass this ARN in as an environment variable via Terraform
    sns_topic_arn = os.environ['SNS_TOPIC_ARN'] 
    
    vulnerable_buckets = []
    
    print("Starting compliance audit of S3 buckets...")
    response = s3.list_buckets()
    
    for bucket in response['Buckets']:
        bucket_name = bucket['Name']
        try:
            # Try to get the Public Access Block configuration
            s3.get_public_access_block(Bucket=bucket_name)
            print(f"✅ {bucket_name} is compliant.")
            
        except s3.exceptions.ClientError as e:
            # If the configuration doesn't exist, AWS throws this specific error
            if e.response['Error']['Code'] == 'NoSuchPublicAccessBlockConfiguration':
                print(f"🚨 VULNERABILITY FOUND: {bucket_name} is missing a Public Access Block!")
                vulnerable_buckets.append(bucket_name)
                
    # If we found vulnerable buckets, ring the alarm!
    if vulnerable_buckets:
        message = (
            "🚨 COMPLIANCE ALERT: S3 VULNERABILITY DETECTED 🚨\n\n"
            "The automated compliance engine has detected the following S3 buckets "
            "are missing Public Access Block configurations:\n\n"
        )
        for b in vulnerable_buckets:
            message += f"- {b}\n"
            
        message += "\nPlease remediate this immediately to prevent data exposure."
        
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject="AWS Security Alert: Open S3 Buckets Detected",
            Message=message
        )
        return {"status": "Vulnerabilities found, alert dispatched."}
        
    return {"status": "Audit complete. All buckets compliant."}