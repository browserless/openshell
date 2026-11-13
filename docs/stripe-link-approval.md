# Stripe Link behind human approval

Browserless can pay with a [Stripe Link](https://link.com) wallet. The main profile denies both Stripe Link MCP tools, `browserless_link_checkout` and `browserless_link_connect`, but keeps REST open, and Browserless's own agent endpoints can use a connected wallet. If the account has a connected wallet, or an agent should use the wallet only after a person says yes, use the two profiles below instead. They need OpenShell 0.1.8 or newer and were tested on 0.1.8.

- `providers/browserless-linkgated.yaml` covers ordinary browsing: REST `/content`, BrowserQL on `/chromium/bql` (single anonymous operations, without `reconnect`), `/json/*` discovery, CDP on `/`, and the MCP tools `browserless_smartscraper` and `browserless_usage`. Every Stripe Link REST path is outside it, and `browserless_link_checkout` is always denied.
- `providers/browserless-link-approve.yaml` is credential-free. Attaching it to a sandbox allows `browserless_link_connect`; detaching it takes that away again.

## Set it up

```shell
openshell settings set --global --key agent_policy_proposals_enabled --value true --yes
openshell provider profile import -f providers/browserless-linkgated.yaml --global
openshell provider profile import -f providers/browserless-link-approve.yaml --global

export BROWSERLESS_TOKEN=<your Browserless API token>
export BROWSERLESS_MCP_TOKEN="$BROWSERLESS_TOKEN"
openshell provider create --name browserless-gated --type browserless-linkgated \
  --credential BROWSERLESS_TOKEN --credential BROWSERLESS_MCP_TOKEN
openshell provider create --name link-approve --type browserless-link-approve

openshell sandbox create --name agent --from <your image> --provider browserless-gated
```

## How approval works

1. **The agent asks.** A Stripe Link REST call such as `GET /integrations/stripe-link/status` gets `403 policy_denied`. The agent proposes a rule for exactly that path by posting to `http://policy.local/v1/proposals` from inside the sandbox.
2. **A person reviews it.** The proposal shows the rule, the endpoint and the agent's reason:

   ```shell
   openshell rule get agent --status pending
   openshell rule approve agent --chunk-id <chunk-id>
   ```

3. **A person allows the wallet tool**, if the agent also needs `browserless_link_connect`:

   ```shell
   openshell sandbox provider attach agent link-approve
   ```

4. **Revoke it** when the purchase is done:

   ```shell
   openshell sandbox provider detach agent link-approve
   ```

   Detaching removes only the wallet tool. The REST rule approved in step 2 stays in the sandbox's policy.

`browserless_link_checkout` stays denied at every step: approval through OpenShell's policy advisor cannot lift a tool-level deny. Review every proposal before approving it, especially one that opens another Browserless path. Browserless's own agent endpoints can also use a connected Stripe Link wallet.

## What we observed on 0.1.8

| Step | REST link status | `browserless_link_connect` | `browserless_link_checkout` | `browserless_smartscraper` |
|---|---|---|---|---|
| Before approval | 403 `policy_denied` | denied | denied | works |
| After approving the rule and attaching `link-approve` | 200 | works | denied | works |
| After detaching `link-approve` | 200 (the approved rule stays) | denied | denied | works |
