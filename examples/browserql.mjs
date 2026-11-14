// SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
// SPDX-License-Identifier: MIT
//
// One BrowserQL query from inside an OpenShell sandbox. Needs only Node's fetch.
const region = process.env.BROWSERLESS_REGION ?? 'production-sfo';
const token = encodeURIComponent(process.env.BROWSERLESS_TOKEN ?? '');

const res = await fetch(`https://${region}.browserless.io/chromium/bql?token=${token}`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify({
    query: 'mutation { goto(url: "https://example.com") { status } title { title } }',
  }),
});
if (!res.ok) throw new Error(`BrowserQL returned ${res.status}`);
const { data } = await res.json();
console.log(`browserql: ${data.goto.status} ${data.title.title}`);
