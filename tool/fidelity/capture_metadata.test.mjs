import test from 'node:test';
import assert from 'node:assert/strict';
import {versionFromWelcome, validateCapture} from './capture_metadata.mjs';

const pin = {carbonReactVersion: '1.118.0'};
const stories = [{component: 'button'}], themes = ['white', 'g100'];
const results = themes.map(theme => ({component: 'button', theme, ok: true}));

test('version is observed from the deployed Welcome caption', () => {
  assert.equal(versionFromWelcome(' v1.118.0 '), '1.118.0');
  assert.throws(() => versionFromWelcome('unknown'), /Unrecognized/);
});
test('wrong deployment, missing, failed and duplicate frames cannot be stamped', () => {
  validateCapture(pin, '1.118.0', stories, themes, results);
  assert.throws(() => validateCapture(pin, '1.119.0', stories, themes, results), /differs/);
  assert.throws(() => validateCapture(pin, '1.118.0', stories, themes, results.slice(0, 1)), /incomplete/);
  assert.throws(() => validateCapture(pin, '1.118.0', stories, themes, [{...results[0], ok: false}, results[1]]), /Incomplete/);
  assert.throws(() => validateCapture(pin, '1.118.0', stories, themes, [...results, results[0]]), /duplicate/);
});
