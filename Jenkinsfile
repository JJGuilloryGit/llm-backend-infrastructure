pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        WORKSPACE = 'development'
        AWS_CLI_PATH = '/usr/local/bin/aws'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy', 'bootstrap'],
            description: 'Select the action to perform'
        )
    }

    stage('Check/Install AWS CLI') {
    steps {
        script {
            try {
                def awsCliInstalled = sh(script: 'which aws', returnStatus: true) == 0
                if (!awsCliInstalled) {
                    sh '''
                        # Create local bin directory
                        mkdir -p $HOME/.local/bin
                        
                        # Download AWS CLI
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip -o awscliv2.zip
                        
                        # Install to user's home directory
                        ./aws/install --bin-dir $HOME/.local/bin --install-dir $HOME/.local/aws-cli
                        
                        # Add to PATH
                        export PATH=$HOME/.local/bin:$PATH
                        
                        # Clean up
                        rm -rf aws awscliv2.zip
                    '''
                    
                    // Update PATH in Jenkins environment
                    env.PATH = "${env.HOME}/.local/bin:${env.PATH}"
                } else {
                    echo 'AWS CLI is already installed'
                }
                
                // Verify installation
                sh 'aws --version'
            } catch (Exception e) {
                echo "Error installing AWS CLI: ${e.getMessage()}"
                error "AWS CLI installation failed"
            }
        }
    }
}

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Bootstrap Infrastructure') {
            when {
                expression { params.ACTION == 'bootstrap' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    script {
                        dir('bootstrap') {
                            sh 'terraform init'
                            sh 'terraform plan -out=tfplan'
                            input message: 'Do you want to apply bootstrap configuration?'
                            sh 'terraform apply tfplan'
                        }
                    }
                }
            }
        }

        stage('Terraform Init') {
            when {
                expression { params.ACTION != 'bootstrap' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    script {
                        if (params.ACTION == 'destroy') {
                            sh 'terraform init -reconfigure'
                        } else {
                            sh 'terraform init'
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION != 'bootstrap' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    script {
                        if (params.ACTION == 'destroy') {
                            sh 'terraform plan -destroy -out=tfplan'
                        } else {
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                input message: "Do you want to proceed with ${params.ACTION}?"
            }
        }

        stage('Terraform Apply/Destroy') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    sh 'terraform apply tfplan'
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
                if (params.ACTION in ['apply', 'destroy']) {
                    echo """
                    Pipeline failed. If there's a lock on the state, you may need to:
                    1. Check the Terraform state lock
                    2. Release the lock if necessary
                    3. Run the pipeline again
                    """
                }
            }
        }
    }








