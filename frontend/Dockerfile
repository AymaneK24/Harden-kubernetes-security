FROM node:20.19.5-alpine3.22 AS builder

WORKDIR /app

COPY . .

ENV NODE_OPTIONS=--openssl-legacy-provider

RUN npm install

RUN npm run build


FROM nginxinc/nginx-unprivileged:alpine3.22-slim

COPY --from=builder /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf


EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080 || exit 1


CMD [ "nginx", "-g", "daemon off;" ]
