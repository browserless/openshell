# SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
# SPDX-License-Identifier: MIT
#
# Sandbox image for the examples: Node 24 plus the pinned Browserless clients.
#   docker build -t browserless-openshell-examples examples
FROM node:24-bookworm-slim

# Under /usr so OpenShell's default filesystem policy can read it; /opt is not
# readable inside a sandbox unless a custom policy allows it.
WORKDIR /usr/local/lib/browserless-examples
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund
COPY *.mjs ./
RUN chmod -R a+rX /usr/local/lib/browserless-examples

USER node
WORKDIR /sandbox
