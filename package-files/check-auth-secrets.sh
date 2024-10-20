#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

SECRETS=('DB_USERNAME' 'DB_PASSWORD' 'KC_ADMIN_USERNAME' 'KC_ADMIN_PASSWORD')
SERVICE="auth"

EXIT=0
for S in ${SECRETS[@]}; do
    if ! ("$SCRIPT_DIR/test-secret.sh" "$SERVICE" "$S"); then
        echo "warn: secret not set for service $SERVICE: $S" >&2
        EXIT=1
    fi
done

exit $EXIT