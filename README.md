# Authentication container

This folder contains the components for running Keycloak with the Notes API.

There are no secrets at build time. Instead, running `build.sh` will build a package to be deployed to a server via `deploy.sh`. Then the service can be set up manually.

- All TLS configuration should be done via TLS termination on the host. The auth service hosts over HTTP.
- The image is built & the service spun up via the [docker-compose config file](./docker-compose.yml).

# TODO:

- Enable notes realm
- Disable user registration on "Login screen customization"
    - Can't have randos creating accounts
- Try to make full name not required, plus just make email == username
- Create notes-api client
    o Just device auth