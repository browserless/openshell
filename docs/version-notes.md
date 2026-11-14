# OpenShell version notes

The profiles here need **OpenShell 0.1.8 or newer**. They were tested on 0.1.8: REST, BrowserQL, Puppeteer, Playwright (CDP and native), durable sessions, the LON and AMS regions, the hosted MCP server, and the Stripe Link approval flow. Earlier releases are not supported.

CI lints and imports every profile, and starts a sandbox with a provider built from each to check that the gateway accepts its policy, against the latest OpenShell release and against 0.1.8 on each pull request and once a week.

## What 0.1.8 changed

Two 0.1.8 changes shape the main profile:

- **REST endpoints refuse WebSocket upgrades.** CDP and Playwright connections need endpoints with `protocol: websocket`. The main profile declares one for each CDP and Playwright connect path, and for the worker-pinned `/e/<id>/…` session and reconnect URLs that the API returns. Any other WebSocket path is refused.
- **Credentials resolve only where the profile places them.** `BROWSERLESS_TOKEN` resolves only as the `token` query parameter, including for the MCP server. A placeholder sent in a header or a request body is not replaced.

## Updating a profile

A gateway keeps the profile it imported; editing the YAML afterwards changes nothing. Importing a profile that already exists fails, so to load a newer version, delete it and import it again (`openshell provider profile delete --global browserless`, then the import). Providers created from it keep working.

## Sandbox images

- **Bring your own image.** OpenShell's default sandbox image has no `curl`, `node` or `python`. Pass `--from` with an image that has your client, such as `node:24-bookworm-slim` or the image built from [`examples/Dockerfile`](../examples/Dockerfile).
- **Install code where the sandbox can read it.** The default filesystem policy does not allow reads under `/opt`. Put scripts and `node_modules` under `/usr` (the examples image uses `/usr/local/lib/browserless-examples`) or in the sandbox working directory, or pass a policy that allows your path.
- **Match `binaries` to your image.** The profile lets only `node` and `curl` at `/usr/bin` or `/usr/local/bin` reach Browserless. Add your paths if your client lives elsewhere.
- **macOS VM driver.** On 0.1.8 the VM driver could not prepare images published with Docker's v2 manifest format, such as `curlimages/curl`. Images published with an OCI index, such as the official `node` images, work.

## Limits

- **Message size.** OpenShell inspects every client WebSocket message and closes the connection on a message over 4 MiB (measured on 0.1.8: 3.9 MiB passes, 4.1 MiB closes). Everyday CDP traffic from Puppeteer and Playwright stays far below that. Large `page.evaluate` arguments or `page.setContent` payloads can hit it.
