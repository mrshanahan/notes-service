# Copied from: https://www.keycloak.org/server/containers
FROM quay.io/keycloak/keycloak:latest as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure database
ENV KC_DB postgres

# Configure HTTPS
# ARG HTTPS_HOSTNAME
# ARG HTTPS_CERT_PATH
# ARG HTTPS_KEY_PATH

# ADD $HTTPS_CERT_PATH /opt/keycloak/conf/cert.pem
# ADD $HTTPS_KEY_PATH /opt/keycloak/conf/privkey.pem
# ENV KC_HOSTNAME=$HTTPS_HOSTNAME
# ENV KC_HTTPS_CERTIFICATE_FILE=/opt/keycloak/conf/cert.pem
# ENV KC_HTTPS_CERTIFICATE_KEY_FILE=/opt/keycloak/conf/privkey.pem

WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
# RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/
ADD --chmod=755 ./start.sh /opt/keycloak
# ADD ./default_realm.json /opt/keycloak

# ENV KC_HOSTNAME notes.quemot.dev
ENTRYPOINT ["bash", "/opt/keycloak/start.sh"]
