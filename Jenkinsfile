pipeline {
    agent {
        label 'docker-agent' // Runs on the agent with Docker, AWS CLI, kubectl
    }

    environment {
        AWS_REGION       = 'us-east-1'
        AWS_ACCOUNT_ID   = '822826627239'
        ECR_REGISTRY     = '822826627239.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO_URI     = '822826627239.dkr.ecr.us-east-1.amazonaws.com/my-flask-app-repo'
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
        EKS_CLUSTER_NAME = 'my-k8s-cluster'
        K8S_NAMESPACE    = 'default'
        APP_PORT         = '5000' // the port app.py listens on
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                // --platform linux/amd64: your Mac is ARM, the EKS nodes are x86
                sh '''
                    echo "--- Building $ECR_REPO_URI:$IMAGE_TAG ---"
                    docker build --platform linux/amd64 \
                        -t "$ECR_REPO_URI:$IMAGE_TAG" \
                        -t "$ECR_REPO_URI:latest" .
                '''
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials',
                                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        echo "--- Logging in to AWS ECR ---"
                        aws ecr get-login-password --region "$AWS_REGION" \
                          | docker login --username AWS --password-stdin "$ECR_REGISTRY"

                        echo "--- Pushing Docker Image to ECR ---"
                        docker push "$ECR_REPO_URI:$IMAGE_TAG"
                        docker push "$ECR_REPO_URI:latest"
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials',
                                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    // The YAML below must stay flush left (no indentation) to be valid.
                    sh '''
echo "--- Configuring kubectl for EKS ---"
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"
kubectl get nodes

echo "--- Deploying to EKS ---"
cat > k8s-manifest.yaml <<EOF
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
        - name: flask-app
          image: $ECR_REPO_URI:$IMAGE_TAG
          ports:
            - containerPort: $APP_PORT
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
      targetPort: $APP_PORT
EOF
cat k8s-manifest.yaml
kubectl apply -n "$K8S_NAMESPACE" -f k8s-manifest.yaml

echo "--- Waiting for Deployment to be ready ---"
kubectl rollout status deployment/jenkins-deployed-app -n "$K8S_NAMESPACE" --timeout=300s
kubectl get svc jenkins-deployed-app-service -n "$K8S_NAMESPACE"
echo "--- Deployment to EKS Complete ---"
'''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout "$ECR_REGISTRY" || true'
            echo "Pipeline finished. Status: ${currentBuild.currentResult}"
        }
        success {
            echo 'Congratulations! Build and Deployment succeeded.'
        }
        failure {
            echo 'Build or Deployment failed. Please check logs.'
        }
    }
}