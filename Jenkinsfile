pipeline {
    agent any
    environment {
        HARBOR_HOST = '172.21.196.15'
        IMAGE_NAME = 'node-todo'
        IMAGE_TAG = "${BUILD_NUMBER}"
        SSH_HOST = '172.21.196.14'
        KUBECONFIG = '/root/jenkins-k3s/k3s.yaml'
        PROJECT_PATH = '/opt/node-todo'
        HARBOR_CRED = credentials('HARBOR_CRED')
    }

    stages {
        stage('2. 发送代码到宿主机') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "rm -rf ${PROJECT_PATH}"
                scp -r . root@${SSH_HOST}:${PROJECT_PATH}
                """
            }
        }

        stage('3. Node 构建 & 测试') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    cd ${PROJECT_PATH}
                    npm install --registry=https://registry.npmmirror.com
                    npm test
                "
                """
            }
        }

        stage('4. 构建 Docker 镜像') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    cd ${PROJECT_PATH}
                    docker build -t ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG} .
                "
                """
            }
        }

        stage('5. 推送 Harbor') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    docker login ${HARBOR_HOST} -u \${HARBOR_CRED_USR} -p \${HARBOR_CRED_PSW}
                    docker push ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}
                "
                """
            }
        }

        stage('6. 部署到 k3s') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl apply -f ${PROJECT_PATH}/k8s-deploy.yaml
                    kubectl set image deployment/node-todo node-todo=${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}
                    kubectl rollout restart deployment node-todo
                "
                """
            }
        }
    }

    post {
        success { echo "✅ 部署成功！" }
        failure { echo "❌ 构建失败！" }
    }
}
