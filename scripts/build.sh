#!/bin/bash

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

echo "[build.sh] building auth CLI image" >&2
docker build auth-cli -t notes-api/auth-cli --no-cache
validate "failed to build auth-cli image"
