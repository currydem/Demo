import boto3
from botocore.exceptions import NoCredentialsError, ClientError
from dotenv import load_dotenv
import os

def check_image_in_s3(bucket_name, image_key):
    """
    Checks if a specific image exists in an S3 bucket.

    Args:
        bucket_name (str): The name of the S3 bucket.
        image_key (str): The key (path) of the image in the bucket.

    Returns:
        bool: True if the image exists, False otherwise.
              Returns None and prints an error if an exception occurs.
    """
    try:
        # Create an S3 client
        s3_client = boto3.client('s3')

        # Use head_object to check if the object exists.  This is more efficient
        # than trying to get the object itself.
        try:
            s3_client.head_object(Bucket=bucket_name, Key=image_key)
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                # The object does not exist.
                return False
            else:
                # Some other error occurred.  Re-raise the exception for
                # the outer try...except to handle.
                raise

        # If head_object does not raise an exception, the object exists.
        return True

    except NoCredentialsError:
        print("Error: AWS credentials not found.  Make sure your credentials "
              "are configured correctly (e.g., via environment variables, "
              "~/.aws/credentials, or an IAM role).")
        return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

def main():
    """
    Main function to run the S3 image check.
    """
    bucket_name = 'poly-test-qrcodes'
    image_key = 'Label_AB10000000A0.png'

    # Load environment variables from .env file
    load_dotenv()

    # Check if the required variables are set
    if not all(os.environ.get(var) for var in ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_DEFAULT_REGION']):
        print("Error: AWS credentials are not set in the .env file.")
        return

    print(f"Checking for image '{image_key}' in bucket '{bucket_name}'...")
    image_exists = check_image_in_s3(bucket_name, image_key)

    if image_exists is None:
        print("Unable to determine image existence due to an error.")
    elif image_exists:
        print(f"The image '{image_key}' exists in the bucket '{bucket_name}'.")
    else:
        print(f"The image '{image_key}' does not exist in the bucket '{bucket_name}'.")


if __name__ == "__main__":
    main()
