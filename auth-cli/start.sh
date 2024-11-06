load_secret() {
    if [[ ! -f "/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/secrets/$1"
}

validate() {
    ORIG_EXIT_CODE=$?
    if [[ -z "$2" ]]; then
        EXIT_CODE=$ORIG_EXIT_CODE
    else
        EXIT_CODE=$2
    fi

    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: $1" >&2
        exit $EXIT_CODE
    fi
}

KC_ADMIN_USERNAME=$(load_secret "KC_ADMIN_USERNAME")
KC_ADMIN_PASSWORD=$(load_secret "KC_ADMIN_PASSWORD")
if [[ "$KC_URL" == "" ]]; then
    KC_URL="https://auth-admin.notes.quemot.dev"
    echo "warn: KC_URL not provided, using default '$KC_URL'" >&2
fi

cd /opt/keycloak/bin
./kcadm.sh config credentials --server "$KC_URL" --user "$KC_ADMIN_USERNAME" --password "$KC_ADMIN_PASSWORD" --realm master
validate "failed to configure KC credentials"

bash