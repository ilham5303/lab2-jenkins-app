pipeline {
    agent {
        label 'docker-agent' // Ensure this runs on your agent with Docker, AWS CLI, Kubectl
    }

    environment {
        // Replace YOUR_DOCKERHUB_USERNAME with your actual Docker Hub username (for image name consistency)
        DOCKERHUB_USERNAME = 'ilhamsbibih'
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/jenkins-python-app" // This will be pushed to ECR
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        LATEST_TAG = "latest"

        // AWS ECR repository URI (replace YOUR_AWS_ACCOUNT_ID and YOUR_AWS_REGION)
        ECR_REPO_URI = '822826627239.dkr.ecr.us-east-1.amazonaws.com/my-flask-app-repo' // From Lab 6
        AWS_REGION = 'us-east-1' // e.g., us-east-1
        AWS_ACCOUNT_ID = '822826627239' // Your AWS Account ID

        // EKS Cluster details (replace YOUR_EKS_CLUSTER_NAME)
        EKS_CLUSTER_NAME = 'my-k8s-cluster' // From Lab 14
        KUBERNETES_NAMESPACE = 'default' // Or your target namespace
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "--- Building Docker Image: ${IMAGE_NAME}:${IMAGE_TAG} ---"
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:${LATEST_TAG} ."
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                // Use AWS Credentials for ECR login
                withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDS')]) {
                    script {
                        echo "--- Logging in to AWS ECR ---"
                        // AWS CLI command to get ECR login password
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URI}"

                        echo "--- Tagging image for ECR ---"
                        // Retag the locally built image with the ECR URI
                        sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}"
                        sh "docker tag ${IMAGE_NAME}:${LATEST_TAG} ${ECR_REPO_URI}:${LATEST_TAG}"

                        echo "--- Pushing Docker Image to ECR ---"
                        sh "docker push ${ECR_REPO_URI}:${IMAGE_TAG}"
                        sh "docker push ${ECR_REPO_URI}:${LATEST_TAG}"

                        echo "--- Docker Image Push to ECR Complete ---"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials', variable: 'AWS_CREDS')]) {
                    script {
                        echo "--- Configuring kubectl for EKS ---"
                        // Update kubeconfig to connect to EKS cluster
                        sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}"
                        // Verify kubectl context
                        sh "kubectl config use-context arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${EKS_CLUSTER_NAME}"
                        sh "kubectl config set-context --current --namespace ${KUBERNETES_NAMESPACE}"

                        echo "--- Deploying to EKS ---"
                        // Define the Kubernetes Deployment and Service YAML inline or from a file
                        // For simplicity, we'll use a basic Nginx deployment and LoadBalancer service here.
                        // In a real scenario, you'd use your Helm Chart or a more complex YAML.
                        def k8sManifest = """
                        apiVersion: apps/v1
                        kind: Deployment
                        metadata:
                          name: jenkins-deployed-app
                          labels:
                            app: jenkins-deployed-app
                        spec:
                          replicas: 1
                          selector:
                            matchLabels:
                              app: jenkins-deployed-app
                          template:
                            metadata:
                              labels:
                                app: jenkins-deployed-app
                            spec:
                              containers:
                              - name: nginx-container
                                image: ${ECR_REPO_URI}:${IMAGE_TAG} // Use the image pushed to ECR
                                ports:
                                - containerPort: 80
                        ---
                        apiVersion: v1
                        kind: Service
                        metadata:
                          name: jenkins-deployed-app-service
                          labels:
                            app: jenkins-deployed-app
                        spec:
                          type: LoadBalancer
                          selector:
                            app: jenkins-deployed-app
                          ports:
                            - protocol: TCP
                              port: 80
                              targetPort: 80
                        """
                        // Apply the Kubernetes manifest
                        sh "echo \"\"\"${k8sManifest}\"\"\" | kubectl apply -f -"

                        echo "--- Waiting for Deployment to be ready ---"
                        sh "kubectl rollout status deployment/jenkins-deployed-app --timeout=300s"

                        echo "--- Deployment to EKS Complete ---"
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Status: ${currentBuild.result}"
        }
        success {
            echo "Congratulations! Build and Deployment succeeded."
        }
        failure {
            echo "Build or Deployment failed. Please check logs."
        }
    }
}

