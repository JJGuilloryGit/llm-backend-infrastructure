# LLM Backend Infrastructure

## Overview
This repository contains the backend infrastructure for deploying and managing a Large Language Model (LLM) backend. It is designed to be scalable, cloud-native, and easily deployable using Infrastructure as Code (IaC).

## Features
- API Gateway to handle requests
- AWS Lambda for serverless execution
- Amazon Bedrock for LLM processing
- DynamoDB for data storage
- S3 for storing logs and state files
- Terraform for infrastructure provisioning

## Architecture Workflow

Below is a high-level workflow of the backend infrastructure:

1. **Client Request**: The user sends a request to the API Gateway.
2. **API Gateway**: Routes the request to the appropriate AWS Lambda function.
3. **Lambda Function**: Processes the request, interacts with Amazon Bedrock for LLM processing, and queries/stores data in DynamoDB.
4. **Amazon Bedrock**: Executes the LLM processing tasks and returns the results.
5. **DynamoDB**: Stores user data, logs, or other necessary state information.
6. **S3 Bucket**: Stores logs and Terraform state files.
7. **Response to Client**: The processed response is sent back via the API Gateway.

![WorkflowLLM](https://github.com/user-attachments/assets/4be31832-d6f1-4852-b17e-8a611042d3a8)

## Prerequisites
- AWS Account
- Terraform installed (`>=1.0` recommended)
- AWS CLI configured with appropriate IAM permissions
- Node.js (`>=16.0` recommended) for local testing

## Setup Instructions
### 1. Clone the Repository
```sh
git clone https://github.com/JJGuilloryGit/llm-backend-infrastructure.git
cd llm-backend-infrastructure
```

### 2. Initialize Terraform
```sh
terraform init
```

### 3. Plan and Apply the Infrastructure
```sh
terraform plan
terraform apply
```

### 4. Deploy Lambda Function
Modify and package your Lambda function, then deploy:
```sh
zip -r function.zip lambda_function.py
aws lambda update-function-code --function-name MyLambdaFunction --zip-file fileb://function.zip
```

## Usage
- Send requests to the API Gateway endpoint to interact with the LLM backend.
- Monitor logs using AWS CloudWatch.

## Contributing
Feel free to submit pull requests or open issues to suggest improvements.

## License
This project is licensed under the MIT License.

