pipeline {
    agent {
        docker {
            image 'alpine/helm:latest'
            args '-u root:root'
        }
    }
    
    environment {
        // Set the Helm repository URL for Dentira organization
        HELM_REPO_URL = 'https://dentira.bitbucket.io/temporal-charts/'
        CHART_DIR = 'charts/temporal'
        DOCS_DIR = 'docs'
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    sh '''
                        apk add --no-cache git bash
                        git config user.email "jenkins@dentira.com"
                        git config user.name "Jenkins CI"
                    '''
                }
            }
        }
        
        stage('Lint Chart') {
            steps {
                echo '🔍 Linting Helm chart...'
                sh "helm lint ${CHART_DIR}"
                echo '✅ Chart validation passed!'
            }
        }
        
        stage('Package Chart') {
            when {
                tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
            }
            steps {
                echo '📦 Packaging Helm chart...'
                echo "Repository URL will be ${HELM_REPO_URL}"
                sh """
                    helm package ${CHART_DIR} -d ${DOCS_DIR}/
                """
            }
        }
        
        stage('Update Repository Index') {
            when {
                tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
            }
            steps {
                echo '📝 Updating repository index...'
                sh """
                    helm repo index ${DOCS_DIR}/ --url ${HELM_REPO_URL} --merge ${DOCS_DIR}/index.yaml
                """
            }
        }
        
        stage('Commit and Push') {
            when {
                tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
            }
            steps {
                echo '📤 Committing and pushing changes...'
                script {
                    sh """
                        git add ${DOCS_DIR}/
                        git diff --staged --quiet || git commit -m "Update Helm repository for ${TAG_NAME} [skip ci]"
                        git push origin HEAD:main
                    """
                }
                echo '✅ Helm repository updated successfully!'
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            script {
                if (env.TAG_NAME) {
                    echo """
                    🎉 Chart published!
                    
                    Users can now install with:
                      helm repo add temporal-charts ${HELM_REPO_URL}
                      helm repo update
                      helm install my-temporal temporal-charts/temporal --version ${TAG_NAME.replaceFirst('v', '')}
                    """
                }
            }
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}

