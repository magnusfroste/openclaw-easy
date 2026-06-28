# Custom OpenClaw image for Easypanel.
#
# Builds on top of the upstream OpenClaw image and bakes in a baseline of
# tools so the agent has a stable environment that survives redeploys. The
# container also runs as root (see docker-compose.yml), so the agent can
# still apt/pip/npm-install extra packages ad-hoc at runtime.
#
# Bump the base by changing OPENCLAW_IMAGE in the Easypanel env panel and
# redeploying — Easypanel rebuilds this image and pulls the new base.
ARG OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
FROM ${OPENCLAW_IMAGE}

USER root

# Baseline tooling (Debian 12 / bookworm base).
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        build-essential \
        python3 python3-pip python3-venv python3-dev \
        git \
        ripgrep \
        curl wget ca-certificates \
        jq unzip zip \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

# uv (fast Python package/installer). bookworm enforces PEP 668, so allow the
# system-wide install explicitly; fall back to the official installer.
RUN pip3 install --no-cache-dir --break-system-packages uv \
    || (curl -LsSf https://astral.sh/uv/install.sh | sh)

# Pre-install Playwright's Chromium + its system libraries so the agent can
# browse immediately. The image ships playwright-core but not the browser, and
# the cache dir is not a mounted volume, so baking it in is what makes browsing
# survive redeploys. PLAYWRIGHT_BROWSERS_PATH is set so the runtime (root) finds
# the same install.
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN node /app/node_modules/playwright-core/cli.js install --with-deps chromium \
    && rm -rf /var/lib/apt/lists/*

# Passwordless sudo for the unprivileged node user, in case the container is
# ever run as node instead of root.
RUN echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node
