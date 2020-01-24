FROM node:12-alpine

WORKDIR /usr/src/app
RUN chown node:node .

COPY package*.json bower.json .bowerrc ./
RUN apk add --no-cache --virtual .build-tools git && \
    apk add --no-cache tini && \
    npm ci --only=production && \
    echo '{ "allow_root": true }' > /root/.bowerrc && \
    npm run bower && \
    apk del .build-tools

COPY . .

EXPOSE 9980

ENTRYPOINT ["/sbin/tini", "--"]
CMD [ "node", "server.js" ]

USER node
