pipeline {
    agent any
    
    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }
    
    environment {
        DOCKER_IMAGE = 'ayaflah/devp'  // Change this to your Docker Hub username
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        APP_PORT = '8089'
    }
    
    stage('Run Tests') {
    steps {
        echo '=== Running Unit Tests ==='
        script {
            try {
                sh 'mvn test'
            } catch (Exception e) {
                echo "Tests failed: ${e.getMessage()}"
                echo "Continuing pipeline anyway..."
                currentBuild.result = 'UNSTABLE'
            }
        }
    }
    post {
        always {
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
        }
    }
}
    stages {
        stage('📥 Checkout') {
            steps {
                echo '=== Checking out source code ==='
                checkout scm
            }
        }
        
        stage('🔍 Environment Info') {
            steps {
                echo '=== Display Environment Information ==='
                sh '''
                    echo "Java Version:"
                    java -version
                    echo "\nMaven Version:"
                    mvn -version
                    echo "\nDocker Version:"
                    docker --version
                '''
            }
        }
        
        stage('🔨 Maven Build') {
            steps {
                echo '=== Building with Maven ==='
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('🧪 Run Tests') {
            steps {
                echo '=== Running Unit Tests ==='
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('📦 Archive Artifacts') {
            steps {
                echo '=== Archiving Artifacts ==='
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('🐳 Build Docker Image') {
            steps {
                echo "=== Building Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG} ==="
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('🔍 Verify Image') {
            steps {
                echo '=== Verifying Docker Image ==='
                sh """
                    docker images | grep ${DOCKER_IMAGE}
                    docker inspect ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }
        
        stage('📤 Push to Docker Hub') {
            steps {
                echo '=== Pushing to Docker Hub ==='
                script {
                    withCredentials([usernamePassword(
                        credentialsId: DOCKER_CREDENTIALS_ID,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage('🛑 Stop Old Container') {
            steps {
                echo '=== Stopping Old Container ==='
                sh '''
                    docker stop devp-app || true
                    docker rm devp-app || true
                '''
            }
        }
        
        stage('🚀 Deploy Container') {
            steps {
                echo '=== Deploying New Container ==='
                sh """
                    docker run -d \
                        --name devp-app \
                        --restart unless-stopped \
                        -p ${APP_PORT}:${APP_PORT} \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                    
                    echo "Waiting for container to start..."
                    sleep 10
                """
            }
        }
        
        stage('✅ Health Check') {
            steps {
                echo '=== Verifying Deployment ==='
                sh """
                    echo "Container Status:"
                    docker ps | grep devp-app
                    
                    echo "\nContainer Logs:"
                    docker logs devp-app --tail 50
                    
                    echo "\nTesting Application Endpoint:"
                    curl -f http://localhost:${APP_PORT} || echo "Application is starting..."
                """
            }
        }
    }
    
    post {
        success {
            echo '''
            ========================================
            ✅ PIPELINE COMPLETED SUCCESSFULLY!
            ========================================
            '''
            echo "🌐 Application URL: http://192.168.33.10:${APP_PORT}"
            echo "🐳 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "📦 Latest Tag: ${DOCKER_IMAGE}:latest"
        }
        failure {
            echo '''
            ========================================
            ❌ PIPELINE FAILED!
            ========================================
            '''
            sh 'docker logs devp-app || true'
        }
        always {
            echo '🧹 Cleaning up unused Docker resources...'
            sh '''
                docker image prune -f || true
                docker container prune -f || true
            '''
        }
    }
}