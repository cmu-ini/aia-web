#!/bin/bash
set -euo pipefail

# Install image processing prerequisites (cairosvg, mkdocs-material[imaging])
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    libcairo2-dev libfreetype-dev libffi-dev libjpeg-dev libpng-dev zlib1g-dev
rm -rf /var/lib/apt/lists/*
