// Run from the hamrash-admin folder:
//   node --test supabase/functions/media-delete/media_delete.test.mjs
// No packages needed; the logic under test has no Deno-only code.
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { handleMediaDelete, parseImageId } from '../_shared/media_delete.mjs';
import { ALLOWED_KINDS } from '../_shared/media_upload.mjs';

const config = { accountId: 'acct', apiToken: 'secret-token', env: 'dev' };
const UUID = '0b6c7c1e-6f0e-4d57-9f64-2b1d7f0e6a11';
const ID = `hamrash-admin/dev/school-logos/${UUID}`;
const ENCODED = encodeURIComponent(ID);

const mine = (overrides = {}) => ({
  success: true,
  result: {
    id: ID,
    meta: { app: 'hamrash-admin', env: 'dev', kind: 'school-logos', uploader: 'user_1', ...overrides },
  },
});

/**
 * `get` and `del` are Cloudflare's answers to the lookup and the delete, as
 * `{ status, body }`. Every call is recorded.
 */
function setup({ get = { status: 200, body: mine() }, del = { status: 200, body: { success: true, result: {} } }, sub = 'user_1' } = {}) {
  const calls = [];
  const deps = {
    config,
    verifyToken: async (token) => {
      if (token !== 'good') throw new Error('bad token');
      return { sub };
    },
    fetch: async (url, init) => {
      calls.push({ url, method: init.method, headers: init.headers });
      const answer = init.method === 'DELETE' ? del : get;
      return new Response(JSON.stringify(answer.body), { status: answer.status });
    },
  };
  return { calls, deps };
}

const post = (body, token = 'good') =>
  new Request('http://x/media-delete', {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });

test('only POST is accepted', async () => {
  const { deps, calls } = setup();
  assert.equal((await handleMediaDelete(new Request('http://x/media-delete'), deps)).status, 405);
  assert.equal(calls.length, 0);
});

test('rejects a missing or invalid login token without calling Cloudflare', async () => {
  const { deps, calls } = setup();
  assert.equal((await handleMediaDelete(post({ id: ID }, null), deps)).status, 401);
  assert.equal((await handleMediaDelete(post({ id: ID }, 'forged'), deps)).status, 401);
  assert.equal(calls.length, 0);
});

test('rejects bad bodies and ids that are not ours, without calling Cloudflare', async () => {
  const { deps, calls } = setup();
  const bad = [
    '{not json',
    {},
    { id: null },
    { id: 42 },
    { id: ['x'] },
    { id: '' },
    // wrong shape
    { id: UUID },
    { id: `hamrash-admin/dev/school-logos` },
    { id: `${ID}/extra` },
    { id: `${ID}/` },
    { id: `/${ID}` },
    { id: `hamrash-admin//school-logos/${UUID}` },
    // an app or kind that isn't on the allow-list
    { id: `other-app/dev/school-logos/${UUID}` },
    { id: `hirethem-customer/dev/profiles/${UUID}` },
    { id: `hamrash-platform/dev/staff-photos/${UUID}` },
    { id: `__proto__/dev/school-logos/${UUID}` },
    { id: `constructor/dev/school-logos/${UUID}` },
    // another environment (dev must never delete prod's images)
    { id: `hamrash-admin/prod/school-logos/${UUID}` },
    // not a real uuid
    { id: 'hamrash-admin/dev/school-logos/not-a-uuid' },
    { id: `hamrash-admin/dev/school-logos/${UUID.toUpperCase()}` },
    { id: `hamrash-admin/dev/school-logos/${UUID}x` },
    // path tricks
    { id: 'hamrash-admin/dev/school-logos/..' },
    { id: `hamrash-admin/dev/../${UUID}` },
    { id: `hamrash-admin/dev/school-logos/${UUID}?x=1` },
    { id: `hamrash-admin/dev/school-logos/%2e%2e` },
  ];
  for (const body of bad) {
    const res = await handleMediaDelete(post(body), deps);
    assert.equal(res.status, 400, JSON.stringify(body));
  }
  assert.equal(calls.length, 0, 'nothing malformed ever reaches Cloudflare');
});

test('parseImageId accepts exactly our ids, for every allowed app and kind', () => {
  assert.deepEqual(parseImageId(ID, 'dev'), {
    app: 'hamrash-admin',
    env: 'dev',
    kind: 'school-logos',
    name: UUID,
  });
  for (const [app, kinds] of Object.entries(ALLOWED_KINDS)) {
    for (const kind of kinds) {
      assert.ok(parseImageId(`${app}/dev/${kind}/${UUID}`, 'dev'), `${app} / ${kind}`);
    }
  }
  assert.equal(parseImageId(ID, 'prod'), null);
});

test('deletes the uploader’s image: looks it up, then deletes it', async () => {
  const { deps, calls } = setup();
  const res = await handleMediaDelete(post({ id: ID }), deps);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { id: ID, deleted: true });

  assert.deepEqual(calls.map((c) => c.method), ['GET', 'DELETE']);
  for (const call of calls) {
    assert.equal(call.url, `https://api.cloudflare.com/client/v4/accounts/acct/images/v1/${ENCODED}`);
    assert.equal(call.headers.Authorization, 'Bearer secret-token');
  }
  assert.match(ENCODED, /%2F/, 'the slashes are URL encoded, as Cloudflare requires');
});

test('refuses someone else’s image and never deletes it', async () => {
  const { deps, calls } = setup({ sub: 'user_2' });
  const res = await handleMediaDelete(post({ id: ID }), deps);
  assert.equal(res.status, 403);
  assert.deepEqual(await res.json(), { error: 'forbidden' });
  assert.deepEqual(calls.map((c) => c.method), ['GET']);
});

test('refuses an image whose record does not match its id', async () => {
  for (const meta of [
    { uploader: 'someone_else' },
    { uploader: undefined },
    { app: 'hamrash-platform' },
    { env: 'prod' },
    { kind: 'staff-photos' },
  ]) {
    const { deps, calls } = setup({ get: { status: 200, body: mine(meta) } });
    const res = await handleMediaDelete(post({ id: ID }), deps);
    assert.equal(res.status, 403, JSON.stringify(meta));
    assert.ok(!calls.some((c) => c.method === 'DELETE'));
  }
});

test('refuses an image with no labels at all (not uploaded through media-upload)', async () => {
  for (const body of [
    { success: true, result: { id: ID } },
    { success: true, result: { id: ID, meta: null } },
    { success: true, result: {} },
    { success: true },
  ]) {
    const { deps, calls } = setup({ get: { status: 200, body } });
    assert.equal((await handleMediaDelete(post({ id: ID }), deps)).status, 403);
    assert.ok(!calls.some((c) => c.method === 'DELETE'));
  }
});

test('an image that is already gone is a 404, not an error', async () => {
  const { deps, calls } = setup({
    get: { status: 404, body: { success: false, errors: [{ code: 5404 }] } },
  });
  const res = await handleMediaDelete(post({ id: ID }), deps);
  assert.equal(res.status, 404);
  assert.deepEqual(await res.json(), { error: 'not_found' });
  assert.deepEqual(calls.map((c) => c.method), ['GET']);

  // deleted by someone else between the lookup and the delete
  const raced = setup({ del: { status: 404, body: { success: false } } });
  assert.equal((await handleMediaDelete(post({ id: ID }), raced.deps)).status, 404);
});

test('hides Cloudflare errors from the app', async () => {
  const failures = [
    setup({ get: { status: 500, body: { success: false, errors: [{ message: 'token detail' }] } } }),
    setup({ get: { status: 200, body: { success: false, errors: [{ message: 'token detail' }] } } }),
    setup({ del: { status: 500, body: { success: false, errors: [{ message: 'token detail' }] } } }),
    setup({ del: { status: 200, body: { success: false } } }),
  ];
  for (const { deps } of failures) {
    const res = await handleMediaDelete(post({ id: ID }), deps);
    assert.equal(res.status, 502);
    assert.deepEqual(await res.json(), { error: 'upstream_failed' });
  }
});

test('a network failure to Cloudflare is a 502', async () => {
  const { deps } = setup();
  deps.fetch = async () => {
    throw new Error('offline');
  };
  assert.equal((await handleMediaDelete(post({ id: ID }), deps)).status, 502);
});

test('never returns the Cloudflare token', async () => {
  for (const scenario of [setup(), setup({ sub: 'user_2' }), setup({ get: { status: 500, body: {} } })]) {
    const res = await handleMediaDelete(post({ id: ID }), scenario.deps);
    assert.ok(!(await res.text()).includes('secret-token'));
  }
});
