FROM alpine:latest

# Install dependencies for nvm, node, npm, and jq
RUN apk add --no-cache bash curl git python3 make g++ jq nodejs npm

# Install nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

WORKDIR /app

# Install TypeScript for building packages
RUN npm install -g typescript

# Copy and build @pipe/shared (from pipe repo)
COPY pipe/pipe-shared ./packages/shared
WORKDIR /app/packages/shared
RUN npm install && npm run build

# Copy and build @pipe/node-sdk (from pipe repo)
WORKDIR /app
COPY pipe/sdks/node-sdk ./packages/node-sdk
WORKDIR /app/packages/node-sdk
RUN npm install && npm run build

# Install the local packages
WORKDIR /app
RUN npm install ./packages/shared ./packages/node-sdk

# Copy package.json and install other dependencies
COPY pipe-node-worker-agent/package.json ./
RUN npm install

# Create symlinks for @pipe/* namespace (bootstrap.sh expects @pipe/shared and @pipe/node-sdk)
RUN mkdir -p node_modules/@pipe && \
    ln -sf ../@torv-pipe/common node_modules/@pipe/shared && \
    ln -sf ../@torv-pipe/node-sdk node_modules/@pipe/node-sdk

# Copy application code
COPY pipe-node-worker-agent/index.js ./
COPY pipe-node-worker-agent/bootstrap.sh ./bootstrap.sh
RUN chmod +x ./bootstrap.sh

# Run via bootstrap script (sources nvm)
CMD ["./bootstrap.sh"]
