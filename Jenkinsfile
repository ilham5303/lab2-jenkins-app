pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'ilhamsbibih'
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/jenkins-python-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        LATEST_TAG = "latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:${LATEST_TAG} ."
            }
        }

        stage('Test Application') {
            steps {
                sh "docker run -d --name test-app-${BUILD_NUMBER} ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "sleep 5"
                sh "docker exec test-app-${BUILD_NUMBER} wget -q -O /dev/null http://localhost:5000"
                echo "Test passed: app returned a page"
            }
            post {
                always {
                    sh "docker rm -f test-app-${BUILD_NUMBER} || true"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin'
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${IMAGE_NAME}:${LATEST_TAG}"
                }
            }
        }
    }

    post {
        always  { echo "Pipeline finished. Status: ${currentBuild.currentResult}" }
        success { echo "Congratulations! Build succeeded." }
        failure { echo "Build failed. Please check logs." }
    }
}
