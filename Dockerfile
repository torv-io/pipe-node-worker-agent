FROM alpine:latest

# deps for nvm, node, npm, jq
RUN apk add --no-cache bash curl git python3 make g++ jq nodejs npm

ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

WORKDIR /app

COPY package.json ./
RUN npm install || true

# Placeholders for @pipe packages (symlinked at runtime from bootstrap)
RUN mkdir -p node_modules/@pipe/shared node_modules/@pipe/node-sdk

COPY index.js bootstrap.sh ./
RUN chmod +x bootstrap.sh

CMD ["./bootstrap.sh"]
