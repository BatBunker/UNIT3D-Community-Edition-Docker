FROM mariadb:10
COPY scripts/*.sql /docker-entrypoint-initdb.d/