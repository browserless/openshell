// SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
// SPDX-License-Identifier: MIT
//
// The hosted Browserless MCP server from inside an OpenShell sandbox.
// BROWSERLESS_MCP_TOKEN holds an OpenShell placeholder for the bearer header.
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';

const transport = new StreamableHTTPClientTransport(new URL('https://mcp.browserless.io/mcp'), {
  requestInit: { headers: { Authorization: `Bearer ${process.env.BROWSERLESS_MCP_TOKEN ?? ''}` } },
});
const client = new Client({ name: 'browserless-openshell-example', version: '1.0.0' });

await client.connect(transport);
try {
  const { tools } = await client.listTools();
  console.log(`mcp: ${tools.length} tools`);
  const result = await client.callTool({
    name: 'browserless_smartscraper',
    arguments: { url: 'https://example.com', formats: ['markdown'] },
  });
  const text = (result.content ?? []).map((part) => part.text ?? '').join('\n');
  console.log(`mcp smartscraper: ${text.includes('Example Domain') ? 'Example Domain found' : text.slice(0, 200)}`);
} finally {
  await client.close();
}
