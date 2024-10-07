#!/usr/bin/env bash
if [[ "$1" == "" ]]; then
    echo "error: expected argument for KC_URL, got none" >&2
    exit -1
fi
docker run -v secrets:/etc/secrets -e KC_URL="$1" --rm notes-api/auth-init