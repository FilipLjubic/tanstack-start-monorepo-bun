# syntax=docker/dockerfile:1

FROM oven/bun:1-alpine AS base
WORKDIR /app

# -----------------------------------------------------------
# Dependencies stage - cached when package.json files unchanged
# -----------------------------------------------------------
FROM base AS deps

COPY --link bun.lock package.json ./
COPY --link apps/web/package.json ./apps/web/
COPY --link packages/backend/package.json ./packages/backend/
COPY --link packages/logger/package.json ./packages/logger/
COPY --link packages/ui/package.json ./packages/ui/
COPY --link packages/tsconfig/package.json ./packages/tsconfig/

RUN bun install --frozen-lockfile

# -----------------------------------------------------------
# Build stage - copy source and build the app
# -----------------------------------------------------------
FROM deps AS build

ENV NODE_ENV=production

COPY --link . .

RUN bun --filter @starter/web build

# -----------------------------------------------------------
# Production dependencies - prune devDependencies
# -----------------------------------------------------------
FROM base AS prod-deps

COPY --link bun.lock package.json ./
COPY --link apps/web/package.json ./apps/web/
COPY --link packages/backend/package.json ./packages/backend/
COPY --link packages/logger/package.json ./packages/logger/
COPY --link packages/ui/package.json ./packages/ui/
COPY --link packages/tsconfig/package.json ./packages/tsconfig/

RUN bun install --frozen-lockfile --production

# -----------------------------------------------------------
# Production stage - minimal runtime image
# -----------------------------------------------------------
FROM oven/bun:1-distroless AS production

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

WORKDIR /app

COPY --link --from=build /app/apps/web/.output ./apps/web/.output
COPY --link --from=prod-deps /app/node_modules ./node_modules
COPY --link --from=build /app/package.json ./

EXPOSE 3000

CMD ["./apps/web/.output/server/index.mjs"]
