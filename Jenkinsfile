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
        
        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
                    script {
                        if (params.ACTION == 'destroy') {
                            // Initialize without backend for destroy
                            sh 'terraform init -migrate-state -backend=false'
                        } else {
                            // Normal initialization for other actions
                            sh 'terraform init'
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
                        // Get the lock ID from the error message or user input
                        def lockId = input(
                            id: 'lockId',
                            message: 'Enter the lock ID to force unlock:',
                            parameters: [
                                string(defaultValue: '', 
                                       description: 'Lock ID from error message', 
                                       name: 'LOCK_ID')
                            ]
                        )
                        
                        // Execute force-unlock
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
                    script {
                        // Try normal destroy first
                        try {
                            sh 'terraform destroy -auto-approve'
                        } catch (Exception e) {
                            // If normal destroy fails, try with lock disabled
                            echo "Normal destroy failed, attempting destroy with lock disabled..."
                            sh 'terraform destroy -auto-approve -lock=false'
                        }
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
                    Destroy failed. If you're experiencing lock issues, try:
                    1. Select 'force-unlock' from the build parameters
                    2. Enter the lock ID from the error message
                    3. Run the pipeline again
                    """
                }
            }
        }
    }
}



