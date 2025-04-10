#!/bin/bash

validate() {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

echo "[deploy] pruning images on remote pre-transfer"
ssh -i ~/.ssh/quemot-dev.pem ubuntu@quemot.dev <<EOF
validate() {
    EXIT_CODE=\$?
    if [[ \$EXIT_CODE -ne 0 ]]; then
        echo "error: \$1" >&2
        exit \$EXIT_CODE
    fi
}

sudo docker image prune --force
validate "failed to prune old images"
EOF

ssh_username="ubuntu"
ssh_key_file="/home/matt/.ssh/quemot-dev.pem"
manifest_path="$(dirname $(realpath "$0"))/../notes-service.json"
SSH_USERNAME=$ssh_username SSH_KEY_FILE=$ssh_key_file deploy-assets -manifest "$manifest_path" $*
validate "failed to deploy assets"