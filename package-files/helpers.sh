#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

validate_command() {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

get_envvar_or_input() {
    if ! (printenv | grep -q "^$1="); then
        # TODO: Validate env var has same value as local var
        if [[ ! -z "${!1}" ]]; then
            echo "error: you were trying to be tricky! don't do that!" >&2
            exit -1
        fi

        while [[ -z "${!1}" || "${!1}" != "$VALIDATION" ]]; do
            while [[ -z "${!1}" ]]; do
                read -s -p "Enter value for $1:   " "$1"
                echo
            done
            while [[ -z "$VALIDATION" ]]; do
                read -s -p "Confirm value for $1: " VALIDATION
                echo
            done
            if [[ "${!1}" != "$VALIDATION" ]]; then
                echo "warn: values did not match; please retry" >&2
                eval "$1=\"\""
                VALIDATION=""
            fi
        done
    fi
}

ensure_volume() {
    VOLUMES=$(docker volume ls --format '{{ .Name }}')
    validate_command "failed to retrieve existing volumes"

    VOLUME_NAME="$1"
    if ! (echo "$VOLUMES" | grep -q "^${VOLUME_NAME}\$"); then
        docker volume create "$VOLUME_NAME" >/dev/null
    fi

    # MOUNTPOINT=$(docker volume inspect "$VOLUME_NAME" --format '{{ .Mountpoint }}')
    # validate_command "failed to find mountpoint for $VOLUME_NAME volume"

    # echo $MOUNTPOINT
}

ensure_secrets_volume() {
    ensure_volume "notes-secrets"
    echo "notes-secrets"
}

wait-for-ok() {
    URL="$1"
    MAX_ATTEMPTS=10
    ATTEMPT=1
    echo "($ATTEMPT/$MAX_ATTEMPTS) attempting to check status of $URL" >&2
    curl -fs "$URL" >/dev/null
    RESULT=$?
    while [[ $RESULT -ne 0 && $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
        sleep 10
        ATTEMPT=$(( $ATTEMPT + 1 ))
        echo "($ATTEMPT/$MAX_ATTEMPTS) attempting to check status of $URL" >&2
        curl -fs "$URL" >/dev/null
        RESULT=$?
    done
    if [[ $RESULT -ne 0 ]]; then
        echo "error: could not get valid HTTP status code from auth url after $MAX_ATTEMPTS" >&2
        exit -1
    fi
}