#!/bin/bash
set -e

# Source nvm
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Parse input JSON
INPUT=$(cat)
CODE=$(echo "$INPUT" | jq -r '.code')
CONTEXT=$(echo "$INPUT" | jq -r '.context')
STAGE_CONFIG=$(echo "$INPUT" | jq -r '.stageConfig // "{}"')

# Parse stage config
NODE_VERSION=$(echo "$STAGE_CONFIG" | jq -r '.nodeVersion // empty')
DEPENDENCIES=$(echo "$STAGE_CONFIG" | jq -r '.dependencies // {}')

# Create work directory
WORK_DIR="/tmp/stage-$(date +%s)-$$"
mkdir -p "$WORK_DIR"

# Cleanup on exit
trap "rm -rf $WORK_DIR" EXIT

# Switch to required node version
if [ -n "$NODE_VERSION" ]; then
  MAJOR_VERSION=$(echo "$NODE_VERSION" | grep -oE '[0-9]+' | head -1)
  nvm install "$MAJOR_VERSION" && nvm use "$MAJOR_VERSION"
else
  nvm install 20 && nvm use 20
fi

# Install runtime dependencies if any
if [ "$DEPENDENCIES" != "{}" ] && [ "$DEPENDENCIES" != "null" ]; then
  # Filter out @pipe/* packages (already provided)
  RUNTIME_DEPS=$(echo "$DEPENDENCIES" | jq 'with_entries(select(.key | startswith("@pipe/") | not))')
  
  if [ "$RUNTIME_DEPS" != "{}" ] && [ "$RUNTIME_DEPS" != "null" ]; then
    echo "$RUNTIME_DEPS" | jq '{name: "stage-dependencies", version: "1.0.0", dependencies: .}' > "$WORK_DIR/package.json"
    npm install --production --no-audit --no-fund --prefix "$WORK_DIR"
  fi
fi

# Link @pipe/* packages from /app/node_modules to work directory
mkdir -p "$WORK_DIR/node_modules/@pipe"
ln -s /app/node_modules/@pipe/shared "$WORK_DIR/node_modules/@pipe/shared" 2>/dev/null || true
ln -s /app/node_modules/@pipe/node-sdk "$WORK_DIR/node_modules/@pipe/node-sdk" 2>/dev/null || true

# Write stage code
echo "$CODE" > "$WORK_DIR/stage.js"

# Execute stage code via index.js
export WORK_DIR
export CONTEXT
cd /app
node index.js
