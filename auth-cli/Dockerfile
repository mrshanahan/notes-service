FROM quay.io/keycloak/keycloak:latest

ADD --chmod=755 ./start.sh /opt/keycloak

ENTRYPOINT ["bash", "/opt/keycloak/start.sh"]