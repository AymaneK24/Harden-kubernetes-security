FROM node:20-alpine

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --omit=dev

# Copy the rest of the app
COPY --chown=appuser:appgroup . .

ENV NODE_OPTIONS=--openssl-legacy-provider

# Create writable cache before switching user
RUN mkdir -p /app/node_modules/.cache && chmod -R 777 /app/node_modules/.cache

# Switch to non-root user
USER appuser


# Expose the port your app runs on
EXPOSE 3000

# Start the app
CMD ["npm", "start"]