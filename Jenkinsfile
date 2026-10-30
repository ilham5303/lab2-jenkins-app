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
                echo "--- Building ${IMAGE_NAME}:${IMAGE_TAG} ---"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:${LATEST_TAG} ."
            }
        }

        stage('Test Application') {
            steps {
                sh '''
                    docker run -d --name test-app-$BUILD_NUMBER $IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    docker exec test-app-$BUILD_NUMBER python -c "import urllib.request; r = urllib.request.urlopen('http://localhost:5000'); print('Status:', r.status)"
                '''
            }
            post {
                always {
                    sh 'docker rm -f test-app-$BUILD_NUMBER || true'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                 usernameVariable: 'DOCKER_USERNAME',
                                 passwordVariable: 'DOCKER_PASSWORD')]) {
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