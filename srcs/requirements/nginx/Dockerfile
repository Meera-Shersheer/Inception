FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl \
    && rm -rf /var/lib/apt/lists/* 

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY html/index.html /var/www/html/index.html

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/C=JO/ST=Amman/L=Amman/O=42/OU=Inception/CN=mshershe.42.fr" \
        -addext "subjectAltName=DNS:mshershe.42.fr" \
        -addext "basicConstraints=critical,CA:FALSE" 

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]

