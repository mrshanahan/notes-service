#!/bin/bash

echo "[deploy] restarting services & pruning unused images on remote"
ssh -i ~/.ssh/quemot-dev.pem ubuntu@quemot.dev <<EOF
validate() {
    EXIT_CODE=\$?
    if [[ \$EXIT_CODE -ne 0 ]]; then
        echo "error: \$1" >&2
        exit \$EXIT_CODE
    fi
}

pushd /home/ubuntu/package
sudo ./manage.sh stop && sudo ./manage.sh start
validate "failed to restart service"

sudo docker image prune --force
validate "failed to prune old images"
EOF