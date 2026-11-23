pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }
  triggers { githubPush() }
  parameters {
    string(name: 'IMAGE_REPOSITORY', defaultValue: '', description: 'Optional registry image, for example ghcr.io/owner/node-todo-cicd')
    booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish on the default branch using registry-credentials')
    booleanParam(name: 'DEPLOY_PRODUCTION', defaultValue: false, description: 'Run the protected deployment command on the default branch')
  }
  stages {
    stage('Checkout') {
      steps { checkout scm; script { env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim(); def repository = params.IMAGE_REPOSITORY?.trim() ? params.IMAGE_REPOSITORY.trim() : 'zaid-node-todo'; env.IMAGE = "${repository}:${env.GIT_COMMIT_SHORT}" } }
    }
    stage('Validate') {
      steps { sh 'npm ci --ignore-scripts'; sh 'npm test' }
    }
    stage('Build and smoke check') {
      steps {
        sh '''
          set -eu
          name="todo-smoke-${BUILD_NUMBER}"
          trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
          docker build --pull -t "${IMAGE}" .
          docker run -d --name "$name" -P "${IMAGE}"
          port=$(docker port "$name" 8000/tcp | head -n 1 | awk -F: '{print $NF}')
          for attempt in $(seq 1 20); do
            if curl --fail --silent "http://127.0.0.1:${port}/todo" | grep -qi 'todo'; then exit 0; fi
            sleep 1
          done
          docker logs "$name"
          exit 1
        '''
      }
    }
    stage('Publish image') {
      when { expression { params.PUBLISH_IMAGE && (env.BRANCH_NAME == 'master' || env.GIT_BRANCH == 'origin/master') } }
      steps {
        script {
          if (!params.IMAGE_REPOSITORY?.trim()) error('Set IMAGE_REPOSITORY before publishing')
          withCredentials([usernamePassword(credentialsId: 'registry-credentials', usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASSWORD')]) {
            sh 'echo "$REGISTRY_PASSWORD" | docker login "$(echo "$IMAGE_REPOSITORY" | cut -d/ -f1)" -u "$REGISTRY_USER" --password-stdin'
            sh 'docker push "${IMAGE}"'
            sh 'docker logout "$(echo "$IMAGE_REPOSITORY" | cut -d/ -f1)"'
          }
        }
      }
    }
    stage('Deploy production') {
      when { expression { params.DEPLOY_PRODUCTION && params.PUBLISH_IMAGE && (env.BRANCH_NAME == 'master' || env.GIT_BRANCH == 'origin/master') } }
      agent { label 'production' }
      steps {
        sh '''
          set -eu
          if [ -z "${DEPLOY_COMMAND:-}" ]; then echo 'Configure DEPLOY_COMMAND in a protected Jenkins folder' >&2; exit 1; fi
          IMAGE="${IMAGE}" sh -c "$DEPLOY_COMMAND"
        '''
      }
    }
  }
  post { success { echo "Pipeline completed for ${env.GIT_COMMIT_SHORT}" } }
}
