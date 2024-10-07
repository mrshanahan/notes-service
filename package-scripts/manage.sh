#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "error: expected command (start, stop)" >&2
    exit -1
fi


case "$1" in
    start)
        PORT=8080
        if [[ ! -z "$KC_PORT" ]]; then
            if [[ $1 == +([[:digit:]]) ]] && [[ $1 -gt 0 ]]; then
                PORT="$KC_PORT"
            else
                echo "error: invalid value for port (expecting positive integer): $1" >&2
                exit 1
            fi
        fi
        KC_PORT=$KC_PORT docker compose -f ./docker-compose.yml up -d
        ;;
    stop)
        KC_PORT=$KC_PORT docker compose -f ./docker-compose.yml down
        ;;
    *)
        echo "error: invalid command: $1" >&2
        exit -1
        ;;
esac
