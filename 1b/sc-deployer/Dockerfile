FROM ghcr.io/foundry-rs/foundry:stable

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Otherwise, the installation below will fail
USER root

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (using NodeSource repository for latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user to avoid permission issues
RUN useradd -m -s /bin/bash deployer && \
    mkdir -p /app && \
    chown -R deployer:deployer /app

# Set working directory
WORKDIR /app

# Switch to non-root user
USER deployer

# Ensure npm cache has correct permissions
RUN mkdir -p ~/.npm && \
    npm config set cache ~/.npm
