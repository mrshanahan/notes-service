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
    KC_URL="https://auth.notes.quemot.dev"
    echo "warn: KC_URL not provided, using default '$KC_URL'" >&2
fi

cd /opt/keycloak/bin
./kcadm.sh config credentials --server "$KC_URL" --user "$KC_ADMIN_USERNAME" --password "$KC_ADMIN_PASSWORD" --realm master
validate "failed to configure KC credentials"

./kcadm.sh get realms/notes --fields id >&2
EXIT_CODE=$?
if [[ $EXIT_CODE -eq 1 ]]; then
    echo "[notes-api] creating notes realm" >&2
    ./kcadm.sh create realms -s realm=notes >&2
    validate "error: failed to create realm (exit code: $?)"
elif [[ $EXIT_CODE -eq 0 ]]; then
    echo "[notes-api] notes realm already exists; skipping" >&2
else
    echo "[notes-api] error: failed to retrieve notes realm (exit code: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi

CLIENT="$(./kcadm.sh get clients -q clientId=notes-api -r notes --fields id --format csv --noquotes)"
EXIT_CODE=$?
if [[ $EXIT_CODE -eq 0 && "$CLIENT" == "" ]]; then
    echo "[notes-api] creating notes-api client in notes realm" >&2
    cat ../default_client.json | ./kcadm.sh create clients -r notes -f - >&2
    if [[ $? -ne 0 ]]; then
        exit $?
    fi
    CLIENT="$(./kcadm.sh get clients -q clientId=notes-api -r notes --fields id --format csv --noquotes)"
    validate "failed to retrieve created notes-api client client"
    echo $CLIENT
elif [[ $EXIT_CODE -eq 0 ]]; then
    echo "[notes-api] notes-api client already exists; skipping" >&2
    echo $CLIENT
else
    echo "[notes-api] error: failed to retrieve notes-api client (exit code: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi

