FROM node:22-alpine AS base

RUN apk add --no-cache git python3 make g++ && \
    git config --system --add safe.directory /app

# Install pnpm
ENV PNPM_HOME="/pnpm"
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV IN_DOCKER=true
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

FROM base AS dependencies
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

FROM base AS development
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
# Expose port (optional, but good practice)
EXPOSE 3000
CMD [ "pnpm", "start:dev" ]

FROM base AS build
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN pnpm run build
RUN pnpm prune --prod

FROM base AS production
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
# Copy package.json if needed for scripts, though usually node dist/main is enough
COPY package.json ./

EXPOSE 3000
CMD [ "node", "dist/main" ]
