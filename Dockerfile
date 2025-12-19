# syntax=docker/dockerfile:1

FROM oven/bun:1-debian AS base
RUN apt-get update && apt-get install -y python3 build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# -----------------------------------------------------------
# Dependencies stage - cached when package.json files unchanged
# -----------------------------------------------------------
FROM base AS deps

COPY bun.lock package.json ./
COPY apps/web/package.json ./apps/web/
COPY packages/backend/package.json ./packages/backend/
COPY packages/logger/package.json ./packages/logger/
COPY packages/ui/package.json ./packages/ui/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN bun install --frozen-lockfile

# -----------------------------------------------------------
# Build stage - copy source and build the app
# -----------------------------------------------------------
FROM deps AS build

COPY . .

RUN bun --filter @starter/web build

# -----------------------------------------------------------
# Production stage - minimal runtime image
# -----------------------------------------------------------
FROM oven/bun:1-distroless AS production

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

WORKDIR /app

COPY --from=build /app/apps/web/.output ./apps/web/.output

EXPOSE 3000

CMD ["bun", "run", "./apps/web/.output/server/index.mjs"]
