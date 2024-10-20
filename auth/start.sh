load_secret() {
    if [[ ! -f "/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/secrets/$1"
}

KC_DB_USERNAME=$(load_secret "DB_USERNAME")
KC_DB_PASSWORD=$(load_secret "DB_PASSWORD")
KEYCLOAK_ADMIN=$(load_secret "KC_ADMIN_USERNAME")
KEYCLOAK_ADMIN_PASSWORD=$(load_secret "KC_ADMIN_PASSWORD")

KC_DB_USERNAME="$KC_DB_USERNAME" \
KC_DB_PASSWORD="$KC_DB_PASSWORD" \
KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN" \
KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
/opt/keycloak/bin/kc.sh "$@"