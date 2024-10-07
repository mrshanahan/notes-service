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

# EXISTING_AUTH_ID=\$(sudo docker image ls --format '{{ .Repository }},{{ .ID }}' | grep ^notes-api/auth, | cut -d, -f2)
# validate "failed to check for existing docker auth image"
# if [[ "\$EXISTING_AUTH_ID" != "" ]]; then
#     sudo docker image rm "\$EXISTING_AUTH_ID"
#     validate "failed to remove existing docker auth image"
# fi

# EXISTING_AUTHDB_ID=\$(sudo docker image ls --format '{{ .Repository }},{{ .ID }}' | grep ^notes-api/auth-db, | cut -d, -f2)
# validate "failed to check for existing docker auth-db image"
# if [[ "\$EXISTING_AUTHDB_ID" != "" ]]; then
#     sudo docker image rm "\$EXISTING_AUTHDB_ID"
#     validate "failed to remove existing docker auth-db image"
# fi

# EXISTING_AUTHINIT_ID=\$(sudo docker image ls --format '{{ .Repository }},{{ .ID }}' | grep ^notes-api/auth-init, | cut -d, -f2)
# validate "failed to check for existing docker auth-init image"
# if [[ "\$EXISTING_AUTHINIT_ID" != "" ]]; then
#     sudo docker image rm "\$EXISTING_AUTHINIT_ID"
#     validate "failed to remove existing docker auth-init image"
# fi

sudo docker image prune --force
validate "failed to prune old images"

cd /home/ubuntu
tar xvf "$PACKAGE_NAME" && (rm "$PACKAGE_NAME")
validate "failed to extract & remove package $PACKAGE_NAME"

cat ./package/notes-api_auth.tar.gz | sudo docker load
validate "failed to load notes-api/auth image"
rm ./package/notes-api_auth.tar.gz

cat ./package/notes-api_auth-db.tar.gz | sudo docker load
validate "failed to load notes-api/auth-db image"
rm ./package/notes-api_auth-db.tar.gz

cat ./package/notes-api_auth-init.tar.gz | sudo docker load
validate "failed to load notes-api/auth-init image"
rm ./package/notes-api_auth-init.tar.gz
EOF