# Stage 1 - Build the Flutter Web App
FROM debian:bookworm-slim AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa wget

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support
RUN flutter config --enable-web

# Set up working directory
WORKDIR /app

# Copy source code
COPY . .

# Fetch dependencies and build web
RUN flutter pub get
RUN flutter build web --release

# Stage 2 - Serve the Web App with Nginx
FROM nginx:alpine

# Install wget for health check
RUN apk add --no-cache wget

# Copy built web assets from build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
