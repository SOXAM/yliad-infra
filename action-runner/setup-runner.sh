#!/bin/bash

set -x

token=$(curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/orgs/SOXAM/actions/runners/registration-token | jq -r .token)

# Download
mkdir -p actions-runner && cd actions-runner
echo -e "Download runner binary file.."
curl -s -o actions-runner-osx-arm64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-osx-arm64-2.319.1.tar.gz
echo "af6a2fba35cc63415693ebfb969b4d7a9d59158e1f3587daf498d0df534bf56f  actions-runner-osx-arm64-2.319.1.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-osx-arm64-2.319.1.tar.gz

# Configure
./config.sh --url https://github.com/SOXAM --token $token --runnergroup Default --name $(hostname) --labels Build --work _work --replace
./svc.sh install
./svc.sh status
./svc.sh start
#./run.sh &
