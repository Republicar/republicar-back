#!/bin/bash
set -e

echo "🐳 Building/Starting Docker services..."
docker-compose up -d --build api

echo "🔍 Running lint-staged inside Docker..."
docker-compose exec -T api pnpm lint-staged

echo "🧪 Running tests inside Docker..."
docker-compose exec -T api pnpm test

echo "📝 Starting commitizen inside Docker..."
# We use 'run' here to ensure we can attach interactively and mount the gitconfig
# We mount the user's gitconfig so the commit has the correct author
docker-compose run --rm -it \
  -v "$HOME/.gitconfig:/root/.gitconfig" \
  api pnpm commit
