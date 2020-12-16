FROM caddy/caddy:latest
VOLUME ["/app/public", "/app/public/files"]
COPY ./Caddyfile /etc/caddy/Caddyfile