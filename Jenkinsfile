pipeline {
    agent { label 'docker-agent' }

       environment {
        AWS_REGION       = 'us-east-1'
        AWS_ACCOUNT_ID   = '822826627239'
        ECR_REGISTRY     = '822826627239.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO_URI     = '822826627239.dkr.ecr.us-east-1.amazonaws.com/my-flask-app-repo'
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
        EKS_CLUSTER_NAME = 'my-k8s-cluster'
        K8S_NAMESPACE    = 'default'
        APP_PORT         = '80'
        DEPLOY_IMAGE     = 'nginx:latest'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
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
                        aws ecr get-login-password --region "$AWS_REGION" \
                          | docker login --username AWS --password-stdin "$ECR_REGISTRY"
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
                    sh '''
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"
kubectl get nodes
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
          image: $DEPLOY_IMAGE
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
kubectl apply -n "$K8S_NAMESPACE" -f k8s-manifest.yaml
kubectl rollout status deployment/jenkins-deployed-app -n "$K8S_NAMESPACE" --timeout=300s
kubectl get svc jenkins-deployed-app-service -n "$K8S_NAMESPACE"
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
        success { echo 'Congratulations! Build and Deployment succeeded.' }
        failure { echo 'Build or Deployment failed. Please check logs.' }
    }
}


