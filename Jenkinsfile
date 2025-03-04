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
        
        stage('Install AWS CLI') {
            steps {
                sh '''
                    sudo rm -f /var/lib/apt/lists/lock
                    sudo rm -f /var/cache/apt/archives/lock
                    sudo rm -f /var/lib/dpkg/lock*
                    sudo dpkg --configure -a
                    sudo apt-get update
                    sudo apt-get install -y python3-pip
                    sudo pip3 install --upgrade pip
                    sudo pip3 install awscli
                '''
            }
        }
        
        stage('Create DynamoDB Table') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        // Check if table exists
                        def tableExists = sh(
                            script: "aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 2>&1 || echo 'not_exists'",
                            returnStdout: true
                        ).trim()
                        
                        if (tableExists.contains('not_exists')) {
                            // Create the DynamoDB table
                            sh '''
                                aws dynamodb create-table \
                                    --table-name terraform-state-lock \
                                    --attribute-definitions AttributeName=LockID,AttributeType=S \
                                    --key-schema AttributeName=LockID,KeyType=HASH \
                                    --billing-mode PAY_PER_REQUEST \
                                    --region us-east-1
                                
                                # Wait for table to be active
                                aws dynamodb wait table-exists --table-name terraform-state-lock --region us-east-1
                            '''
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
                            // Initialize without backend for destroy
                            sh 'terraform init -migrate-state -backend=false -lock=false'
                        } else {
                            // Normal initialization for other actions
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
                        // Always use lock-free destroy
                        sh 'terraform destroy -auto-approve -lock=false'
                        
                        // After successful destroy, remove the DynamoDB table
                        sh '''
                            aws dynamodb delete-table \
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




