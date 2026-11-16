// SPDX-FileCopyrightText: Copyright (c) 2026 Browserless
// SPDX-License-Identifier: MIT
//
// Playwright inside an OpenShell sandbox, both ways Browserless accepts it:
// over CDP, and over Playwright's own protocol on /chromium/playwright.
import { chromium } from 'playwright-core';

const region = process.env.BROWSERLESS_REGION ?? 'production-sfo';
const token = encodeURIComponent(process.env.BROWSERLESS_TOKEN ?? '');

async function title(browser) {
  try {
    const context = browser.contexts()[0] ?? (await browser.newContext());
    const page = await context.newPage();
    await page.goto('https://example.com');
    return await page.title();
  } finally {
    await browser.close();
  }
}

const overCDP = await chromium.connectOverCDP(`wss://${region}.browserless.io?token=${token}`);
console.log(`playwright (CDP): ${await title(overCDP)}`);

const native = await chromium.connect(`wss://${region}.browserless.io/chromium/playwright?token=${token}`);
console.log(`playwright (native): ${await title(native)}`);
