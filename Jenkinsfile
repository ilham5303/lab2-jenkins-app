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

        // Test BEFORE push, and test inside the image (where Flask is installed)
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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credenti                withCredentials(                     le: 'DOCKER_USERNAME',
                                 passwordVariable: 'DOCKER_PASSWORD')]) {
                    // Single quotes: the shell reads the secret, not Groovy
                                                                                                  din'                                  sh ${IMAGE_NAME}:${IMAGE_TAG}"
                                                                                               }
        }
    }

    post {
        always  { echo "Pipeline finished. Status: ${currentBuild.currentResult}" }
        success { echo "Congratulations! Build succeeded." }
        failure { echo "Build failed. Please check logs." }
    }
}
