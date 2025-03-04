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
                    """
                }
            }
        }
    }
}







