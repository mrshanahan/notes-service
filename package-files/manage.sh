#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    cat >&2 << EOF
usage: $(basename "${BASH_SOURCE[0]}") <global-options> <command> <sub-options>

    Manages a local Notes API service.

    Global options:
        -h|--help               Show usage information & exit.
        -p|--port               Port at which the auth service should be/is hosted. Defaults to 8080.

    Commands:
        setup-auth-service      Performs any necessary setup for the auth service. Fully idempotent.

        check-auth-secrets      Validates that all required secrets used by the auth service are present.

        reset-auth-secrets      Fully resets all secrets used by the auth service.

        setup-api-client        Sets up the API client on the running auth service.
            Options:
                -u|--auth-url       URL at which the auth service is hosted. Defaults to https://auth.notes.quemot.dev.
        
        docker-compose,dc       Passes through the remaining arguments to docker-compose using the auth service as the context.
EOF
    exit 0
}

if [[ -z "$1" ]]; then
    usage
fi

DEFAULT_AUTH_URL="https://auth.notes.quemot.dev"
DEFAULT_AUTH_PORT=8080

AUTH_PORT=$DEFAULT_AUTH_PORT
case "$1" in
    -h|--help)
        usage
        ;;
    -p|--port)
        if [[ ! -z "$2" ]]; then
            if [[ $2 == +([[:digit:]]) ]] && [[ $2 -gt 0 ]]; then
                AUTH_PORT="$2"
            else
                echo "error: invalid value for port (expecting positive integer): $2" >&2
                exit -1
            fi
        fi
        ;;
    setup-auth-service)
        "$SCRIPT_DIR/setup-auth-secrets.sh"
        "$SCRIPT_DIR/ensure-volume.sh" kc-data
        ;;
    check-auth-secrets)
        "$SCRIPT_DIR/check-auth-secrets.sh"
        ;;
    reset-auth-secrets)
        "$SCRIPT_DIR/setup-auth-secrets.sh" --force
        ;;
    setup-api-client)
        URL=$DEFAULT_AUTH_URL
        if [[ ! -z "$2" ]]; then
            case "$2" in
                -u|--auth-url)
                    URL="$3"
                    ;;
                *)
                    echo "error: unrecognized argument '$2'" >&2
                    exit -1
                    ;;
            esac
        fi
        "$SCRIPT_DIR/setup-api-client.sh" "$URL"            
        ;;
    docker-compose|dc)
        shift
        KC_PORT=$AUTH_PORT docker compose -f "$SCRIPT_DIR/docker-compose.yml" $*
        ;;
    -*)
        echo "error: unrecognized option: $1" >&2
        exit -1
        ;;
    *)
        echo "error: unrecognized command: $1" >&2
        exit -1
esac

