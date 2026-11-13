# Changelog

All notable changes to these profiles are documented here. Tags match the headings below.

## 1.0.0 — initial release

- Added `providers/browserless.yaml`: REST, BrowserQL, CDP and Playwright WebSockets on their own `protocol: websocket` endpoints (required from OpenShell 0.1.8), durable-session and reconnect paths in every region, and the hosted MCP server with the Stripe Link payment tools denied. One Browserless API token, declared as `BROWSERLESS_TOKEN` (query parameter) and `BROWSERLESS_MCP_TOKEN` (bearer header).
- Added `providers/browserless-linkgated.yaml` and `providers/browserless-link-approve.yaml` for Stripe Link behind human approval.
- Documented NemoClaw's own route to the hosted MCP server.
- Added Puppeteer, Playwright, BrowserQL and MCP examples with a sandbox image.
- Added `scripts/lint-profiles.sh` and a CI workflow that lints and imports every profile against the latest OpenShell release and 0.1.8, on pull requests and weekly.
- Requires OpenShell 0.1.8 or newer. Tested on 0.1.8.
