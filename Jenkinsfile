node('docker') {
  try {
    properties([disableConcurrentBuilds()])

    repository = "quay.io/aspenmesh/bookinfo-private"
    branchName = env.BRANCH_NAME.toLowerCase()
    version = "$branchName-${env.BUILD_ID}"

    stage('Checkout') {
      checkout scm
    }

    stage('Build and Push') {
      docker.withRegistry('https://quay.io', 'quay-infrajenkins-robot-creds') {
        sh "./build_push_update_images.sh $repository $version"
      }
    }

    tmpDir = sh(script: "mktemp -d --tmpdir=$WORKSPACE", returnStdout: true).trim()
    experimentNamespace = "bookinfo-dev-$branchName"
    stage('Deploy') {
      if ("$branchName" != 'master') {
        withEnv(["BINDIR=$tmpDir"]) {
          sh '''
             kubectl=$BINDIR'/kubectl'
             curl -o $kubectl -L 'https://storage.googleapis.com/kubernetes-release/release/v1.7.11/bin/linux/amd64/kubectl'
             chmod +x $kubectl
          '''

          withCredentials([file(credentialsId: 'dummy_k8s_cluster_jenkins_config', variable: 'KUBECONFIG')]) {
            sh "./deploy.sh $repository $version $experimentNamespace"
          }
        }
      } else {
        sh "echo 'Skipping deploy for master branch' "
      }
    }
    experimentName = "bookinfo-$branchName"
    baselineNamespace = "default"
    service = "productpage"
    stage('Aspen Experiment') {
      if (env.BRANCH_NAME != 'master') {
        withEnv(["BINDIR=$tmpDir"]) {
          copyArtifacts(projectName: 'apiserver/master',
                        filter: '_build/canonical/cross/aspenctl-linux-amd64',
                        selector: lastSuccessful(), target: "$tmpDir", flatten: true)
          sh '''
            aspenctl=$BINDIR'/aspenctl'
            mv $BINDIR'/aspenctl-linux-amd64' $aspenctl
            chmod +x $aspenctl
          '''
          withCredentials([string(credentialsId: 'dummy_user_agent_token', variable: 'TOKEN')]) {
            sh "./create-experiment.sh $experimentName $baselineNamespace $experimentNamespace $service"
          }
        }
      } else {
        sh "echo 'Skipping aspen experiment for master branch' "
      }
    }
  } catch (e) {
    throw e
  } finally {
      sh "if [ -d $tmpDir ]; then rm -r $tmpDir; fi "
  }
}
