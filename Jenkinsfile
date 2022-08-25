pipeline {
	agent { label 'bikenow-vm' }

    stages {
        stage('Build and test Flutter app') {
            steps {
                script {
                    echo 'Building and testing Flutter app...'
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter test && flutter build apk --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)"'
                    echo 'Flutter app build and test complete.'
                }
            }
        }

        stage('Distribute App to Google Play - Internal Track') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    echo 'Building and publishing Flutter Android app...'
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter build appbundle --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)"'
                    // Distribute it with Fastlane.
                    sh 'docker build -t fastlane -f Dockerfile.fastlane .'
                    sh 'docker run --rm -v ${PWD}:/app -w /app/android fastlane fastlane internal'
                    echo 'Complete.'
                }
            }
        }

        stage('Distribute App to Google Play - Closed Track') {
            when {
                branch 'beta'
            }
            steps {
                script {
                    echo 'Building and publishing Flutter Android app...'
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/cirrusci/flutter
                    sh 'docker run --rm -v ${PWD}/.netrc:${HOME}/.netrc -v ${PWD}:/app -w /app cirrusci/flutter:2.10.5 /bin/bash -c "flutter pub get && flutter build appbundle --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)"'
                    // Distribute it with Fastlane.
                    sh 'docker build -t fastlane -f Dockerfile.fastlane .'
                    sh 'docker run --rm -v ${PWD}:/app -w /app/android fastlane fastlane closed'
                    echo 'Complete.'
                }
            }
        }
    }

    post {
        success {
            echo 'Build and test complete. Uploading artifacts...'
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk'
        }
    }
}
