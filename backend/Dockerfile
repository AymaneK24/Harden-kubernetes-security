FROM node:25-alpine3.21 AS build

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev

COPY . .

FROM node:25-alpine3.21

RUN addgroup -S appgroup -g 1001 && adduser -S appuser -G appgroup -u 1001

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app ./app

USER appuser

EXPOSE 3500

CMD [ "node" , "app/index.js" ]