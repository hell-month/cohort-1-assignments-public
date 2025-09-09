#!/bin/sh

docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/hell-month/foundry:latest --push .