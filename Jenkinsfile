pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
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
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        // Temporarily rename backend.tf to prevent initialization errors
                        sh '''
                            if [ -f backend.tf ]; then
                                mv backend.tf backend.tf.bak
                            fi
                            
                            # Initialize without backend
                            terraform init
                            
                            # Apply bootstrap resources
                            terraform apply -auto-approve \
                              -target=aws_s3_bucket.terraform_state \
                              -target=aws_s3_bucket_versioning.terraform_state \
                              -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                              -target=aws_s3_bucket_public_access_block.terraform_state \
                              -target=aws_dynamodb_table.terraform_state_lock
                            
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
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh '''
                        terraform init -reconfigure -backend=true
                        terraform init -migrate-state
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh 'terraform destroy -auto-approve'
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


