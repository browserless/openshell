#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
# SPDX-License-Identifier: MIT
#
# Lints and imports every profile in providers/ against a throwaway local
# OpenShell gateway, then starts a sandbox with a provider built from each
# profile and waits for the gateway to accept the sandbox's configuration.
# `openshell provider profile lint` validates through a running gateway, so
# this downloads the release binaries, checks their checksums, starts a gateway
# with the Docker compute driver, and removes everything on exit. Linux only
# (x86_64 or aarch64); needs curl, Docker, and a kernel with Landlock.
#
#   OPENSHELL_VERSION        release tag to test, v0.1.8 or newer (default: latest)
#   OPENSHELL_PORT           local gateway port (default: 17670)
#   OPENSHELL_BIND_ADDRESS   gateway listen address (default: 0.0.0.0). Keep a
#                            wildcard address: sandbox containers reach the
#                            gateway through the Docker host, and the CLI
#                            through 127.0.0.1.
#   OPENSHELL_SANDBOX_IMAGE  image for the check sandboxes (default:
#                            node:24-bookworm-slim)
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
version="${OPENSHELL_VERSION:-latest}"
port="${OPENSHELL_PORT:-17670}"
sandbox_image="${OPENSHELL_SANDBOX_IMAGE:-node:24-bookworm-slim}"
export OPENSHELL_BIND_ADDRESS="${OPENSHELL_BIND_ADDRESS:-0.0.0.0}"

case "$(uname -m)" in
  x86_64) cli_target=x86_64-unknown-linux-musl gateway_target=x86_64-unknown-linux-gnu ;;
  aarch64 | arm64) cli_target=aarch64-unknown-linux-musl gateway_target=aarch64-unknown-linux-gnu ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [ "$version" = latest ]; then
  base_url=https://github.com/NVIDIA/OpenShell/releases/latest/download
else
  base_url="https://github.com/NVIDIA/OpenShell/releases/download/$version"
fi

work="$(mktemp -d)"
gateway_pid=""
openshell=""
sandboxes=()
# shellcheck disable=SC2317 # cleanup runs from the EXIT trap
cleanup() {
  local name
  for name in "${sandboxes[@]}"; do
    "$openshell" sandbox delete "$name" >/dev/null 2>&1 || true
  done
  if [ -n "$gateway_pid" ]; then kill "$gateway_pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT

# The gateway and the CLI keep their state under HOME; keep it in the temp dir.
export HOME="$work/home"
mkdir -p "$HOME" "$work/bin"

download() {
  local asset="$1" checksums="$2"
  curl -fsSL -o "$work/$asset" "$base_url/$asset"
  curl -fsSL -o "$work/$checksums" "$base_url/$checksums"
  (cd "$work" && grep " $asset\$" "$checksums" | sha256sum -c -)
  tar -xzf "$work/$asset" -C "$work/bin"
}
download "openshell-$cli_target.tar.gz" openshell-checksums-sha256.txt
download "openshell-gateway-$gateway_target.tar.gz" openshell-gateway-checksums-sha256.txt

openshell="$work/bin/openshell"
gateway="$work/bin/openshell-gateway"
"$openshell" --version

"$gateway" generate-certs --output-dir "$work/tls" --server-san host.openshell.internal >/dev/null
OPENSHELL_LOCAL_TLS_DIR="$work/tls" "$gateway" --port "$port" --compute-driver docker >"$work/gateway.log" 2>&1 &
gateway_pid=$!

for _ in $(seq 1 60); do
  if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then break; fi
  sleep 1
done
# The gateway writes client certificates for its default name, `openshell`.
"$openshell" gateway add "https://127.0.0.1:$port" --local >/dev/null 2>&1 || true

ready=""
for _ in $(seq 1 30); do
  if "$openshell" status 2>/dev/null | grep -q 'Connected'; then
    ready=1
    break
  fi
  sleep 1
done
if [ -z "$ready" ]; then
  echo "gateway did not become ready; log follows" >&2
  cat "$work/gateway.log" >&2
  exit 1
fi

# Lint checks each profile on its own. The gateway validates the policy a
# provider contributes only when a sandbox uses it, so start one sandbox per
# profile and wait until its configuration is accepted or rejected. Credential
# values are dummies; the sandboxes run no commands, so nothing reaches
# Browserless.
check_sandbox() {
  local profile="$1" name="$2" id var created status=""
  local args=()
  id="$(sed -n 's/^id: *//p' "$profile")"
  for var in $(sed -n 's/^ *env_vars: *\[\(.*\)\]/\1/p' "$profile" | tr ',' ' '); do
    export "$var=ci-placeholder"
    args+=(--credential "$var")
  done
  "$openshell" provider create --name "$name" --type "$id" "${args[@]}" >/dev/null
  sandboxes+=("$name")
  if ! created="$("$openshell" sandbox create --name "$name" --from "$sandbox_image" \
    --provider "$name" --detach 2>&1)"; then
    echo "sandbox $name could not be created; output follows" >&2
    printf '%s\n' "$created" >&2
    return 1
  fi
  for _ in $(seq 1 90); do
    status="$("$openshell" sandbox get "$name" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)"
    if grep -q 'ConfigurationReady: True' <<<"$status"; then
      return 0
    fi
    if grep -q -e 'ConfigurationInvalid' -e 'Phase: Error' <<<"$status"; then
      break
    fi
    sleep 2
  done
  echo "sandbox $name did not accept its configuration; status follows" >&2
  printf '%s\n' "$status" >&2
  return 1
}

failed=0
index=0
for profile in "$repo_root"/providers/*.yaml; do
  name="$(basename "$profile")"
  index=$((index + 1))
  # Sandbox names are limited to 19 characters, so number them.
  if "$openshell" provider profile lint -f "$profile" &&
    "$openshell" provider profile import -f "$profile" --global &&
    check_sandbox "$profile" "ci-check-$index"; then
    echo "ok: $name"
  else
    echo "FAILED: $name" >&2
    failed=1
  fi
done
exit "$failed"
