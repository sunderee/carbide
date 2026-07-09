// Copyright 2026 Bizjak Tech OÜ
//
// Captures upstream Carbon React Storybook stories as reference screenshots,
// one per theme, for the fidelity comparison (epic W3). Run via capture.sh
// (Docker + Playwright). Needs network access to the published Storybook.
//
// Output: <repo>/test/fidelity/references/<component>/<theme>.png
// and a manifest at test/fidelity/references/manifest.json.

import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';

const BASE =
  process.env.STORYBOOK_URL || 'https://react.carbondesignsystem.com';
const OUT = process.env.OUT || 'test/fidelity/references';
// Carbon Storybook theme globals.
const THEMES = ['white', 'g10', 'g90', 'g100'];

const { stories } = JSON.parse(
  readFileSync(new URL('./stories.json', import.meta.url)),
);

const browser = await chromium.launch();
const context = await browser.newContext({ deviceScaleFactor: 2 });
const page = await context.newPage();

const results = [];
for (const story of stories) {
  for (const theme of THEMES) {
    const url =
      `${BASE}/iframe.html?id=${story.storyId}` +
      `&viewMode=story&globals=theme:${theme}`;
    const out = join(OUT, story.component, `${theme}.png`);
    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
      const root = page.locator('#storybook-root');
      await root.waitFor({ state: 'visible', timeout: 15000 });
      // Let fonts/animations settle.
      await page.waitForTimeout(700);
      const box = await root.boundingBox();
      if (!box || box.width < 2 || box.height < 2) {
        throw new Error('empty #storybook-root');
      }
      mkdirSync(dirname(out), { recursive: true });
      await root.screenshot({ path: out });
      results.push({ component: story.component, theme, ok: true });
      console.log(`OK   ${story.component} ${theme}`);
    } catch (err) {
      results.push({
        component: story.component,
        theme,
        ok: false,
        error: String(err).split('\n')[0],
      });
      console.log(`FAIL ${story.component} ${theme}: ${String(err).split('\n')[0]}`);
    }
  }
}

await browser.close();

// Stamp the @carbon/react version the live Storybook tracks (#230): the
// published Storybook deploys from the latest release, so the npm registry
// 'latest' at capture time identifies what the pixels were rendered by.
// Compared against the submodule pin by the staleness check in
// test/fidelity/fidelity_test.dart.
let carbonReactVersion = null;
try {
  const res = await fetch('https://registry.npmjs.org/@carbon/react/latest');
  carbonReactVersion = (await res.json()).version ?? null;
} catch {
  console.log('WARN could not resolve @carbon/react version for the stamp');
}

const ok = results.filter((r) => r.ok).length;
mkdirSync(OUT, { recursive: true });
writeFileSync(
  join(OUT, 'manifest.json'),
  JSON.stringify(
    {
      source: BASE,
      capturedAt: new Date().toISOString(),
      carbonReactVersion,
      themes: THEMES,
      stories,
      results,
    },
    null,
    2,
  ) + '\n',
);
console.log(`\n${ok}/${results.length} references captured -> ${OUT}`);
if (ok === 0) {
  process.exitCode = 1;
}
