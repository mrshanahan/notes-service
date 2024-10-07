#!/bin/bash

# ./build.sh --hostname <hostname> --https-cert-path <cert-path> --https-key-path <key-path>

# HTTPS_HOSTNAME="auth.quemot.dev"
# HTTPS_CERT_PATH="cert.pem"
# HTTPS_KEY_PATH="key.pem"

validate() {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

echo "[build.sh] building service images" >&2
docker compose -f ./docker-compose.yml build --no-cache
validate "failed to build service images"

echo "[build.sh] building initialization image" >&2
docker build auth-init -t notes-api/auth-init --no-cache
validate "failed to build auth-init image"

echo "[build.sh] saving notes-api/auth image" >&2
docker save notes-api/auth -o ./notes-api_auth.tar.gz
validate "failed to save notes-api/auth image"

echo "[build.sh] saving notes-api/auth-db image" >&2
docker save notes-api/auth-db -o ./notes-api_auth-db.tar.gz
validate "failed to save notes-api/auth-db image"

echo "[build.sh] saving notes-api/auth-init image" >&2
docker save notes-api/auth-init -o ./notes-api_auth-init.tar.gz
validate "failed to save notes-api/auth-init image"

if [ -d "./package" ]; then
    rm -rf ./package
fi
mkdir ./package
cp -r ./notes-api_auth.tar.gz ./notes-api_auth-db.tar.gz ./notes-api_auth-init.tar.gz ./docker-compose.yml ./package
validate "failed to copy container files to package"

cp -r ./package-scripts ./package/scripts
validate "failed to copy script files to package"

PACKAGE="./package_$(date +%Y%m%d%H%M%S).tar.gz"
echo "[build.sh] compressing package -> $PACKAGE" >&2
tar czvf "$PACKAGE" ./package
validate "failed to create package tarball"

echo "[build.sh] cleaning up package directory" >&2
#rm -rf ./package ./notes-api_auth.tar.gz ./notes-api_auth-db.tar.gz ./notes-api_auth-init.tar.gz
rm -rf ./package ./notes-api_auth.tar.gz ./notes-api_auth-db.tar.gz ./notes-api_auth-init.tar.gz