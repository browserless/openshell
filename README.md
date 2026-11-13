# Browserless for NVIDIA OpenShell and NemoClaw

Give an agent running in an [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandbox a real browser, without installing one in the sandbox.

This repository holds OpenShell **provider profiles** for [Browserless](https://www.browserless.io). A provider profile tells OpenShell where a credential may be sent. Your Browserless API token stays in the OpenShell gateway: the sandbox's environment holds a placeholder, and OpenShell puts the real token on requests to Browserless only.

---

## Install

### Import from this repository (recommended)

Needs OpenShell 0.1.8 or newer.

```shell
openshell provider profile import --global \
  --url https://raw.githubusercontent.com/browserless/openshell/main/providers/browserless.yaml

export BROWSERLESS_TOKEN=<your Browserless API token>
export BROWSERLESS_MCP_TOKEN="$BROWSERLESS_TOKEN"
openshell provider create --name browserless --type browserless \
  --credential BROWSERLESS_TOKEN --credential BROWSERLESS_MCP_TOKEN
```

Then attach the provider to a sandbox with `--provider browserless`. Inside the sandbox, `BROWSERLESS_TOKEN` and `BROWSERLESS_MCP_TOKEN` hold placeholders, not the token.

No account yet? Sign up at [browserless.io/signup/email](https://www.browserless.io/signup/email) and copy the API token from [account.browserless.io](https://account.browserless.io).

### Pin a version

To keep the profile from changing under you, replace `main` in the URL with a tag from this repository's [releases](https://github.com/browserless/openshell/releases).

### Update

Importing a profile that already exists fails. To move to a newer version, delete the profile and import it again. Providers created from it keep working:

```shell
openshell provider profile delete --global browserless
openshell provider profile import --global \
  --url https://raw.githubusercontent.com/browserless/openshell/main/providers/browserless.yaml
```

### From a local copy

```shell
openshell provider profile lint   -f providers/browserless.yaml
openshell provider profile import -f providers/browserless.yaml --global
```

NemoClaw pins an older OpenShell release, which these profiles do not support. [docs/nemoclaw.md](docs/nemoclaw.md) covers NemoClaw's own route to the hosted MCP server.

---

## Profiles

| Profile | Use it for |
|---|---|
| [`providers/browserless.yaml`](providers/browserless.yaml) | REST, BrowserQL, Puppeteer and Playwright (CDP and native), durable sessions in every region, and the hosted MCP server. The two Stripe Link MCP tools are denied; REST stays open (see [what it allows](#what-these-profiles-allow)). |
| [`providers/browserless-linkgated.yaml`](providers/browserless-linkgated.yaml) | Ordinary browsing, with Stripe Link only after a person approves. See [docs/stripe-link-approval.md](docs/stripe-link-approval.md). |
| [`providers/browserless-link-approve.yaml`](providers/browserless-link-approve.yaml) | Credential-free companion an operator attaches to allow `browserless_link_connect`, and detaches to revoke. |

---

## What these profiles allow

The main profile, `providers/browserless.yaml`:

- **One token, two placements.** `BROWSERLESS_TOKEN` resolves only as the `token` query parameter, and `BROWSERLESS_MCP_TOKEN` only as an `Authorization: Bearer` header. Create both from the same Browserless API token.
- **Only Browserless hosts.** The token is sent only to `production-*.browserless.io` (the SFO, LON and AMS regions) and to `mcp.browserless.io/mcp`. Requests from the sandbox to any other host are blocked by the sandbox's network policy.
- **Only the processes you list.** `binaries` lets `node` and `curl` at `/usr/bin` or `/usr/local/bin` reach those hosts. Edit it to match your image.
- **REST** with full access, including `DELETE` so an agent can stop its own sessions.
- **BrowserQL**: every query and mutation except `reconnect`, which hands the live browser to another client. Send each request as a single anonymous operation (`mutation { … }`); named operations are denied. To keep a browser between connections, use a durable session (`POST /session`) and the connect and BrowserQL URLs it returns.
- **WebSockets** only on the CDP and Playwright connect paths, and on the worker-pinned session and reconnect URLs that the API returns.
- **Every MCP tool except the two Stripe Link tools.** OpenShell answers `browserless_link_checkout` and `browserless_link_connect` with `policy_denied`. These rules cover the MCP tools only. REST stays open, including Browserless's own agent endpoints, which can use a Stripe Link wallet connected to the account. If the account has a connected wallet, use the [Link-gated profiles](docs/stripe-link-approval.md), whose REST access is an allow-list.

Usage is billed to the Browserless account that owns the token, as it is outside OpenShell.

---

## Quick check

This starts a throwaway sandbox and fetches example.com through Browserless. OpenShell's default sandbox image has no `curl` or `node`, so it uses the official Node image:

```shell
openshell sandbox create --no-keep --from node:24-bookworm-slim --provider browserless -- node -e '
  fetch(`https://production-sfo.browserless.io/content?token=${process.env.BROWSERLESS_TOKEN}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ url: "https://example.com" }),
  }).then((r) => r.text()).then(console.log)'
```

Keep the single quotes: `${process.env.BROWSERLESS_TOKEN}` is read inside the sandbox, where it holds the placeholder. [`scripts/smoke.sh`](scripts/smoke.sh) runs the same check and prints `PASS` or `FAIL`.

Puppeteer, Playwright, BrowserQL and MCP examples, with an image to run them in, are in [examples/](examples/).

---

## Version notes

- **OpenShell 0.1.8 and newer** need WebSocket paths on their own `protocol: websocket` endpoints, and resolve each credential only where the profile places it. The main profile does both.
- **Earlier OpenShell releases** are not supported.
- OpenShell closes the connection on any client WebSocket message over 4 MiB.

Details, and what each profile was tested on: [docs/version-notes.md](docs/version-notes.md).

---

## Repository layout

```
providers/                     OpenShell provider profiles
docs/                          Version notes, NemoClaw's MCP route, Stripe Link approval
examples/                      Puppeteer, Playwright, BrowserQL and MCP clients, and a sandbox image
scripts/lint-profiles.sh       Lints, imports and attaches every profile on a throwaway gateway (CI)
scripts/smoke.sh               The quick check above
assets/logo.svg                Browserless logo
```

CI runs `scripts/lint-profiles.sh` against the latest OpenShell release and against 0.1.8 on every pull request and once a week. It runs on Linux with Docker and a kernel with Landlock; locally:

```shell
OPENSHELL_VERSION=v0.1.8 scripts/lint-profiles.sh
```

---

## Resources

- OpenShell: [github.com/NVIDIA/OpenShell](https://github.com/NVIDIA/OpenShell) and the [provider docs](https://docs.nvidia.com/openshell/latest/how-it-works/providers/overview)
- NemoClaw: [github.com/NVIDIA/NemoClaw](https://github.com/NVIDIA/NemoClaw)
- Browserless docs: [docs.browserless.io](https://docs.browserless.io)
- Hosted MCP server: [`https://mcp.browserless.io/mcp`](https://mcp.browserless.io/mcp)
- Report a security issue: [SECURITY.md](SECURITY.md)

---

## License

MIT, see [LICENSE](LICENSE).

The Browserless server itself is licensed separately under SSPL-1.0.
