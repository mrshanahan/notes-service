#!/usr/bin/env bash

validate_envvar() {
    if [[ -z "${!1}" ]]; then
        echo "error: required environment variable unset: $1" >&2
        exit 1
    fi
}

validate_command() {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

validate_envvar "DB_USERNAME"
validate_envvar "DB_PASSWORD"
validate_envvar "KC_ADMIN_USERNAME"
validate_envvar "KC_ADMIN_PASSWORD"

VOLUMES=$(docker volume ls --format '{{ .Name }}')
validate_command "failed to retrieve existing volumes"

if ! (echo "$VOLUMES" | grep -q '^secrets$'); then
    docker volume create secrets
    validate_command "failed to create secrets volume"
fi

MOUNTPOINT=$(docker volume inspect secrets --format '{{ .Mountpoint }}')
validate_command "failed to find mountpoint for secrets volume"

echo "$DB_USERNAME" >"$MOUNTPOINT/db_username" && \
    echo "$DB_PASSWORD" >"$MOUNTPOINT/db_password" && \
    echo "$KC_ADMIN_USERNAME" >"$MOUNTPOINT/kc_admin_username" && \
    echo "$KC_ADMIN_PASSWORD" >"$MOUNTPOINT/kc_admin_password"
validate_command "failed to save secrets"
