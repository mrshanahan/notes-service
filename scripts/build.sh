#!/bin/bash

validate() {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

GIT_SHA=$(git rev-parse HEAD)

echo "[build.sh] building auth service images" >&2
GIT_SHA=$GIT_SHA docker compose -f "$SCRIPT_DIR/../docker-compose-auth.yml" build --no-cache
validate "failed to build auth service images"

echo "[build.sh] building api service images" >&2
GIT_SHA=$GIT_SHA docker compose -f "$SCRIPT_DIR/../docker-compose-api.yml" build --no-cache
validate "failed to build api service images"

echo "[build.sh] building auth CLI image" >&2
docker build auth-cli -t notes-api/auth-cli --build-arg GIT_SHA=$GIT_SHA --no-cache
validate "failed to build auth-cli image"
