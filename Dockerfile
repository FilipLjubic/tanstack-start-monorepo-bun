# syntax=docker/dockerfile:1

FROM oven/bun:1 AS base
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
FROM base AS production

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

COPY --from=build /app/apps/web/.output ./apps/web/.output
COPY --from=build /app/apps/web/package.json ./apps/web/
COPY --from=build /app/package.json ./

EXPOSE 3000

CMD ["bun", "run", "--filter", "@starter/web", "start"]
