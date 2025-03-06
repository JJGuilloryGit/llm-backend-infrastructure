pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        WORKSPACE = 'development'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['bootstrap', 'plan', 'apply', 'destroy'],  // Moved bootstrap to first position
            description: 'Select the action to perform'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Bootstrap Infrastructure') {
            when {
                expression { params.ACTION == 'destroy-bootstrap' }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    script {
                        // Explicitly check if bootstrap.tf exists
                        sh 'ls -la bootstrap.tf || echo "bootstrap.tf not found in root directory"'
                        
                        // Create bootstrap directory if it doesn't exist
                        sh 'mkdir -p bootstrap'
                        
                        // Copy bootstrap.tf to bootstrap directory if it's in root
                        sh '''
                            if [ -f bootstrap.tf ]; then
                                cp bootstrap.tf bootstrap/
                                echo "Copied bootstrap.tf to bootstrap directory"
                            fi
                        '''
                        
                        dir('bootstrap') {
                            sh 'ls -la'  // List files for verification
                            sh 'terraform init -reconfigure'
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











