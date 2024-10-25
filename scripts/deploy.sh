#!/bin/bash

# ./deploy.sh ./package_X.tar.gz

PACKAGE="$1"
if [[ -z $PACKAGE ]]; then
    FOUND_PACKAGE=$(ls -1 ./package_*.tar.gz | sort | tail -1)
    if [[ -z $FOUND_PACKAGE ]]; then
        echo "error: ensure that a package exists in your local directory, or provide a package path as an argument" >&2
        exit 1
    fi
    echo "warn: found package: $FOUND_PACKAGE" >&2
    PACKAGE="$FOUND_PACKAGE"
fi

if [[ ! -f $PACKAGE ]]; then
    echo "error: package does not exist: $PACKAGE" >&2
    exit 1
fi

echo "[deploy] cleaning up old packages"
ssh -i ~/.ssh/quemot-dev.pem ubuntu@quemot.dev <<EOF
cd /home/ubuntu
rm -rf ./package ./package*.tar.gz
df -h /
EOF

ATTEMPTS=0
SUCCESS=1
while [[ $ATTEMPTS -lt 10 && $SUCCESS -ne 0 ]]; do
    echo "[deploy] attempting transfer ($(($ATTEMPTS+1)))"
    rsync -P -e "ssh -i ~/.ssh/quemot-dev.pem" "$PACKAGE" ubuntu@quemot.dev:/home/ubuntu
    SUCCESS=$?
    echo $SUCCESS
    if [[ $SUCCESS -ne 0 ]]; then
        ((ATTEMPTS+=1))
    fi
done

if [[ $SUCCESS -ne 0 ]]; then
    echo "error: file copy failed after $ATTEMPTS attempts" >&2
    exit 1
fi

echo "[deploy] attempting setup on remote machine"
PACKAGE_NAME=$(basename "$PACKAGE")
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

cd /home/ubuntu
tar xvf "$PACKAGE_NAME" && (rm "$PACKAGE_NAME")
validate "failed to extract & remove package $PACKAGE_NAME"

IMAGES=('notes-api/auth' 'notes-api/auth-db' 'notes-api/auth-init' 'notes-api/api')
for I in \${IMAGES[@]}; do
    FILENAME="\$(echo \$I | tr '/' '_').tar.gz"
    cat "./package/\$FILENAME" | sudo docker load
    validate "failed to load notes-api/\$I image"
    rm "./package/\$FILENAME"
done
EOF