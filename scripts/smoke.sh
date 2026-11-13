#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
# SPDX-License-Identifier: MIT
#
# The README smoke test as a script. Starts a throwaway sandbox with the given
# provider attached and fetches example.com through Browserless /content. The
# sandbox only ever sees the OpenShell placeholder, never the API key.
#
#   scripts/smoke.sh [provider-name]    (default: browserless)
#
# Needs `openshell` on PATH, connected to a gateway that has the provider.
set -euo pipefail

provider="${1:-browserless}"

# shellcheck disable=SC2016 # ${...} below is JavaScript, evaluated inside the sandbox
out="$(openshell sandbox create --no-keep --from node:24-bookworm-slim --provider "$provider" -- node -e '
  fetch(`https://production-sfo.browserless.io/content?token=${process.env.BROWSERLESS_TOKEN}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ url: "https://example.com" }),
  }).then((r) => r.text()).then(console.log)' 2>&1)" || true

if grep -q 'Example Domain' <<<"$out"; then
  echo "PASS: Browserless returned example.com through provider '$provider'"
else
  echo "FAIL: no example.com content; last lines follow" >&2
  printf '%s\n' "$out" | tail -20 >&2
  exit 1
fi
