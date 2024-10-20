#!/usr/bin/env bash

load_secret() {
    if [[ ! -f "/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/secrets/$1"
}

POSTGRES_USER=$(load_secret "DB_USERNAME")
POSTGRES_PASSWORD=$(load_secret "DB_PASSWORD")

POSTGRES_USER="$POSTGRES_USER" POSTGRES_PASSWORD="$POSTGRES_PASSWORD" docker-entrypoint.sh "$@"