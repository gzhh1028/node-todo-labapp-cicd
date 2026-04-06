pipeline {
    agent any
    environment {
        HARBOR_HOST     = '172.21.196.15'    // Harbor 仓库
        IMAGE_NAME      = 'node-todo'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        SSH_HOST        = '172.21.196.14'    // 构建节点（Docker 打包）
        K3S_HOST        = '172.21.196.16'    // ✅ K3s 部署节点（已修正！）
        KUBECONFIG      = '/root/jenkins-k3s/k3s.yaml'
        PROJECT_PATH    = '/opt/node-todo'
        HARBOR_CRED     = credentials('HARBOR_CRED')
    }

    stages {
        // 1. 代码同步到构建机(14)
        stage('同步代码到构建机') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "rm -rf ${PROJECT_PATH} && mkdir -p ${PROJECT_PATH}"
                tar -czf - . | ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "tar -xzf - -C ${PROJECT_PATH}"
                """
            }
        }

        // 2. 构建机(14) 构建 Docker 镜像
        stage('构建 Docker 镜像') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    cd ${PROJECT_PATH}
                    docker build -t ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG} .
                "
                """
            }
        }

        // 3. 推送到 Harbor
        stage('推送镜像到 Harbor') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${SSH_HOST} "
                    docker login ${HARBOR_HOST} -u \${HARBOR_CRED_USR} -p \${HARBOR_CRED_PSW}
                    docker push ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}
                "
                """
            }
        }

        // 4. ✅ 部署到 K3s 机器(16)（已修正地址！）
        stage('部署到 K3s') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no root@${K3S_HOST} "
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl apply -f <(ssh root@${SSH_HOST} 'cat ${PROJECT_PATH}/k8s-deploy.yaml')
                    kubectl set image deployment/node-todo node-todo=${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}
                    kubectl rollout restart deployment/node-todo
                "
                """
            }
        }
    }

    post {
        success { echo "✅ 部署成功！镜像：${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}" }
        failure { echo "❌ 构建部署失败！" }
    }
}
