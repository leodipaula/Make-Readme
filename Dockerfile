# Dockerfile para gerar README.md com IA via Hugging Face e GitHub
FROM rust:1.85-slim

# Install only required dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    build-essential \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only necessary files
COPY ./gerador_readme ./gerador_readme

# Build Rust binary
WORKDIR /app/gerador_readme
RUN cargo build --release && \
    chmod +x ./target/release/gerador_readme

# Create wrapper script
WORKDIR /app
RUN echo '#!/bin/sh\n/app/gerador_readme/target/release/gerador_readme --prompt "$PROMPT"' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Set the entry point to use the wrapper script
ENTRYPOINT ["/app/entrypoint.sh"]
