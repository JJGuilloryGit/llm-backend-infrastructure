# LLM Backend Infrastructure

This repository contains the Terraform and Jenkins pipeline configuration for deploying an LLM (Large Language Model) backend infrastructure on AWS, utilizing services such as Lambda, API Gateway, and Amazon Bedrock.

## Architecture

The infrastructure includes:
- Amazon S3 bucket for logs and Terraform state
- DynamoDB tables for feedback storage and state locking
- Lambda function for LLM processing
- API Gateway for REST endpoint
- IAM roles and policies
- Amazon Bedrock integration

## Prerequisites

- AWS Account with appropriate permissions
- Jenkins server with:
  - AWS Credentials plugin
  - Pipeline plugin
  - Git plugin
- Terraform (v1.0.0 or later)
- Git
- Python 3.9+
- Optional testing tools:
  - tfsec
  - checkov
  - infracost

## Repository Structure
├── Jenkinsfile # Jenkins pipeline configuration
├── README.md # This file
├── bootstrap.tf # Bootstrap configuration for S3 and DynamoDB
├── main.tf # Main Terraform configuration
├── test.tf # Test configuration
├── variables.tf # Variable definitions
├── outputs.tf # Output definitions
└── lambda_project/
├── llm_handler.py # Lambda function code
├── requirements.txt # Python dependencies
└── lambda_code.zip # Deployment package


## Setup Instructions

### 1. Local Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/llm-backend-infrastructure.git
cd llm-backend-infrastructure

# Create Lambda deployment package
cd lambda_project
pip install --target ./package -r requirements.txt
cd package
zip -r9 ../lambda_code.zip .
cd ..
zip -g lambda_code.zip llm_handler.py

2. Jenkins Configuration
Install required Jenkins plugins:

AWS Credentials

Pipeline: AWS Steps

CloudBees AWS Credentials

Configure AWS Credentials in Jenkins:

Navigate to Manage Jenkins > Manage Credentials

Add new AWS Credentials

Set ID as 'aws-credentials'

Add AWS Access Key and Secret Key

Create new Pipeline:

New Item > Pipeline

Configure Git repository

Set branch specifier to */main

Save

Deployment Process
1. Bootstrap Infrastructure
First, deploy the bootstrap infrastructure which creates necessary state management resources:

Go to Jenkins pipeline

Click "Build with Parameters"

Select 'bootstrap' from ACTION dropdown

Click "Build"

2. Main Infrastructure Deployment
After bootstrap is complete, deploy the main infrastructure:

Select 'plan' to review changes

Select 'apply' to deploy infrastructure

Approve the changes when prompted

3. Testing Configuration
Run the test suite before deploying changes:

Select 'test' from ACTION dropdown

Tests will check:

Terraform formatting

Configuration validation

Security best practices

Cost estimation

4. Destruction Process
To remove the infrastructure:

Select 'destroy' to remove main infrastructure

Wait for completion

Select 'destroy-bootstrap' to remove bootstrap resources

Pipeline Stages
Standard Deployment Stages
Checkout: Retrieves code from Git repository

Bootstrap: Creates S3 bucket and DynamoDB table for Terraform state

Terraform Init: Initializes Terraform working directory

Terraform Plan: Creates execution plan

Terraform Apply: Applies changes to infrastructure

Terraform Destroy: Removes infrastructure

Testing Stages
Terraform Format Check: Ensures consistent formatting

Terraform Validate: Checks configuration validity

TFSEC Security Scan: Checks security best practices

Checkov Security Scan: Additional security validation

Cost Estimation: Estimates infrastructure costs

Infrastructure Components
Storage
S3 bucket for storing logs

DynamoDB table for feedback storage

S3 bucket for Terraform state

DynamoDB table for state locking

Compute
Lambda function running Python 3.9

Integration with Amazon Bedrock

API
REST API Gateway endpoint

POST method for LLM interactions

CORS enabled

Security
IAM roles and policies

Lambda execution role

Bedrock invocation permissions

Testing

Local Testing

# Format check
terraform fmt -check -recursive

# Validate configuration
terraform init -backend=false
terraform validate

# Security scan
tfsec .
checkov -d .

# Cost estimation
infracost breakdown --path .

Pipeline Testing
Run full test suite through Jenkins:

Select 'test' from ACTION dropdown

Review test results in Jenkins console output

Troubleshooting
Common issues and solutions:

State Lock Error
Ensure DynamoDB table exists

Check for stuck locks in DynamoDB

Verify AWS credentials have DynamoDB permissions

S3 Bucket Name
Must be globally unique

Check for naming conflicts

Verify AWS credentials have S3 permissions

Lambda Timeout
Check Lambda execution time limits

Review CloudWatch logs

Adjust timeout settings if needed

API Gateway CORS
Verify CORS configuration

Check allowed origins

Test with OPTIONS request

IAM Permissions
Ensure proper role permissions

Check policy attachments

Verify resource access

Maintenance
Regular maintenance tasks:

Update dependencies in requirements.txt

Review and rotate AWS credentials

Monitor CloudWatch logs

Check S3 bucket usage

Review API Gateway metrics

Update Terraform providers

Contributing
Fork the repository

Create your feature branch ( git checkout -b feature/AmazingFeature)

Run tests before committing

Commit your changes ( git commit -m 'Add some AmazingFeature')

Push to the branch ( git push origin feature/AmazingFeature)

Open a Pull Request

Security
All sensitive credentials stored in Jenkins credentials store

AWS resources use least-privilege permissions

API Gateway uses CORS protection

S3 buckets are encrypted

State file is encrypted and locked

Regular security scans implemented

For more information or issues, please open a GitHub issue.


This updated README includes:
1. New testing information
2. Detailed deployment steps
3. Enhanced troubleshooting guide
4. Security considerations
5. Maintenance procedures
6. Clear structure and organization
