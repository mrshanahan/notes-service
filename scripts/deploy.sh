#!/bin/bash

# ./deploy.sh ./package_X.tar.gz

S3_BUCKET_PATH="quemot-dev-bucket"

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

PACKAGE_NAME="$(basename "$PACKAGE")"
aws s3 cp "$PACKAGE" "s3://$S3_BUCKET_PATH"
if [[ $? -ne 0 ]]; then
    echo "error: upload of $PACKAGE to S3 bucket $S3_BUCKET_PATH failed" >&2
    exit 1
fi

echo "[deploy] attempting setup on remote machine"
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

aws s3 cp "s3://$S3_BUCKET_PATH/$PACKAGE_NAME" .
validate "failed to download package s3://$S3_BUCKET_PATH/$PACKAGE_NAME"

cd /home/ubuntu
tar xvf "$PACKAGE_NAME" && (rm "$PACKAGE_NAME")
validate "failed to extract & remove package $PACKAGE_NAME"

IMAGES=('notes-api/auth' 'notes-api/auth-db' 'notes-api/auth-cli' 'notes-api/api' 'notes-api/web')
for I in \${IMAGES[@]}; do
    FILENAME="\$(echo \$I | tr '/' '_').tar.gz"
    cat "./package/\$FILENAME" | sudo docker load
    validate "failed to load notes-api/\$I image"
    rm "./package/\$FILENAME"
done
EOF