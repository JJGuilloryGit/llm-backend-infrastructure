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

    stages {
        stage('Check/Install AWS CLI') {
            steps {
                script {
                    try {
                        // First check if AWS CLI exists
                        def awsCliExists = sh(script: 'which aws || true', returnStatus: true) == 0
                        
                        if (!awsCliExists) {
                            // Install prerequisites
                            sh '''
                                # Update package list
                                apt-get update
                                
                                # Install required packages
                                apt-get install -y curl unzip
                                
                                # Download AWS CLI v2
                                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
                                
                                # Unzip the downloaded file
                                cd /tmp
                                unzip -q awscliv2.zip
                                
                                # Install AWS CLI
                                ./aws/install
                                
                                # Cleanup
                                rm -rf /tmp/aws /tmp/awscliv2.zip
                                
                                # Verify installation
                                aws --version
                            '''
                        } else {
                            echo "AWS CLI is already installed"
                            sh 'aws --version'
                        }
                    } catch (Exception e) {
                        echo "Detailed error: ${e.getMessage()}"
                        // Try alternative installation method if first one fails
                        try {
                            sh '''
                                # Try alternative installation method
                                mkdir -p $HOME/.local/bin
                                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                                unzip -q awscliv2.zip
                                ./aws/install --bin-dir $HOME/.local/bin --install-dir $HOME/.local/aws-cli
                                export PATH=$HOME/.local/bin:$PATH
                                rm -rf aws awscliv2.zip
                                aws --version
                            '''
                            env.PATH = "${env.HOME}/.local/bin:${env.PATH}"
                        } catch (Exception e2) {
                            echo "Alternative installation also failed: ${e2.getMessage()}"
                            error "AWS CLI installation failed after trying multiple methods"
                        }
                    }
                }
            }
        }

        // ... rest of your stages remain the same ...
    }

    // ... post section remains the same ...
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
}








