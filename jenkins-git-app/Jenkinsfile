pipeline {
    agent { label 'docker-agent' }

    environment {
        AWS_ACCOUNT_ID       = '822826627239'
        AWS_REGION           = 'us-east-1'
        ECR_REGISTRY         = "822826627239.dkr.ecr.us-east-1.amazonaws.com"
        ECR_REPO_URI         = "822826627239.dkr.ecr.us-east-1.amazonaws.com/my-flask-app-repo"
        IMAGE_NAME           = 'jenkins-python-app'
        IMAGE_TAG            = "${env.BUILD_NUMBER}"
        EKS_CLUSTER_NAME     = 'my-k8s-cluster'
        KUBERNETES_NAMESPACE = 'default'
        RDS_ENDPOINT         = 'my-flask-app-db.c50k6qy48ewz.us-east-1.rds.amazonaws.com'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --platform linux/amd64 -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ./jenkins-git-app"
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}"
                    sh "docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URI}:latest"
                    sh "docker push ${ECR_REPO_URI}:${IMAGE_TAG}"
                    sh "docker push ${ECR_REPO_URI}:latest"
                }
            }
        }

        stage('Deploy to EKS with Helm') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}"
                    sh "kubectl get nodes"
                    sh "helm upgrade --install my-flask-app-release ./my-flask-chart --namespace ${KUBERNETES_NAMESPACE} --atomic --wait --timeout 5m --set image.repository=${ECR_REPO_URI} --set image.tag=${IMAGE_TAG} --set service.type=LoadBalancer --set service.port=80 --set service.targetPort=5000 --set env.DB_HOST=${RDS_ENDPOINT} --set env.DB_NAME=mydatabase --set env.DB_USER=myuser --set env.DB_PASSWORD=mypassword --set replicaCount=2"
                    sh "helm list -n ${KUBERNETES_NAMESPACE}"
                    sh "kubectl get svc"
                }
            }
        }
    }

    post {
        success {
            echo "Build and Deployment succeeded."
        }
        failure {
            echo "Build or Deployment failed. Check logs."
        }
    }
}

