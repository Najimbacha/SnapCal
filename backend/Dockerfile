# Pinned minor, not :latest — a base image that moves under you is a
# production change nobody reviewed.
FROM node:20.17-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:20.17-alpine
ENV NODE_ENV=production
WORKDIR /app

# Run unprivileged. The node image ships a `node` user for exactly this.
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .
USER node

EXPOSE 3000

# The platform's own health probe hits this; keeping it in the image means a
# container that cannot serve /health never receives traffic.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT:-3000}/health || exit 1

CMD ["node", "server.js"]
