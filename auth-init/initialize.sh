load_secret() {
    if [[ ! -f "/etc/secrets/$1" ]]; then
        echo "error: cannot find secret $1" >&2
        exit 1
    fi
    cat "/etc/secrets/$1"
}

KC_ADMIN_USERNAME=$(load_secret "kc_admin_username")
KC_ADMIN_PASSWORD=$(load_secret "kc_admin_password")
if [[ "$KC_URL" == "" ]]; then
    KC_URL="https://auth.notes.quemot.dev"
    echo "warn: KC_URL not provided, using default '$KC_URL'" >&2
fi

cd /opt/keycloak/bin
./kcadm.sh config credentials --server "$KC_URL" --user "$KC_ADMIN_USERNAME" --password "$KC_ADMIN_PASSWORD" --realm master
if [[ $? -ne 0 ]]; then
    exit $?
fi

./kcadm.sh get realms/notes --fields id
EXIT_CODE=$?
if [[ $EXIT_CODE -eq 1 ]]; then
    echo "[notes-api] creating notes realm" >&2
    ./kcadm.sh create realms -s realm=notes
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "error: failed to create realm (exit code: $EXIT_CODE)" >&2
        exit $EXIT_CODE
    fi
elif [[ $EXIT_CODE -eq 0 ]]; then
    echo "[notes-api] notes realm already exists; skipping" >&2
else
    echo "[notes-api] error: failed to retrieve notes realm (exit code: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi

CLIENT="$(./kcadm.sh get clients -q clientId=notes-api --fields id,clientId --format csv)"
EXIT_CODE=$?
if [[ $EXIT_CODE -eq 0 && "$CLIENT" == "" ]]; then
    echo "[notes-api] creating notes-api client in notes realm" >&2
    cat ../default_client.json | ./kcadm.sh create clients -r notes -f -
    if [[ $? -ne 0 ]]; then
        exit $?
    fi
elif [[ $EXIT_CODE -eq 0 ]]; then
    echo "[notes-api] notes-api client already exists; skipping" >&2
else
    echo "[notes-api] error: failed to retrieve notes-api client (exit code: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi