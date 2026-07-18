# ---------- Base ----------
FROM node:24-slim AS base
RUN corepack enable pnpm

# ---------- Dependencies ----------
FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN pnpm config set verify-store-integrity false \
  && pnpm install --ignore-scripts --no-frozen-lockfile

# ---------- Builder ----------
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Prisma client generation
RUN npx prisma generate

# Next.js build (standalone output)
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

# ---------- Runner ----------
FROM node:24-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root user
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# Copy standalone server
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
