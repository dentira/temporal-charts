pipeline {
    agent {
        docker {
            image 'alpine/helm:latest'
            args '-u root:root'
        }
    }
    
    environment {
        // Set the Helm repository URL for Dentira organization
        HELM_REPO_URL = 'https://dentira.github.io/temporal-charts/'
        CHART_DIR = 'charts/temporal'
        DOCS_DIR = 'docs'
        GIT_CREDENTIALS_ID = 'github-credentials' // Update this to match your Jenkins credentials ID
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    echo '🔧 Setting up environment...'
                    sh '''
                        apk add --no-cache git bash curl
                        git config user.email "jenkins@dentira.com"
                        git config user.name "Jenkins CI"
                    '''
                    
                    // Display build information
                    echo """
                    ═══════════════════════════════════════════════════
                    Build Information:
                    ═══════════════════════════════════════════════════
                    Job Name:     ${env.JOB_NAME}
                    Build Number: ${env.BUILD_NUMBER}
                    Branch:       ${env.BRANCH_NAME ?: 'N/A'}
                    Tag:          ${env.TAG_NAME ?: 'N/A'}
                    Commit:       ${env.GIT_COMMIT ?: 'N/A'}
                    ═══════════════════════════════════════════════════
                    """
                }
            }
        }
        
        stage('Validate Chart') {
            steps {
                echo '🔍 Validating Helm chart structure...'
                script {
                    sh """
                        # Check if Chart.yaml exists
                        if [ ! -f ${CHART_DIR}/Chart.yaml ]; then
                            echo "❌ Chart.yaml not found!"
                            exit 1
                        fi
                        
                        # Check if values.yaml exists
                        if [ ! -f ${CHART_DIR}/values.yaml ]; then
                            echo "❌ values.yaml not found!"
                            exit 1
                        fi
                        
                        # Check if templates directory exists
                        if [ ! -d ${CHART_DIR}/templates ]; then
                            echo "❌ templates directory not found!"
                            exit 1
                        fi
                        
                        echo "✅ Chart structure is valid!"
                    """
                }
            }
        }
        
        stage('Lint Chart') {
            steps {
                echo '🔍 Linting Helm chart...'
                script {
                    def lintResult = sh(
                        script: "helm lint ${CHART_DIR}",
                        returnStatus: true
                    )
                    
                    if (lintResult != 0) {
                        error("❌ Helm lint failed!")
                    }
                    
                    echo '✅ Chart validation passed!'
                }
            }
        }
        
        stage('Test Chart') {
            steps {
                echo '🧪 Running chart tests...'
                script {
                    sh """
                        # Dry-run installation to validate templates
                        echo "Testing chart template rendering..."
                        helm template test-release ${CHART_DIR} > /dev/null
                        
                        echo "✅ Chart templates are valid!"
                    """
                }
            }
        }
        
        stage('Package Chart') {
            when {
                anyOf {
                    tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
                    expression { params.FORCE_PACKAGE == true }
                }
            }
            steps {
                echo '📦 Packaging Helm chart...'
                script {
                    sh """
                        echo "Repository URL: ${HELM_REPO_URL}"
                        
                        # Get chart version
                        CHART_VERSION=\$(grep '^version:' ${CHART_DIR}/Chart.yaml | awk '{print \$2}')
                        echo "Chart Version: \$CHART_VERSION"
                        
                        # Package the chart
                        helm package ${CHART_DIR} -d ${DOCS_DIR}/
                        
                        # List packaged files
                        echo "Packaged files:"
                        ls -lh ${DOCS_DIR}/*.tgz
                    """
                    
                    echo '✅ Chart packaged successfully!'
                }
            }
        }
        
        stage('Update Repository Index') {
            when {
                anyOf {
                    tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
                    expression { params.FORCE_PACKAGE == true }
                }
            }
            steps {
                echo '📝 Updating repository index...'
                script {
                    sh """
                        # Backup existing index
                        if [ -f ${DOCS_DIR}/index.yaml ]; then
                            cp ${DOCS_DIR}/index.yaml ${DOCS_DIR}/index.yaml.backup
                            echo "Backed up existing index.yaml"
                        fi
                        
                        # Update repository index
                        helm repo index ${DOCS_DIR}/ --url ${HELM_REPO_URL} --merge ${DOCS_DIR}/index.yaml
                        
                        # Display index contents
                        echo "Repository index updated:"
                        cat ${DOCS_DIR}/index.yaml
                    """
                    
                    echo '✅ Repository index updated!'
                }
            }
        }
        
        stage('Commit and Push') {
            when {
                anyOf {
                    tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
                    expression { params.FORCE_PACKAGE == true }
                }
            }
            steps {
                echo '📤 Committing and pushing changes...'
                script {
                    // Use Jenkins credentials for Git operations
                    withCredentials([usernamePassword(
                        credentialsId: env.GIT_CREDENTIALS_ID,
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh """
                            # Configure git to use credentials
                            git config credential.helper store
                            
                            # Add changes
                            git add ${DOCS_DIR}/
                            
                            # Check if there are changes to commit
                            if git diff --staged --quiet; then
                                echo "No changes to commit"
                            else
                                # Commit changes
                                COMMIT_MSG="Update Helm repository for ${env.TAG_NAME ?: 'manual build'} [skip ci]"
                                git commit -m "\$COMMIT_MSG"
                                
                                # Push to remote
                                git push https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/dentira/temporal-charts.git HEAD:main
                                
                                echo "✅ Changes pushed successfully!"
                            fi
                        """
                    }
                }
            }
        }
        
        stage('Create GitHub Release') {
            when {
                tag pattern: "v\\d+\\.\\d+\\.\\d+.*", comparator: "REGEXP"
            }
            steps {
                echo '🚀 Creating GitHub Release...'
                script {
                    withCredentials([string(
                        credentialsId: 'github-token',
                        variable: 'GITHUB_TOKEN'
                    )]) {
                        sh """
                            # Get the packaged chart file
                            CHART_FILE=\$(ls ${DOCS_DIR}/temporal-*.tgz | tail -1)
                            CHART_VERSION=\$(basename \$CHART_FILE .tgz | sed 's/temporal-//')
                            
                            echo "Creating GitHub release for version \$CHART_VERSION..."
                            
                            # Create release using GitHub API
                            curl -X POST \
                                -H "Authorization: token \${GITHUB_TOKEN}" \
                                -H "Accept: application/vnd.github.v3+json" \
                                https://api.github.com/repos/dentira/temporal-charts/releases \
                                -d "{
                                    \\"tag_name\\": \\"${env.TAG_NAME}\\",
                                    \\"name\\": \\"Release ${env.TAG_NAME}\\",
                                    \\"body\\": \\"Helm chart version \$CHART_VERSION\\\\n\\\\nInstall with:\\\\n\\\`\\\`\\\`bash\\\\nhelm repo add temporal-charts ${HELM_REPO_URL}\\\\nhelm repo update\\\\nhelm install my-temporal temporal-charts/temporal --version \$CHART_VERSION\\\\n\\\`\\\`\\\`\\",
                                    \\"draft\\": false,
                                    \\"prerelease\\": false
                                }"
                            
                            echo "✅ GitHub release created!"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            script {
                if (env.TAG_NAME) {
                    def version = env.TAG_NAME.replaceFirst('v', '')
                    echo """
                    ═══════════════════════════════════════════════════
                    🎉 Chart Published Successfully!
                    ═══════════════════════════════════════════════════
                    Version:      ${version}
                    Tag:          ${env.TAG_NAME}
                    Repository:   ${HELM_REPO_URL}
                    
                    Users can now install with:
                      helm repo add temporal-charts ${HELM_REPO_URL}
                      helm repo update
                      helm install my-temporal temporal-charts/temporal --version ${version}
                    ═══════════════════════════════════════════════════
                    """
                } else {
                    echo """
                    ═══════════════════════════════════════════════════
                    ✅ Chart Validation Passed!
                    ═══════════════════════════════════════════════════
                    The Helm chart has been validated successfully.
                    To publish a new version, create and push a version tag.
                    ═══════════════════════════════════════════════════
                    """
                }
            }
        }
        failure {
            echo """
            ═══════════════════════════════════════════════════
            ❌ Pipeline Failed!
            ═══════════════════════════════════════════════════
            Build Number: ${env.BUILD_NUMBER}
            Job Name:     ${env.JOB_NAME}
            
            Please check the logs above for error details.
            ═══════════════════════════════════════════════════
            """
        }
        always {
            // Archive artifacts
            archiveArtifacts artifacts: "${DOCS_DIR}/*.tgz", allowEmptyArchive: true, fingerprint: true
            
            // Clean workspace
            cleanWs()
        }
    }
}

// Pipeline parameters (optional)
properties([
    parameters([
        booleanParam(
            name: 'FORCE_PACKAGE',
            defaultValue: false,
            description: 'Force packaging even without a version tag'
        )
    ])
])

