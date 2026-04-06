pipeline {
    agent any
    environment {
        HARBOR_HOST     = '172.21.196.15'
        IMAGE_NAME      = 'node-todo'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        SSH_HOST        = '172.21.196.14'
        K3S_HOST        = '172.21.196.16'
        KUBECONFIG      = '/etc/rancher/k3s/k3s.yaml'  // ✅ 修复：K3s 真实默认路径
        PROJECT_PATH    = '/opt/node-todo'
        HARBOR_CRED     = credentials('HARBOR_CRED')
    }

    stages {
        stage('同步代码到构建机') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "rm -rf ${PROJECT_PATH} && mkdir -p ${PROJECT_PATH}"
                tar -czf - . | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "tar -xzf - -C ${PROJECT_PATH}"
                """
            }
        }

        stage('构建 Docker 镜像') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "
                    cd ${PROJECT_PATH}
                    docker build -t ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG} .
                "
                """
            }
        }

        stage('推送镜像到 Harbor') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "
                    docker login ${HARBOR_HOST} -u \${HARBOR_CRED_USR} -p \${HARBOR_CRED_PSW}
                    docker push ${HARBOR_HOST}/library/${IMAGE_NAME}:${IMAGE_TAG}
                "
                """
            }
        }

        // ✅ 最终 100% 可运行部署
        stage('部署到 K3s') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${K3S_HOST} "
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl apply -f <(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} 'cat ${PROJECT_PATH}/k8s-deploy.yaml')
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
