pipeline {
	agent { label 'bikenow-vm' }

    stages {
        stage('Build necessary docker images') {
            steps {
                sh 'docker build -t fastlane -f ${PWD}/Dockerfile.fastlane /home/jenkins/'
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}/.git:${HOME}/.git -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter test"'
                }
            }
        }

        stage('Distribute App to Google Play - Internal Track') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}/.git:${HOME}/.git -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter build appbundle"'
                    // Distribute it with Fastlane.
                    sh 'docker run --rm -v ${PWD}:/app -w /app/android fastlane fastlane internal'
                }
            }
        }

        stage('Distribute App to Google Play - Closed Track') {
            when {
                branch 'beta'
            }
            steps {
                script {
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}/.git:${HOME}/.git -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter build appbundle"'
                    // Distribute it with Fastlane.
                    sh 'docker run --rm -v ${PWD}:/app -w /app/android fastlane fastlane closed'
                }
            }
        }
    }

    post {
        success {
            echo 'Build and test complete. Uploading artifacts...'
            archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', allowEmptyArchive: true
        }
    }
}
