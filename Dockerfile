FROM rust:1.85-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    build-essential \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./gerador_readme ./gerador_readme

WORKDIR /app/gerador_readme
RUN cargo build --release && \
    chmod +x ./target/release/gerador_readme

WORKDIR /app
RUN echo '#!/bin/sh\n/app/gerador_readme/target/release/gerador_readme --prompt "$PROMPT"' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
