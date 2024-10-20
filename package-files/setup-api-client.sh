#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

if [[ "$1" == "" ]]; then
    echo "error: expected argument for KC_URL, got none" >&2
    exit -1
fi

VOLUME=$(ensure_secrets_volume)

CLIENT=$(docker run --mount "type=volume,source=$VOLUME,target=/secrets,volume-subpath=auth" -e KC_URL="$1" --rm notes-api/auth-init)
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "error: failed to initialize auth or retrieve initialization info (code: $EXIT_CODE)" >&2
    exit -1
fi

SERVICE="api"
CLIENT_ID="$CLIENT" "$SCRIPT_DIR/set-secret.sh" "$SERVICE" CLIENT_ID
if [[ $? -ne 0 ]]; then
    echo "error: failed to set client ID secret for $SERVICE service" >&2
    exit -1
fi