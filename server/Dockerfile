# ---- build stage: compile the Dart server to a native executable ----
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/bin/server

# ---- runtime stage: tiny image with just the binary + sqlite ----
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends libsqlite3-0 sqlite3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server
# Seed schedule, copied into the data volume on first start (entrypoint).
COPY --from=build /app/data/fixtures.json /app/seed/fixtures.json
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8787
ENV PORT=8787
ENTRYPOINT ["/app/docker-entrypoint.sh"]
