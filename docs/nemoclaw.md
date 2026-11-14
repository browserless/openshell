# NemoClaw

[NemoClaw](https://github.com/NVIDIA/NemoClaw) runs OpenClaw inside an OpenShell sandbox. It pins an OpenShell release older than 0.1.8, so the provider profiles in this repository do not apply to it. Use NemoClaw's own MCP support instead.

## Hosted MCP server

NemoClaw adds the hosted Browserless MCP server as a tool provider. When you add it, deny the Stripe Link payment tools and `browserless_function`, which runs your own code in the browser:

```shell
export BROWSERLESS_TOKEN=<your Browserless API token>
nemoclaw <sandbox> mcp add browserless --url https://mcp.browserless.io/mcp \
  --env BROWSERLESS_TOKEN \
  --deny-tool browserless_link_checkout --deny-tool browserless_link_connect \
  --deny-tool browserless_function
```

NemoClaw stores the token as an OpenShell provider, and the sandbox sees only a placeholder. The agent gets every Browserless MCP tool except the three denied ones, including `browserless_agent` for multi-step browsing and `browserless_smartscraper` for single pages.

Tested with NemoClaw v0.0.142.

## Puppeteer, Playwright and OpenClaw's built-in browser

These connect to Browserless over a WebSocket, and the profiles here need OpenShell 0.1.8 or newer for that. Use them in an OpenShell 0.1.8 sandbox outside NemoClaw, with [`providers/browserless.yaml`](../providers/browserless.yaml), until NemoClaw moves to OpenShell 0.1.8 or newer.
