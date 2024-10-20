#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    USAGE=$(cat << EOF
usage: $(basename "${BASH_SOURCE[0]}") [-f|--force]

    Checks that all secrets needed for the Notes API auth service exist, and if not
    creates them. Secrets that are not present as environment variables in the current
    process will be prompted from the user.

    Options:
        -f|--force      Overwrite all existing secrets.
EOF
    )
    echo "$USAGE" >&2
    exit $1

}

FORCE=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=0
            shift
            ;;
        *)
            echo "error: unrecognized option: $1" >&2
            exit -1
    esac
done

SECRETS=('DB_USERNAME' 'DB_PASSWORD' 'KC_ADMIN_USERNAME' 'KC_ADMIN_PASSWORD')
SERVICE="auth"

for S in ${SECRETS[@]}; do
    "$SCRIPT_DIR/test-secret.sh" "$SERVICE" "$S"
    TEST_RESULT=$?
    if [[ $FORCE -eq 0 || $TEST_RESULT -eq 99 ]]; then
        if ! ("$SCRIPT_DIR/set-secret.sh" "$SERVICE" "$S"); then
            echo "error: failed to set secret for service $SERVICE: $S" >&2
            exit -1
        fi
    elif [[ $TEST_RESULT -ne 0 ]]; then
        echo "error: failed to check service $SERVICE for secret $S" >&2
        exit -1
    fi
done