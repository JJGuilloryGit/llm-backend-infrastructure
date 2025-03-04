pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-2'
        TABLE_NAME = 'terraform-state-lock'
        TF_IN_AUTOMATION = 'true'
    }
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Select the action to perform (apply or destroy)'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Bootstrap') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {
                    script {
                        sh '''
                            # Temporarily rename backend.tf
                            if [ -f backend.tf ]; then
                                mv backend.tf backend.tf.bak
                            fi
                            
                            # Initialize without backend and apply bootstrap resources without state lock
                            terraform init -input=false
                            terraform apply -auto-approve -lock=false \
                              -target=aws_s3_bucket.terraform_state \
                              -target=aws_s3_bucket_versioning.terraform_state \
                              -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                              -target=aws_s3_bucket_public_access_block.terraform_state \
                              -target=aws_dynamodb_table.terraform_state_lock
                            
                            # Verify DynamoDB table creation
                            aws dynamodb describe-table --table-name terraform-state-lock --region us-east-2 || true
                            
                            # Restore backend.tf
                            if [ -f backend.tf.bak ]; then
                                mv backend.tf.bak backend.tf
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Init with Backend') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {
                    sh '''
                        # Initialize with backend, without state lock
                        terraform init -reconfigure -backend=true -lock=false
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {
                    sh 'terraform plan -lock=false -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {
                    sh 'terraform apply -lock=false -auto-approve tfplan'
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-2') {
                    sh 'terraform destroy -lock=false -auto-approve'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}


