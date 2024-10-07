# Authentication container

This folder contains the components for running Keycloak with the Notes API.

There are no secrets at build time. Instead, running `build.sh` will build a package to be deployed to a server via `deploy.sh`. Then the service can be set up manually

- HTTPS (hostname & certificate) configuration is done in the [Dockerfile](./Dockerfile).
- Thus you will need 3 pieces of information to build this image:
    - Public hostname (e.g. `foobar.com`)
    - Certificate file (can be full chain) for that hostname (e.g. `~/certs/foobar.pem`)
    - Key file for that certificate file (e.g. `~/certs/foobar-key.pem`)
- The image is built & the service spun up via the [docker-compose config file](./docker-compose.yml).
    - Building:

        cp <full-cert-path> ./cert.pem
        cp <full-key-path> ./privkey.pem
        docker compose -f ./docker-compose.yml build --build-arg HTTPS_HOSTNAME=<hostname> --build-arg HTTPS_CERT_PATH=cert.pem --build-arg HTTPS_KEY_PATH=privkey.pem

    - Then it can be spun up:

        KC_DB_PASSWORD=<db-password> KC_ADMIN_PASSWORD=<kc-password> docker compose -f ./docker-compose.yml up -d
