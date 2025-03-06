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

## Repository Structure
├── Jenkinsfile # Jenkins pipeline configuration
├── README.md # This file
├── bootstrap.tf # Bootstrap configuration for S3 and DynamoDB
├── main.tf # Main Terraform configuration
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

### 2. Jenkins Config
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

### Infrastructure Deployment
The infrastructure can be deployed using Jenkins pipeline with two options:

Apply: Creates or updates the infrastructure

Destroy: Removes the infrastructure

To deploy:

Open the pipeline in Jenkins

Click "Build with Parameters"

Select 'apply' or 'destroy'

Click "Build"

### Pipeline Stages###
Checkout : Retrieves code from Git repository

Bootstrap : Creates S3 bucket and DynamoDB table for Terraform state

Terraform Init : Initializes Terraform working directory

Terraform Plan : Creates execution plan (apply only)

Terraform Apply : Applies changes to infrastructure (apply only)

Terraform Destroy : Removes infrastructure (destroy only)

#Infrastructure Components

#Storage
S3 bucket for storing logs

DynamoDB table for feedback storage

S3 bucket for Terraform state

DynamoDB table for state locking

#Compute
Lambda function running Python 3.9

Integration with Amazon Bedrock

#API
REST API Gateway endpoint

POST method for LLM interactions

CORS enabled

#Security
IAM roles and policies

Lambda execution role

Bedrock invocation permissions

Testing
Test the deployed API using:

curl -X POST \
  https://your-api-gateway-url/prod/backend \
  -H 'Content-Type: application/json' \
  -d '{"input": "your test message"}'


#Cleanup
To remove all created resources:

Run Jenkins pipeline with 'destroy' parameter

Manually delete bootstrap resources if needed:

S3 bucket for Terraform state

DynamoDB state lock table

#Contributing
Fork the repository

Create your feature branch ( git checkout -b feature/AmazingFeature)

Commit your changes ( git commit -m 'Add some AmazingFeature')

Push to the branch ( git push origin feature/AmazingFeature)

Open a Pull Request

#Security
All sensitive credentials are stored in Jenkins credentials store

AWS resources use least-privilege permissions

API Gateway uses CORS protection

S3 buckets are encrypted

State file is encrypted and locked

#Troubleshooting
Common issues:

State Lock Error: Ensure DynamoDB table exists

S3 Bucket Name: Must be globally unique

Lambda Timeout: Check Lambda execution time limits

API Gateway CORS: Verify CORS configuration

IAM Permissions: Ensure proper role permissions

#Maintenance
Regular maintenance tasks:

Update dependencies in requirements.txt

Review and rotate AWS credentials

Monitor CloudWatch logs

Check S3 bucket usage

Review API Gateway metrics

For more information or issues, please open a GitHub issue.