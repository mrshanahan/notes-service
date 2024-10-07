load_secret() {
    if [[ ! -f "/etc/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/etc/secrets/$1"
}

KC_DB_USERNAME=$(load_secret "db_username")
KC_DB_PASSWORD=$(load_secret "db_password")
KEYCLOAK_ADMIN=$(load_secret "kc_admin_username")
KEYCLOAK_ADMIN_PASSWORD=$(load_secret "kc_admin_password")

KC_DB_USERNAME="$KC_DB_USERNAME" \
KC_DB_PASSWORD="$KC_DB_PASSWORD" \
KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN" \
KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
/opt/keycloak/bin/kc.sh "$@"