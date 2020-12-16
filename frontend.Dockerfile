FROM node:14
VOLUME ["/build/static", "/build/node_modules"]
WORKDIR /build
COPY src/package.json src/package-lock.json src/package.json src/webpack.mix.js ./
COPY src/resources/ ./resources
COPY src/public/ ./public
COPY scripts/build_frontend.sh .
ENTRYPOINT ["./build_frontend.sh"]
