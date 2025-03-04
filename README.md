# LLM-Powered Mental Health Assistant

![WorkflowLLM](https://github.com/user-attachments/assets/b7bfc4f1-eb67-45c6-9596-da09faef1c41)


This project deploys an **LLM-powered mental health assistant** on **AWS** using **Terraform** and a **CI/CD pipeline with Jenkins**. It leverages **Amazon Bedrock** for AI inference, **AWS Lambda** for backend processing, **API Gateway** for exposure, **DynamoDB** for feedback storage, and **S3** for logs and data.

## Features

- **Amazon Bedrock**: Hosts the LLM (Anthropic Claude v2).
- **AWS Lambda**: Processes user queries and invokes the model.
- **API Gateway**: Exposes the chatbot backend.
- **DynamoDB**: Stores user feedback.
- **S3**: Stores logs and data.
- **Jenkins (Docker)**: CI/CD pipeline for deployment.

---

## Prerequisites

- AWS account with necessary permissions.
- Terraform installed (`terraform --version`).
- AWS CLI configured (`aws configure`).
- Docker installed (for Jenkins).
- GitHub repository access.

---

## Deployment Instructions

### 1. Clone the Repository

```sh
git clone https://github.com/your-repo/llm-assistant.git
cd llm-assistant
```

### 2. Initialize Terraform

```sh
terraform init
```

### 3. Plan Deployment

```sh
terraform plan -out=tfplan
```

### 4. Apply Deployment

```sh
terraform apply -auto-approve tfplan
```

### 5. Upload Lambda Function

```sh
zip -r llm_backend.zip llm_handler.py
aws s3 cp llm_backend.zip s3://llm-mh-logs/
aws lambda update-function-code --function-name LLMBackend --s3-bucket llm-mh-logs --s3-key llm_backend.zip
```

---

## Testing the Chatbot

### 1. From the AWS CLI

```sh
aws lambda invoke --function-name LLMBackend --payload '{ "message": "How can I manage stress?" }' response.json
cat response.json
```

### 2. Using API Gateway

```sh
curl -s -X POST 'https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/backend' -H 'Content-Type: application/json' -d '{ "message": "How can I manage stress?" }'
```

---

## CI/CD Pipeline with Jenkins

1. **Set up Jenkins in a Docker container**:
   ```sh
   docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts
   ```
2. **Access Jenkins** at `http://localhost:8080` and set up your pipeline.
3. **Use the provided `Jenkinsfile`** to automate deployment.

---

## Cleanup

To remove all resources:

```sh
terraform destroy -auto-approve
```

---

## Cost Considerations

- **Amazon Bedrock**: Pay-per-token pricing.
- **Lambda**: Free for first 1M requests, then ~$0.20/million.
- **API Gateway**: ~$1 per million requests.
- **DynamoDB**: Free up to 25GB storage.
- **S3**: ~$0.023/GB after free tier.
- **EC2 for Jenkins**: ~$30/month for a `t3.medium` instance.

For a detailed cost breakdown, check the [AWS Pricing Calculator](https://calculator.aws/).

---

## Future Enhancements

- **Improve logging & monitoring** with AWS CloudWatch.
- **Integrate authentication** for restricted access.
- **Optimize LLM prompts** for better responses.
- **Automate cost tracking** using AWS Cost Explorer.

---

## License

This project is licensed under the MIT License.

---

## Contributors

- **[JG]** - Developer
