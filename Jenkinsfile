pipeline {
	agent { label 'bikenow-vm' }

    stages {
        stage('Build and test Flutter app') {
            steps {
                script {
                    echo 'Building and testing Flutter app...'
                    // Build and test the Flutter app in a Docker image.
                    // See: https://hub.docker.com/r/fischerscode/flutter/tags
                    sh 'docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable /bin/bash -c "flutter pub get && flutter test && flutter build apk"'
                    echo 'Flutter app build and test complete.'
                }
            }
        }
    }
}
