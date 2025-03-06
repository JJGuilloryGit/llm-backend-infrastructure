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
            choices: ['plan', 'apply', 'destroy', 'bootstrap'],
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










