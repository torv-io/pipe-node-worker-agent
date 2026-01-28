FROM alpine:latest

# Install dependencies for nvm, node, npm, and jq
RUN apk add --no-cache bash curl git python3 make g++ jq nodejs npm

# Install nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

WORKDIR /app

# Copy package.json and install dependencies (including @pipe/* packages from npm)
COPY package.json ./
RUN npm install

# Copy application code
COPY index.js ./
COPY bootstrap.sh ./bootstrap.sh
RUN chmod +x ./bootstrap.sh

# Run via bootstrap script (sources nvm)
CMD ["./bootstrap.sh"]
