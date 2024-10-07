FROM postgres

ADD --chmod=755 ./start.sh /var/lib/postgresql

ENTRYPOINT [ "bash", "/var/lib/postgresql/start.sh" ]
CMD [ "postgres" ]