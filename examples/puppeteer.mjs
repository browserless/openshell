// SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
// SPDX-License-Identifier: MIT
//
// Puppeteer over CDP, run inside an OpenShell sandbox. BROWSERLESS_TOKEN holds
// an OpenShell placeholder; the sandbox swaps in the real key on the way out.
import puppeteer from 'puppeteer-core';

const region = process.env.BROWSERLESS_REGION ?? 'production-sfo';
const token = encodeURIComponent(process.env.BROWSERLESS_TOKEN ?? '');

const browser = await puppeteer.connect({
  browserWSEndpoint: `wss://${region}.browserless.io?token=${token}`,
});
try {
  const page = await browser.newPage();
  await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
  console.log(`puppeteer: ${await page.title()}`);
} finally {
  await browser.close();
}
