#!/bin/bash

token=$(curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/orgs/SOXAM/actions/runners/registration-token | jq -r .token)

cd actions-runner
./svc.sh uninstall
./config.sh remove --token $token
