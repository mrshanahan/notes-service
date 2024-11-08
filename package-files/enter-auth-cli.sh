#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

KC_ADMIN_URL="https://auth-admin.notes.quemot.dev"
if [[ "$1" != "" ]]; then
    KC_ADMIN_URL="$1"
fi

VOLUME=$(ensure_secrets_volume)

docker run -it \
    --mount "type=volume,source=$VOLUME,target=/secrets,volume-subpath=auth" \
    -v "$SCRIPT_DIR/auth-cli-scripts:/auth-cli-scripts" \
    -e KC_ADMIN_URL="$KC_ADMIN_URL" --rm notes-api/auth-cli