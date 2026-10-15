// Run from the hamrash-admin folder:
//   node --test supabase/functions/media-upload/media_upload.test.mjs
// No packages needed; the logic under test has no Deno-only code.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import { ALLOWED_KINDS, handleMediaUpload } from '../_shared/media_upload.mjs';

const config = {
  accountId: 'acct',
  apiToken: 'secret-token',
  env: 'dev',
  imagesAccountHash: 'hash',
  streamCustomerCode: 'code',
};

function setup({ cloudflare, claims = { sub: 'user_1' }, streamCustomerCode } = {}) {
  const calls = [];
  const deps = {
    config: { ...config, ...(streamCustomerCode && { streamCustomerCode }) },
    uuid: () => 'uuid-1',
    verifyToken: async (token) => {
      if (token !== 'good') throw new Error('bad token');
      return claims;
    },
    fetch: async (url, init) => {
      calls.push({ url, init });
      return new Response(JSON.stringify(cloudflare), { status: 200 });
    },
  };
  return { calls, deps };
}

const post = (body, token = 'good') =>
  new Request('http://x/media-upload', {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: JSON.stringify(body),
  });

const imageOk = {
  success: true,
  result: { id: 'x', uploadURL: 'https://upload.example/u1' },
};
const videoOk = {
  success: true,
  result: { uid: 'vid1', uploadURL: 'https://upload.example/v1' },
};

test('only POST is accepted', async () => {
  const { deps } = setup();
  assert.equal((await handleMediaUpload(new Request('http://x/media-upload'), deps)).status, 405);
});

test('rejects a missing or invalid login token', async () => {
  const { deps, calls } = setup();
  const body = { type: 'image', app: 'hamrash-admin', kind: 'school-logos' };
  assert.equal((await handleMediaUpload(post(body, null), deps)).status, 401);
  assert.equal((await handleMediaUpload(post(body, 'forged'), deps)).status, 401);
  assert.equal(calls.length, 0);
});

test('rejects a token with no subject', async () => {
  const { deps, calls } = setup({ claims: {} });
  const res = await handleMediaUpload(post({ type: 'image', app: 'hamrash-admin', kind: 'school-logos' }), deps);
  assert.equal(res.status, 401);
  assert.equal(calls.length, 0);
});

test('the allow-list is exactly these two apps and their kinds', () => {
  assert.deepEqual(ALLOWED_KINDS, {
    'hamrash-platform': ['school-logos'],
    'hamrash-admin': ['school-logos', 'staff-photos', 'student-photos', 'parent-photos'],
  });
});

test('each allowed app and kind is accepted', async () => {
  for (const [app, kinds] of Object.entries(ALLOWED_KINDS)) {
    for (const kind of kinds) {
      const { deps } = setup({ cloudflare: imageOk });
      const res = await handleMediaUpload(post({ type: 'image', app, kind }), deps);
      assert.equal(res.status, 200, `${app} / ${kind}`);
    }
  }
});

test('rejects unknown types, apps and kinds without calling Cloudflare', async () => {
  const { deps, calls } = setup();
  for (const body of [
    { type: 'audio', app: 'hamrash-admin', kind: 'school-logos' },
    { type: 'image', app: 'other-app', kind: 'school-logos' },
    { type: 'image', app: 'hirethem-customer', kind: 'profiles' },
    { type: 'image', app: 'hamrash-admin', kind: 'hire-requests' },
    // each app only gets its own kinds
    { type: 'image', app: 'hamrash-platform', kind: 'staff-photos' },
    { type: 'image', app: 'hamrash-admin' },
    {},
  ]) {
    assert.equal((await handleMediaUpload(post(body), deps)).status, 400, JSON.stringify(body));
  }
  const notJson = new Request('http://x/media-upload', {
    method: 'POST',
    headers: { Authorization: 'Bearer good' },
    body: 'not json',
  });
  assert.equal((await handleMediaUpload(notJson, deps)).status, 400);
  assert.equal(calls.length, 0);
});

test('reserves an image with a prefixed custom id and labels', async () => {
  const { deps, calls } = setup({ cloudflare: imageOk });
  const res = await handleMediaUpload(
    post({ type: 'image', app: 'hamrash-admin', kind: 'student-photos' }),
    deps,
  );
  assert.equal(res.status, 200);
  const id = 'hamrash-admin/dev/student-photos/uuid-1';
  assert.deepEqual(await res.json(), {
    id,
    uploadURL: 'https://upload.example/u1',
    url: `https://imagedelivery.net/hash/${id}/public`,
  });
  assert.match(calls[0].url, /\/accounts\/acct\/images\/v2\/direct_upload$/);
  assert.equal(calls[0].init.headers.Authorization, 'Bearer secret-token');
  assert.equal(calls[0].init.body.get('id'), id);
  assert.equal(calls[0].init.body.get('requireSignedURLs'), 'false');
  assert.deepEqual(JSON.parse(calls[0].init.body.get('metadata')), {
    app: 'hamrash-admin',
    env: 'dev',
    kind: 'student-photos',
    uploader: 'user_1',
  });
});

test('reserves a video with creator and meta set at creation', async () => {
  const { deps, calls } = setup({ cloudflare: videoOk });
  const res = await handleMediaUpload(
    post({ type: 'video', app: 'hamrash-platform', kind: 'school-logos' }),
    deps,
  );
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), {
    id: 'vid1',
    uploadURL: 'https://upload.example/v1',
    url: 'https://customer-code.cloudflarestream.com/vid1/manifest/video.m3u8',
  });
  assert.match(calls[0].url, /\/accounts\/acct\/stream\/direct_upload$/);
  const sent = JSON.parse(calls[0].init.body);
  assert.equal(sent.creator, 'hamrash-platform/dev');
  assert.equal(sent.meta.uploader, 'user_1');
  assert.equal(sent.meta.kind, 'school-logos');
  assert.equal(sent.maxDurationSeconds, 300);
});

test('accepts the stream customer code or the whole address', async () => {
  for (const pasted of ['abc123', 'customer-abc123', 'customer-abc123.cloudflarestream.com']) {
    const { deps } = setup({ cloudflare: videoOk, streamCustomerCode: pasted });
    const res = await handleMediaUpload(
      post({ type: 'video', app: 'hamrash-admin', kind: 'school-logos' }),
      deps,
    );
    assert.equal(
      (await res.json()).url,
      'https://customer-abc123.cloudflarestream.com/vid1/manifest/video.m3u8',
      pasted,
    );
  }
});

test('hides Cloudflare errors from the app', async () => {
  const { deps } = setup({ cloudflare: { success: false, errors: [{ message: 'token detail' }] } });
  const res = await handleMediaUpload(
    post({ type: 'video', app: 'hamrash-admin', kind: 'school-logos' }),
    deps,
  );
  assert.equal(res.status, 502);
  assert.deepEqual(await res.json(), { error: 'upstream_failed' });
});

test('never returns the Cloudflare token', async () => {
  const { deps } = setup({ cloudflare: imageOk });
  const res = await handleMediaUpload(
    post({ type: 'image', app: 'hamrash-admin', kind: 'school-logos' }),
    deps,
  );
  assert.ok(!(await res.text()).includes('secret-token'));
});

// secrets.env.example is committed, so it must stay a blank template. Real
// values go in secrets.env, which git ignores. This fails if one is pasted
// into the template by mistake (CLERK_JWKS_URL is a public URL, so it may stay).
test('the committed secrets template holds no secret values', () => {
  const template = readFileSync(new URL('./secrets.env.example', import.meta.url), 'utf8');
  const filled = [...template.matchAll(/^([A-Z_]+)=(.+)$/gm)]
    .map(([, key]) => key)
    .filter((key) => key !== 'CLERK_JWKS_URL');
  assert.deepEqual(filled, [], 'put real values in secrets.env, not secrets.env.example');
});
