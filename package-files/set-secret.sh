#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    USAGE=$(cat << EOF
usage: $(basename "${BASH_SOURCE[0]}") <target-service> <secret> [<secret> ...]

    Creates a file in the docker volume that the Notes service uses for secrets &
    sets its value to the value of the given environment variable.

    <target-service>    Required. Name of the service which will use the secret. Each service
                        will have a subdirectory in the secrets volume.
    <secret>            Required. Name of the secret to write. This will be the filename of
                        secret, and the value will be pulled from an environment variable
                        of the same name or prompted from the user if the environment variable
                        does not exist. Multiple secrets can be specified.
    
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

while [[ $# -gt 0 ]]; do
    SECRET_NAME="$1"
    if [[ -z "$SECRET_NAME" ]]; then
        echo "error: expected secret name" >&2
        exit -1
    fi

    # Resolving the env variable below will also resolve any variable
    # used by this script, so we at least prevent silly behavior.
    if [[ "$SECRET_NAME" == "SECRET_NAME" || "$SECRET_NAME" == "1" ]]; then
        echo "error: thought you were tricky, huh? pick a different name!" >&2
        exit -1
    fi

    if ! (echo "$SECRET_NAME" | grep -iq '^[a-z0-9_\-]\+$'); then
        echo "error: invalid variable name: $SECRET_NAME"
        exit -1
    fi

    get_envvar_or_input "$SECRET_NAME"

    VAR_VALUE="${!SECRET_NAME}"

    VOLUME_NAME=$(ensure_secrets_volume)

    SCRIPT=$(cat <<EOF
    mkdir -p "/secrets/\$TARGET_SERVICE" && echo "\$VAR_VALUE" >"/secrets/\$TARGET_SERVICE/\$SECRET_NAME"
EOF
    )

    echo $SCRIPT |
        TARGET_SERVICE=$TARGET_SERVICE VAR_VALUE=$VAR_VALUE SECRET_NAME=$SECRET_NAME \
        docker run -e TARGET_SERVICE -e VAR_VALUE -e SECRET_NAME -i --rm --mount "src=$VOLUME_NAME,dst=/secrets" alpine

    shift
done