pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        TABLE_NAME = 'terraform-state-lock'
        TF_IN_AUTOMATION = 'true'
        HOME = '/var/jenkins_home'
        AWS_CLI_PATH = '/var/jenkins_home/.local/bin/aws'
    }
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy', 'force-unlock'],
            description: 'Select the action to perform (apply, destroy, or force-unlock)'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup AWS CLI') {
            steps {
                sh '''
                    mkdir -p /var/jenkins_home/.local/bin
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip -o awscliv2.zip
                    ./aws/install --bin-dir /var/jenkins_home/.local/bin --install-dir /var/jenkins_home/.local/aws-cli --update
                    rm -rf aws awscliv2.zip
                    export PATH=/var/jenkins_home/.local/bin:$PATH
                '''
            }
        }
        
        stage('Create DynamoDB Table') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        // Check if table exists
                        def tableExists = sh(
                            script: "/var/jenkins_home/.local/bin/aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 2>&1 || echo 'not_exists'",
                            returnStdout: true
                        ).trim()
                        
                        if (tableExists.contains('not_exists')) {
                            echo "Creating DynamoDB table terraform-state-lock..."
                            sh '''
                                /var/jenkins_home/.local/bin/aws dynamodb create-table \
                                    --table-name terraform-state-lock \
                                    --attribute-definitions AttributeName=LockID,AttributeType=S \
                                    --key-schema AttributeName=LockID,KeyType=HASH \
                                    --billing-mode PAY_PER_REQUEST \
                                    --region us-east-1
                                
                                /var/jenkins_home/.local/bin/aws dynamodb wait table-exists --table-name terraform-state-lock --region us-east-1
                            '''
                        } else {
                            echo "DynamoDB table terraform-state-lock already exists, skipping creation..."
                        }
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        if (params.ACTION == 'destroy') {
                            sh 'terraform init -migrate-state -backend=false -lock=false'
                        } else {
                            sh 'terraform init -lock=false'
                        }
                    }
                }
            }
        }
        
        stage('Force Unlock') {
            when {
                expression { params.ACTION == 'force-unlock' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        def lockId = input(
                            id: 'lockId',
                            message: 'Enter the lock ID to force unlock:',
                            parameters: [
                                string(defaultValue: '', 
                                       description: 'Lock ID from error message', 
                                       name: 'LOCK_ID')
                            ]
                        )
                        sh "terraform force-unlock -force ${lockId}"
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh 'terraform plan -lock=false -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    sh 'terraform apply -lock=false -auto-approve tfplan'
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        sh 'terraform destroy -auto-approve -lock=false'
                        
                        sh '''
                            /var/jenkins_home/.local/bin/aws dynamodb delete-table \
                                --table-name terraform-state-lock \
                                --region us-east-1 || true
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            script {
                if (params.ACTION == 'destroy') {
                    echo """
                    Destroy failed. Try the following:
                    1. Select 'force-unlock' from the build parameters
                    2. Enter the lock ID from the error message
                    3. Run the pipeline again
                    
                    If issues persist, you may need to manually delete the DynamoDB table:
                    aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1
                    """
                }
            }
        }
    }
}






