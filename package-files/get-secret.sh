#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    USAGE=$(cat << EOF
usage: $(basename "${BASH_SOURCE[0]}") <target-service> [<secret> ...]

    Reads a file in the docker volume that the Notes service uses for secrets.

    <target-service>    Required. Name of the service which will use the secret. Each service
                        will have a subdirectory in the secrets volume.
    <secret>            Optional. Name of the secret to read. This will be the filename of
                        secret. Multiple secrets can be specified. If none are specified then
                        all current secrets are listed (but their contents are not).
    
    Both service names & secret names can only be composed of letters, numbers, dashes, and underscores.
    This means that a service name shouldn't be something like "notes-api/api" but just "api".
EOF
    )
    echo "$USAGE" >&2
    exit $1
}

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi

TARGET_SERVICE="$1"
if ! (echo "$TARGET_SERVICE" | grep -iq '^[a-z0-9_\-]\+$'); then
    echo "error: invalid service name: $TARGET_SERVICE"
    exit -1
fi

shift

if [[ $# -eq 0 ]]; then
    VOLUME_NAME=$(ensure_secrets_volume)

    SCRIPT=$(cat <<EOF
    SECRET_DIR="/secrets/\$TARGET_SERVICE"
    if [[ -d "\$SECRET_DIR" ]]; then
        ls -1 "\$SECRET_DIR"
    else
        exit 99
    fi
EOF
    )

    echo "$SCRIPT" |
        TARGET_SERVICE=$TARGET_SERVICE \
        docker run -e TARGET_SERVICE -i --rm --mount "src=$VOLUME_NAME,dst=/secrets" alpine

    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 99 ]]; then
        echo "error: service $TARGET_SERVICE is not registered for secrets" >&2
        exit -1
    elif [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: failed to read secrets for service $TARGET_SERVICE" >&2
        exit -1
    fi
else
    while [[ $# -gt 0 ]]; do
        SECRET_NAME="$1"
        if [[ -z "$SECRET_NAME" ]]; then
            echo "error: expected environment variable name" >&2
            exit -1
        fi

        # Resolving the env variable below will also resolve any variable
        # used by this script, so we at least prevent silly behavior.
        if [[ "$SECRET_NAME" == "SECRET_NAME" || "$SECRET_NAME" == "1" ]]; then
            echo "error: thought you were tricky, huh? pick a different name!" >&2
            exit -1
        fi

        if ! (echo "$SECRET_NAME" | grep -iq '^[a-z0-9_\-]\+$'); then
            echo "error: invalid secret name: $SECRET_NAME"
            exit -1
        fi

        VOLUME_NAME=$(ensure_secrets_volume)

        SCRIPT=$(cat <<EOF
    SECRET_FILE="/secrets/\$TARGET_SERVICE/\$SECRET_NAME"
    if [[ -f "\$SECRET_FILE" ]]; then
        cat "\$SECRET_FILE"
    else
        exit 1
    fi
EOF
        )

        echo "$SCRIPT" |
            TARGET_SERVICE=$TARGET_SERVICE SECRET_NAME=$SECRET_NAME \
            docker run -e TARGET_SERVICE -e SECRET_NAME -i --rm --mount "src=$VOLUME_NAME,dst=/secrets" alpine

        EXIT_CODE=$?
        if [[ $EXIT_CODE -eq 1 ]]; then
            echo "error: secret not found for service $TARGET_SERVICE: $SECRET_NAME" >&2
            exit -1
        elif [[ $EXIT_CODE -ne 0 ]]; then
            echo "error: failed to read secret $SECRET_NAME for service $TARGET_SERVICE" >&2
            exit -1
        fi

        shift
    done
fi