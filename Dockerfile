FROM alpine:latest

# Install dependencies for nvm, node, npm, and jq
RUN apk add --no-cache bash curl git python3 make g++ jq nodejs npm

# Install nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

WORKDIR /app

# Copy package.json first
COPY package.json ./

# Install dependencies (none for now, but structure is ready)
RUN npm install || true

# Create directory structure for @pipe packages
# These will be populated at runtime if the packages are available
# bootstrap.sh will symlink them if they exist
RUN mkdir -p node_modules/@pipe/shared node_modules/@pipe/node-sdk

# Copy application code
COPY index.js ./
COPY bootstrap.sh ./bootstrap.sh
RUN chmod +x ./bootstrap.sh

# Run via bootstrap script (sources nvm)
CMD ["./bootstrap.sh"]
