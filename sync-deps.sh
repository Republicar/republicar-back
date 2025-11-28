#!/bin/bash
set -e

echo "🔄 Syncing node_modules from Docker to host..."

# We use docker-compose run to spin up a container with the correct image.
# We mount the current directory to /host so we can write to it without being obstructed by the /app/node_modules volume.
# We copy node_modules from /app (container) to /host (host machine).
# We use chown to ensure the files on the host are owned by the current user, not root.

docker-compose run --rm \
  -v "$(pwd):/host" \
  api \
  sh -c "cp -r /app/node_modules /host/ && chown -R $(id -u):$(id -g) /host/node_modules"

echo "✅ Done! node_modules synced to host."
