# Examples

Browserless clients to run inside an OpenShell sandbox that has the `browserless` provider attached. Each script reads the OpenShell placeholder from `BROWSERLESS_TOKEN` and sends it as the `token` query parameter; OpenShell puts the real API token on the request on its way to Browserless.

| Script | What it does |
|---|---|
| `puppeteer.mjs` | Puppeteer over CDP: opens example.com and prints the title. |
| `playwright.mjs` | Playwright over CDP, then over Playwright's own protocol on `/chromium/playwright`. |
| `browserql.mjs` | One BrowserQL query with Node's `fetch`; no dependencies. |
| `mcp.mjs` | The hosted MCP server: lists the tools and runs `browserless_smartscraper`. |

## Run them

OpenShell's default sandbox image has no Node, so build an image with the clients first. The [Dockerfile](Dockerfile) installs the pinned versions from `package-lock.json` under `/usr/local/lib/browserless-examples`, a path the default sandbox filesystem policy can read.

```shell
docker build -t browserless-openshell-examples examples
openshell sandbox create --no-keep --from browserless-openshell-examples \
  --provider browserless -- sh -c '
    cd /usr/local/lib/browserless-examples
    node puppeteer.mjs && node playwright.mjs && node browserql.mjs && node mcp.mjs'
```

Expected output:

```text
puppeteer: Example Domain
playwright (CDP): Example Domain
playwright (native): Example Domain
browserql: 200 Example Domain
mcp: 23 tools
mcp smartscraper: Example Domain found
```

The tool count follows the hosted server and changes as tools are added. Set `BROWSERLESS_REGION` to `production-lon` or `production-ams` to use another region.
