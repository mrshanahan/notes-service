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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "[build.sh] building auth service images" >&2
docker compose -f "$SCRIPT_DIR/../docker-compose-auth.yml" build --no-cache
validate "failed to build auth service images"

echo "[build.sh] building api service images" >&2
docker compose -f "$SCRIPT_DIR/../docker-compose-api.yml" build --no-cache
validate "failed to build api service images"

echo "[build.sh] building initialization image" >&2
docker build auth-init -t notes-api/auth-init --no-cache
validate "failed to build auth-init image"

IMAGES=('notes-api/auth' 'notes-api/auth-db' 'notes-api/auth-init' 'notes-api/api')
for I in ${IMAGES[@]}; do
    FILENAME="$(echo $I | tr '/' '_').tar.gz"
    echo "[build.sh] saving $I image" >&2
    docker save "$I" -o "./$FILENAME"
    validate "failed to save $I image"
done

if [ -d "./package" ]; then
    rm -rf ./package
fi
mkdir ./package
cp -r ./notes-api_*.tar.gz ./docker-compose*.yml ./package
validate "failed to copy container files to package"

cp -r ./package-files/* ./package
validate "failed to copy static files to package"

PACKAGE="./package_$(date +%Y%m%d%H%M%S).tar.gz"
echo "[build.sh] compressing package -> $PACKAGE" >&2
tar czvf "$PACKAGE" ./package
validate "failed to create package tarball"

echo "[build.sh] cleaning up package directory" >&2
rm -rf ./package ./notes-api_*.tar.gz