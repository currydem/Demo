terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.AWS_DEFAULT_REGION #  AWS Region -  taken from the environment variable
  access_key =  var.AWS_ACCESS_KEY_ID
  secret_key =  var.AWS_SECRET_ACCESS_KEY
  # Use the default provider behavior:  It will look for credentials in environment variables.
}

# Create a VPC
resource "aws_vpc" "nifi_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "NiFi VPC"
  }
}

# Create a Subnet
resource "aws_subnet" "nifi_subnet" {
  vpc_id     = aws_vpc.nifi_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a" # Replace with your desired Availability Zone
  tags = {
    Name = "NiFi Subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "nifi_igw" {
  vpc_id = aws_vpc.nifi_vpc.id
  tags = {
    Name = "NiFi Internet Gateway"
  }
}

# Create a Route Table
resource "aws_route_table" "nifi_route_table" {
  vpc_id = aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nifi_igw.id
  }

  tags = {
    Name = "NiFi Route Table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "nifi_rta" {
  subnet_id      = aws_subnet.nifi_subnet.id
  route_table_id = aws_route_table.nifi_route_table.id
}

# Create an EC2 Key Pair
resource "aws_key_pair" "nifi_key_pair" {
  key_name   = "nifi-key-pair" #  Name for the key pair
  public_key = file("~/.ssh/id_rsa.pub") # Replace with your public key path

  tags = {
    Name = "NiFi Key Pair"
  }
}

resource "aws_instance" "nifi_instance" {
  ami           = "ami-084568db4383264d4" #  Ubuntu Server 20.04 AMI ID (example, verify for your region)
  instance_type = "t3.medium" # Or a suitable instance type (e.g., t3.medium, t4g.medium)
  key_name      = aws_key_pair.nifi_key_pair.key_name # Use the key pair created above
  subnet_id     = aws_subnet.nifi_subnet.id  # Use the Subnet created above
  vpc_security_group_ids = [aws_security_group.nifi_sg.id]

  tags = {
    Name = "NiFi-Server" # A name for your EC2 instance
  }
}

resource "aws_security_group" "nifi_sg" {
  name        = "nifi-sg"
  description = "Allow inbound traffic for NiFi"
  vpc_id      = aws_vpc.nifi_vpc.id # Use the VPC created above

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This allows traffic from anywhere.  For production, restrict this to your specific IP or network.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NiFi Security Group"
  }
}

resource "aws_s3_bucket" "nifi_data_bucket" {
  bucket = "nifi-data-bucket-currydemdemo" #  S3 bucket name
  acl    = "private" # Or "public-read" if needed, but "private" is generally safer

  tags = {
    Name = "NiFi Data Bucket"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.nifi_data_bucket.id
  status = "Enabled" # Enable versioning for data protection
}

output "nifi_instance_public_ip" {
  value = aws_instance.nifi_instance.public_ip
  description = "Public IP of the NiFi instance"
}

output "nifi_private_key" {
  value = aws_key_pair.nifi_key_pair.private_key
  sensitive = true
  description = "The private key for the NiFi instance.  Store this securely!"
}