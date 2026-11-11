FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

COPY conf/mdb.cnf /etc/mysql/mariadb.conf.d/mdb.cnf
COPY tools/entrypoint.sh /usr/local/bin/mariadb-entrypoint

RUN chmod 755 /usr/local/bin/mariadb-entrypoint && \
    mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint"]