// Copyright 2026 Bizjak Tech OÜ
//
// Captures upstream Carbon React Storybook stories as reference screenshots,
// one per theme, for the fidelity comparison (epic W3). Run via capture.sh
// (Docker + Playwright). Needs network access to the published Storybook.
//
// Output: <repo>/test/fidelity/references/<component>/<theme>.png
// and a manifest at test/fidelity/references/manifest.json.

import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { createHash } from 'node:crypto';
import {versionFromWelcome, validateCapture} from './capture_metadata.mjs';
import { dirname, join } from 'node:path';

const BASE =
  process.env.STORYBOOK_URL || 'https://react.carbondesignsystem.com';
const OUT = process.env.OUT || 'test/fidelity/references';
const STAGE = mkdtempSync(join(tmpdir(), 'carbide-carbon-capture-'));
const pin = JSON.parse(readFileSync(new URL('../carbon_reference.lock.json', import.meta.url)));
// Carbon Storybook theme globals.
const THEMES = ['white', 'g10', 'g90', 'g100'];

const { stories } = JSON.parse(
  readFileSync(new URL('./stories.json', import.meta.url)),
);

let browser;
try {
  browser = await chromium.launch();
  const context = await browser.newContext({ deviceScaleFactor: 2, viewport: {width: 1280, height: 720} });
  const page = await context.newPage();

  await page.goto(`${BASE}/iframe.html?id=getting-started-welcome--welcome&viewMode=story`, {waitUntil: 'domcontentloaded', timeout: 45000});
  const caption = page.locator('.welcome__heading--subtitle');
  await caption.waitFor({state: 'visible', timeout: 20000});
  const carbonReactVersion = versionFromWelcome(await caption.textContent());
  if (carbonReactVersion !== pin.carbonReactVersion) {
    throw new Error(`Deployed version ${carbonReactVersion} differs from pinned ${pin.carbonReactVersion}`);
  }
  console.log(`Observed deployed @carbon/react ${carbonReactVersion}`);

  const results = [];
  for (const story of stories) {
    for (const theme of THEMES) {
      // The Storybook's theme decorator follows the `backgrounds` global
      // (mapped to data-carbon-theme); the legacy `theme` global is kept in
      // the URL for older deployments.
      const url =
        `${BASE}/iframe.html?id=${story.storyId}` +
        `&viewMode=story&globals=theme:${theme};backgrounds.value:${theme}`;
      const out = join(STAGE, story.component, `${theme}.png`);
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

  const ok = results.filter((r) => r.ok).length;
  validateCapture(pin, carbonReactVersion, stories, THEMES, results);
  const imageSha256 = {};
  for (const story of stories) for (const theme of THEMES) {
    const relative = `${story.component}/${theme}.png`;
    const source = join(STAGE, relative), target = join(OUT, relative);
    mkdirSync(dirname(target), {recursive: true});
    copyFileSync(source, target);
    imageSha256[relative] = createHash('sha256').update(readFileSync(source)).digest('hex');
  }
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
        captures: [{capturedAt: new Date().toISOString(), carbonReactVersion, versionBasis: 'Version observed in deployed Carbon Welcome story', components: stories.map(s => s.component)}],
        referenceReview: {carbonCommit: pin.carbonCommit, carbonReactVersion, reviewedAt: new Date().toISOString()},
        imageSha256,
      },
      null,
      2,
    ) + '\n',
  );
  console.log(`\n${ok}/${results.length} references captured -> ${OUT}`);

} finally {
  await browser?.close();
  rmSync(STAGE, {recursive: true, force: true});
}
