FROM quay.io/keycloak/keycloak:latest

ADD --chmod=755 ./initialize.sh /opt/keycloak
ADD ./default_client.json /opt/keycloak

ENTRYPOINT ["bash", "/opt/keycloak/initialize.sh"]