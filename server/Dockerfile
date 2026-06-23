# ---- build stage: compile the Dart server to a native executable ----
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/bin/server

# ---- runtime stage: tiny image with just the binary + sqlite + litestream ----
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends libsqlite3-0 sqlite3 ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*
# Litestream: streams goalverse.db to an S3 bucket so data survives a host with
# no persistent disk (Render free tier). Only active when LITESTREAM_* env vars
# are set; otherwise the entrypoint runs the plain server (local / docker-compose).
ARG LITESTREAM_VERSION=0.3.13
RUN wget -qO /tmp/litestream.tar.gz \
      "https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64.tar.gz" \
    && tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz \
    && rm /tmp/litestream.tar.gz
WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server
# Seed schedule, copied into the data volume on first start (entrypoint).
COPY --from=build /app/data/fixtures.json /app/seed/fixtures.json
COPY litestream.yml /etc/litestream.yml
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8787
ENV PORT=8787
ENTRYPOINT ["/app/docker-entrypoint.sh"]
