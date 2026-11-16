# Changelog

All notable changes to these profiles are documented here. Tags match the headings below.

## 1.0.0 — initial release

- Added `providers/browserless.yaml`: REST, BrowserQL on its own `protocol: graphql` endpoints, as single anonymous operations without `reconnect`, CDP and Playwright WebSockets on their own `protocol: websocket` endpoints (required from OpenShell 0.1.8), the worker-pinned durable-session and reconnect URLs in every region, and the hosted MCP server. The endpoints that run your own code in the browser (`/function`, `/download` and `browserless_function`) and the two Stripe Link MCP tools are denied. One Browserless API token, `BROWSERLESS_TOKEN`, sent as the `token` query parameter everywhere, including the MCP server.
- Added `providers/browserless-linkgated.yaml` and `providers/browserless-link-approve.yaml` for Stripe Link behind human approval.
- Documented NemoClaw's own route to the hosted MCP server.
- Added Puppeteer, Playwright, BrowserQL and MCP examples with a sandbox image.
- Added `scripts/lint-profiles.sh` and a CI workflow that lints and imports every profile and starts a sandbox with each, against the latest OpenShell release and 0.1.8, on pull requests and weekly.
- Requires OpenShell 0.1.8 or newer. Tested on 0.1.8.
