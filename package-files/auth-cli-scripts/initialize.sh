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

./kcadm.sh get realms/notes --fields id >&2
EXIT_CODE=$?
if [[ $EXIT_CODE -eq 1 ]]; then
    echo "[notes-api] creating notes realm" >&2
    ./kcadm.sh create realms -s realm=notes -s enabled=true -s ssoSessionIdleTimeout=1209600 -s ssoSessionMaxLifespan=2592000 >&2
    validate "error: failed to create realm (exit code: $?)"
    ./kcadm.sh 
elif [[ $EXIT_CODE -eq 0 ]]; then
    echo "[notes-api] notes realm already exists; skipping" >&2
else
    echo "[notes-api] error: failed to retrieve notes realm (exit code: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi

CLIENTS=(notes-api notes-cli notes-web)
for CLIENT_NAME in ${CLIENTS[@]}; do
    CLIENT="$(./kcadm.sh get clients -q "clientId=$CLIENT_NAME" -r notes --fields id --format csv --noquotes)"
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 && "$CLIENT" == "" ]]; then
        echo "[notes-api] creating $CLIENT_NAME client in notes realm" >&2
        if [[ ! -f "./$CLIENT_NAME-client.json" ]]; then
            echo "error: could not find file for client $CLIENT_NAME" >&2
            exit 1
        fi
        cat ./$CLIENT_NAME-client.json | ./kcadm.sh create clients -r notes -f - >&2
        if [[ $? -ne 0 ]]; then
            exit $?
        fi
        CLIENT="$(./kcadm.sh get clients -q "clientId=$CLIENT_NAME" -r notes --fields id --format csv --noquotes)"
        validate "failed to retrieve created $CLIENT_NAME client"
        echo $CLIENT
    elif [[ $EXIT_CODE -eq 0 ]]; then
        echo "[notes-api] $CLIENT_NAME client already exists; skipping" >&2
        echo $CLIENT
    else
        echo "[notes-api] error: failed to retrieve $CLIENT_NAME client (exit code: $EXIT_CODE)" >&2
        exit $EXIT_CODE
    fi
done

# TODO: Create notes-cli client w/just device auth
# TODO: Enable notes realm
# TODO: Enable user registration on login screen