#!/usr/bin/env bash

load_secret() {
    if [[ ! -f "/etc/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/etc/secrets/$1"
}

POSTGRES_USER=$(load_secret "db_username")
POSTGRES_PASSWORD=$(load_secret "db_password")

POSTGRES_USER="$POSTGRES_USER" POSTGRES_PASSWORD="$POSTGRES_PASSWORD" docker-entrypoint.sh "$@"