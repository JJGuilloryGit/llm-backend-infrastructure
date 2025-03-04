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
                        sh '''
                            # Temporarily rename backend.tf
                            if [ -f backend.tf ]; then
                                mv backend.tf backend.tf.bak
                            fi
                            
                            # Initialize without backend and create DynamoDB table
                            terraform init -input=false
                            terraform apply -auto-approve -lock=false \
                              -target=aws_dynamodb_table.terraform_state_lock
                            
                            # Verify DynamoDB table creation
                            aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 || true
                            
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



