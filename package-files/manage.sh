#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/helpers.sh"

usage() {
    cat >&2 << EOF
usage: $(basename "${BASH_SOURCE[0]}") <global-options> <command> <sub-options>

    Manages a local Notes API service.

    Global options:
        -h|--help                   Show usage information & exit.
        --auth-port                 Port at which the auth service should be/is hosted. Defaults to 8080.
        --auth-url                  URL at which the auth service's main application is hosted. Defaults to https://auth.notes.quemot.dev.
        --auth-admin-url            URL at which the auth service's admin features are accessible. Defaults to https://auth-admin.notes.quemot.dev.
        --api-port                  Port at which the api service should be/is hosted. Defaults to 3333.

    Commands:
        start                       Runs the following steps to fully start the service:
                                        setup-auth-service
                                        docker-compose auth up -d
                                        setup-api-service
                                        docker-compose api up -d
        stop                        Runs the following steps to fully stop the service:
                                        docker-compose api down
                                        docker-compose auth down
        auth-cli                    Enter a CLI for interacting with the auth service as admin.
        setup-auth-service          Performs any necessary setup for the auth service. Fully idempotent.
        check-auth-secrets          Validates that all required secrets used by the auth service are present.
        reset-auth-secrets          Fully resets all secrets used by the auth service.
        setup-api-service           Sets up the API client on the running auth service.
        docker-compose,dc <svc>     Passes through the remaining arguments to docker-compose using the given service as the context.

EOF
    exit 0
}

if [[ -z "$1" ]]; then
    usage
fi

auth-cli() {
    "$SCRIPT_DIR/enter-auth-cli.sh" "$1"
}

setup-auth-service() {
    "$SCRIPT_DIR/setup-auth-secrets.sh"
    "$SCRIPT_DIR/ensure-volume.sh" kc-data
}

check-auth-secrets() {
    "$SCRIPT_DIR/check-auth-secrets.sh"
}

reset-auth-secrets() {
    "$SCRIPT_DIR/setup-auth-secrets.sh" --force
}

setup-api-service() {
    "$SCRIPT_DIR/setup-api-client.sh" "$AUTH_URL"
    validate_command "failed to setup API client"
    "$SCRIPT_DIR/ensure-volume.sh" notes-data
}

invoke-docker-compose() {
    if [[ -z "$1" ]]; then
        echo "error: expected service argument for command $1" >&2
        exit -1
    fi

    # https://stackoverflow.com/questions/15691942/print-array-elements-on-separate-lines-in-bash
    SVC=""
    for S in ${SERVICES[@]}; do
        if [[ "$S" == "$1" ]]; then
            SVC="$S"
        fi
    done
    if [[ -z $SVC ]]; then
        echo "error: unrecognized service name: $1" >&2
        exit -1
    fi

    shift

    KC_URL=$AUTH_URL KC_PORT=$AUTH_PORT NOTES_API_PORT=$API_PORT \
        docker compose -f "$SCRIPT_DIR/docker-compose-${SVC}.yml" $*

}

DEFAULT_AUTH_URL="https://auth.notes.quemot.dev"
DEFAULT_AUTH_ADMIN_URL="https://auth-admin.notes.quemot.dev"
DEFAULT_AUTH_PORT=8080
DEFAULT_API_PORT=3333
SERVICES=('auth' 'api')

AUTH_URL=$DEFAULT_AUTH_URL
AUTH_ADMIN_URL=$DEFAULT_AUTH_ADMIN_URL
AUTH_PORT=$DEFAULT_AUTH_PORT
API_PORT=$DEFAULT_API_PORT
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --auth-port)
            if [[ ! -z "$2" ]]; then
                if [[ $2 == +([[:digit:]]) ]] && [[ $2 -gt 0 ]]; then
                    AUTH_PORT="$2"
                else
                    echo "error: invalid value for auth port (expecting positive integer): $2" >&2
                    exit -1
                fi
            else
                echo "error: expected value for auth port" >&2
                exit -1
            fi
            shift
            shift
            ;;
        --auth-url)
            if [[ ! -z "$2" ]]; then
                AUTH_URL="$2"
            else
                echo "error: expected value for auth URL" >&2
                exit -1
            fi
            shift
            shift
            ;;
        --auth-admin-url)
            if [[ ! -z "$2" ]]; then
                AUTH_ADMIN_URL="$2"
            else
                echo "error: expected value for auth admin URL" >&2
                exit -1
            fi
            shift
            shift
            ;;
        --api-port)
            if [[ ! -z "$2" ]]; then
                if [[ $2 == +([[:digit:]]) ]] && [[ $2 -gt 0 ]]; then
                    API_PORT="$2"
                else
                    echo "error: invalid value for api port (expecting positive integer): $2" >&2
                    exit -1
                fi
            else
                echo "error: expected value for api port" >&2
                exit -1
            fi
            shift
            shift
            ;;
        start)
            setup-auth-service
            invoke-docker-compose auth up -d
            validate_command "failed to spin up auth service"
            setup-api-service
            AUTH_URL="$AUTH_URL" API_PORT="$API_PORT" invoke-docker-compose api up -d
            validate_command "failed to spin up api service"
            ;;
        stop)
            invoke-docker-compose api down
            invoke-docker-compose auth down
            ;;
        auth-cli)
            auth-cli $AUTH_ADMIN_URL
            ;;
        setup-auth-service)
            setup-auth-service
            ;;
        check-auth-secrets)
            check-auth-secrets
            ;;
        reset-auth-secrets)
            reset-auth-secrets
            ;;
        setup-api-service)
            setup-api-service
            ;;
        docker-compose|dc)
            shift
            invoke-docker-compose $*
            ;;
        -*)
            echo "error: unrecognized option: $1" >&2
            exit -1
            ;;
        *)
            echo "error: unrecognized command: $1" >&2
            exit -1
    esac
done
