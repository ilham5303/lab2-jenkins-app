// Explanation: This defines a Declarative Pipeline.
// Declarative Pipelines are structured and easier to read.
pipeline {
    // Explanation: Specifies where the pipeline will run.
    // 'agent any' means Jenkins can run this pipeline on any available agent.
    // For Docker builds, you could also specify 'agent { dockerfile true }'
    // or 'agent { docker { image 'docker:dind' } }' for isolated Docker-in-Docker.
    // For this lab, 'agent any' relies on the Jenkins server having Docker access.
    agent any

    // Explanation: Define environment variables that will be available throughout the pipeline.
    environment {
        // Replace YOUR_DOCKERHUB_USERNAME with your actual Docker Hub username
        DOCKERHUB_USERNAME = 'YOUR_DOCKERHUB_USERNAME'
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/jenkins-python-app"
        // BUILD_NUMBER is a built-in Jenkins environment variable
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        LATEST_TAG = "latest"
        // You can also add other env vars here, e.g., for database connections
    }

    // Explanation: Define the stages of your CI/CD pipeline.
    stages {
        // Stage 1: Checkout - Get code from SCM
        stage('Checkout') {
            steps {
                // Explanation: 'checkout scm' automatically checks out the code
                // from the SCM configured in the job.
                checkout scm
            }
        }

        // Stage 2: Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    echo "--- Building Docker Image: ${IMAGE_NAME}:${IMAGE_TAG} ---"
                    // 'sh' executes shell commands. 'docker build' uses the Dockerfile in the current directory.
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:${LATEST_TAG} ."
                }
            }
        }

        // Stage 3: Push Docker Image to Registry
        stage('Push Docker Image') {
            steps {
                // Explanation: 'withCredentials' securely exposes credentials to the step.
                // 'dockerhub-credentials' is the ID you set in Jenkins Credentials Manager.
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        echo "--- Logging in to Docker Hub ---"
                        // Use the exposed environment variables for Docker login
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"

                        echo "--- Pushing Docker Image: ${IMAGE_NAME}:${IMAGE_TAG} ---"
                        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker push ${IMAGE_NAME}:${LATEST_TAG}"

                        echo "--- Docker Image Push Complete ---"
                    }
                }
            }
        }

        // Stage 4: Basic Test (running the Python app)
        stage('Test Application') {
            steps {
                script {
                    echo "--- Running Python application for basic test ---"
                    // Execute the Python application
                    sh "python app.py"
                    echo "--- Application test complete ---"
                }
            }
        }
    }

    // Explanation: Define actions to take after the entire pipeline finishes.
    post {
        // 'always' means this block will always run, regardless of build success or failure.
        always {
            echo "Pipeline finished. Status: ${currentBuild.result}"
        }
        // 'success' means this block runs only if the pipeline succeeds.
        success {
            echo "Congratulations! Build succeeded."
        }
        // 'failure' means this block runs only if the pipeline fails.
        failure {
            echo "Build failed. Please check logs."
        }
    }
}

