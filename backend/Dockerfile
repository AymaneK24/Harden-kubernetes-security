FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

# no "npm run build" for backend apps
# ---- Stage 2: Run ----
FROM node:20-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app ./app

USER appuser

EXPOSE 3500


CMD ["node", "app/index.js"]
