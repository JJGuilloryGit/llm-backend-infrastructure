pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'  # Changed to us-east-2
        TABLE_NAME = 'terraform-state-lock'
        TF_IN_AUTOMATION = 'true'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Bootstrap') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {  # Changed to us-east-2
                    script {
                        sh '''
                            terraform init -input=false
                            terraform apply -auto-approve -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state -target=aws_dynamodb_table.terraform_state_lock
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {  # Changed to us-east-2
                    sh 'terraform init -reconfigure'
                }
            }
        }
        
        // Rest of your stages...
    }
    
    post {
        always {
            cleanWs()
        }
    }
}

