pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        WORKSPACE = 'development'
        PATH = "$HOME/.local/bin:${env.PATH}"
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
                        sh '''
                            # Create installation directories
                            mkdir -p $HOME/.local/bin
                            
                            # Install required packages
                            if command -v apt-get &> /dev/null; then
                                apt-get update && apt-get install -y curl unzip
                            elif command -v yum &> /dev/null; then
                                yum install -y curl unzip
                            fi
                            
                            # Download and install AWS CLI
                            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                            unzip -q awscliv2.zip
                            ./aws/install --bin-dir $HOME/.local/bin --install-dir $HOME/.local/aws-cli --update
                            
                            # Add to PATH permanently for this job
                            echo "export PATH=$HOME/.local/bin:$PATH" >> $HOME/.bashrc
                            
                            # Clean up installation files
                            rm -rf aws awscliv2.zip
                            
                            # Source the updated bashrc
                            . $HOME/.bashrc
                            
                            # Verify installation
                            $HOME/.local/bin/aws --version
                        '''
                        
                        // Update PATH in Jenkins environment
                        env.PATH = "$HOME/.local/bin:${env.PATH}"
                    } catch (Exception e) {
                        echo "Installation failed with error: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
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
}









