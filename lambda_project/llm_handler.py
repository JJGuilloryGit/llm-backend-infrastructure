import json
import boto3
import os

def lambda_handler(event, context):
    try:
        # Parse the incoming request
        body = json.loads(event['body']) if 'body' in event else {}
        input_text = body.get('input', '')
        
        # Initialize Bedrock client
        bedrock = boto3.client('bedrock-runtime')
        
        # Example request body for Claude model
        request_body = {
            "prompt": input_text,
            "max_tokens_to_sample": 500,
            "temperature": 0.7,
            "top_p": 1
        }
        
        # Invoke Bedrock model
        response = bedrock.invoke_model(
            modelId='anthropic.claude-v2',
            body=json.dumps(request_body)
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        
        # Log to S3
        s3 = boto3.client('s3')
        logs_bucket = os.environ['LOGS_BUCKET']
        
        log_data = {
            'input': input_text,
            'response': response_body
        }
        
        s3.put_object(
            Bucket=logs_bucket,
            Key=f'logs/{context.aws_request_id}.json',
            Body=json.dumps(log_data)
        )
        
        # Store feedback in DynamoDB
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['FEEDBACK_TABLE'])
        
        table.put_item(
            Item={
                'feedback_id': context.aws_request_id,
                'input': input_text,
                'response': response_body
            }
        )
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': response_body
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
