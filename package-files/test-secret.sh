#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    USAGE=$(cat << EOF
usage: $(basename "${BASH_SOURCE[0]}") <target-service> <secret> [<secret> ...]

    Checks that the given secrets exist as files in the docker volume that the Notes service
    uses for secrets. If all are present as files in the appropriate directory, then exits
    with exit code 0; otherwise, exits with non-zero exit code.

    <target-service>    Required. Name of the service which will use the secret. Each service
                        will have a subdirectory in the secrets volume.
    <secret>            Required. Name of the secret to check. Multiple secrets can be specified,
                        and they will be validated with an "AND" operation.
    
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

if [[ $# -lt 2 ]]; then
    echo "error: invalid number of arguments (expect at least 2)" >&2
    usage -1
fi

TARGET_SERVICE="$1"
if ! (echo "$TARGET_SERVICE" | grep -iq '^[a-z0-9_\-]\+$'); then
    echo "error: invalid service name: $TARGET_SERVICE"
    exit -1
fi

shift


VOLUME_NAME=$(ensure_secrets_volume)

SCRIPT=$(cat <<EOF
    ls -1 "/secrets/\$TARGET_SERVICE" 2>/dev/null; exit 0
EOF
)

SECRETS=$(echo $SCRIPT | TARGET_SERVICE=$TARGET_SERVICE docker run -e TARGET_SERVICE -i --rm --mount "src=$VOLUME_NAME,dst=/secrets" alpine)
validate_command "failed to retrieve secrets for service $TARGET_SERVICE"

while [[ $# -gt 0 ]]; do
    VAR_NAME="$1"
    if [[ -z "$VAR_NAME" ]]; then
        echo "error: expected secret name" >&2
        exit -1
    fi

    if ! (echo "$VAR_NAME" | grep -iq '^[a-z0-9_\-]\+$'); then
        echo "error: invalid variable name: $VAR_NAME"
        exit -1
    fi

    if ! (echo "$SECRETS" | grep -qi "^$VAR_NAME$"); then
        exit 99
    fi

    shift
done