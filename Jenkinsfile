pipeline {
    agent any
    environment {
        HARBOR_HOST     = '172.21.196.15'
        IMAGE_NAME      = 'node-todo'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        SSH_HOST        = '172.21.196.14'
        K3S_HOST        = '172.21.196.16'
        KUBECONFIG      = '/root/jenkins-k3s/k3s.yaml'  // ✅ 你真实存在的路径
        HARBOR_CRED     = credentials('HARBOR_CRED')
    }

    stages {
        stage('同步代码到构建机') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "rm -rf /opt/node-todo && mkdir -p /opt/node-todo"
                tar -czf - . | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "tar -xzf - -C /opt/node-todo"
                """
            }
        }

        stage('构建 Docker 镜像') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SSH_HOST} "
                    cd /opt/node-todo
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

        // ✅ 最终最干净、不会报错的部署
        stage('部署到 K3s') {
            steps {
                sh """
                # 1. 把 yaml 传到 16 机器 /opt（永久保存，不删除）
                scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null k8s-deploy.yaml root@${K3S_HOST}:/opt/

                # 2. 在 16 上直接部署
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${K3S_HOST} "
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl apply -f /opt/k8s-deploy.yaml
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
