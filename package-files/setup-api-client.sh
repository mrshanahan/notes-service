#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

if [[ "$1" == "" ]]; then
    echo "error: expected argument for KC_URL, got none" >&2
    exit -1
fi
KC_URL="$1"

VOLUME=$(ensure_secrets_volume)

wait-for-ok "$KC_URL"

SCRIPT=$(cat <<EOF
cp -r /auth-cli-scripts/* .
chmod a+x ./initialize.sh
./initialize.sh
EOF
)
CLIENT=$(echo "$SCRIPT" | docker run -i --mount "type=volume,source=$VOLUME,target=/secrets,volume-subpath=auth" -v "$SCRIPT_DIR/auth-cli-scripts:/auth-cli-scripts" -e KC_URL="$KC_URL" --rm notes-api/auth-cli)
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