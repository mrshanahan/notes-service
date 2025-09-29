FROM quay.io/keycloak/keycloak:latest
ARG GIT_SHA

ADD --chmod=755 ./start.sh /opt/keycloak

LABEL dev.quemot.notes.image.sha=$GIT_SHA

ENTRYPOINT ["bash", "/opt/keycloak/start.sh"]