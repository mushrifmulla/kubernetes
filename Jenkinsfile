pipeline{
    agent any
    environment{
        IMAGE_NAME = 'mushrifmulla/maven-web-application'
        TAG = "${BUILD_NUMBER}"
    }
    tools{
        maven 'maven3.9'
    }

    stages{
        stage('code checkout'){
            steps{
                git credentialsId: 'gitpass1', url: 'https://github.com/mushrifmulla/maven-web-application.git'
            }
        }

        stage('Build'){
            steps{
                sh "mvn clean package"
            }
        }

        stage('docker image'){
            steps{
                sh "docker build -t ${IMAGE_NAME}:${TAG} ."
            }
        }

        stage('docker Login and Push'){
            steps{
                sh "docker login -u username -p password"
                sh "docker push ${IMAGE_NAME}:${TAG}"
            }
        

        stage('k8s cluster'){
            steps{
                sh "kubectl apply -f Requests_Limits_deployment.yml"
            }
        }

    }
}