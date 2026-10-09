// Capture provenance is validated before repository images are replaced.
export function versionFromWelcome(text) {
  const match = /^v?(\d+\.\d+\.\d+)$/.exec(text.trim());
  if (!match) throw new Error(`Unrecognized deployed Carbon version: ${text}`);
  return match[1];
}

export function validateCapture(pin, version, stories, themes, results) {
  if (version !== pin.carbonReactVersion) {
    throw new Error(`Deployed Carbon ${version} differs from pinned ${pin.carbonReactVersion}`);
  }
  const expected = new Set(stories.flatMap(s => themes.map(t => `${s.component}/${t}`)));
  const actual = new Set();
  for (const result of results) {
    const key = `${result.component}/${result.theme}`;
    if (!result.ok || !expected.has(key) || actual.has(key)) {
      throw new Error(`Incomplete, unknown or duplicate capture: ${key}`);
    }
    actual.add(key);
  }
  if (actual.size !== expected.size) throw new Error('Capture batch is incomplete');
}
