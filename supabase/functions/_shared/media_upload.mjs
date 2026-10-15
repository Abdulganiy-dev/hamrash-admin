// Reserves a one-time Cloudflare upload URL for the signed-in user. The
// Cloudflare token stays here; the app only gets the URL, the media id and the
// public URL. Kept free of Deno APIs so `node --test` can run it.
// Ported from HireThem.

/**
 * Which media kinds each app may ask for. To let a new app upload, add it here,
 * give the app a `MediaKind` with the same `appName` and kinds, and extend the
 * test.
 */
export const ALLOWED_KINDS = {
  'hamrash-platform': ['school-logos'],
  'hamrash-admin': ['school-logos', 'staff-photos', 'student-photos', 'parent-photos'],
};

const CLOUDFLARE = 'https://api.cloudflare.com/client/v4';
const MAX_VIDEO_SECONDS = 300;

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

/**
 * deps:
 *  - verifyToken(token): resolves to the token's claims (`sub`), or throws
 *  - fetch, uuid(): injectable for tests
 *  - config: { accountId, apiToken, env, imagesAccountHash, streamCustomerCode }
 */
export async function handleMediaUpload(request, deps) {
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });

  const token = (request.headers.get('Authorization') ?? '').replace(/^Bearer /i, '');
  if (!token) return json(401, { error: 'unauthorized' });
  let claims;
  try {
    claims = await deps.verifyToken(token);
  } catch {
    return json(401, { error: 'unauthorized' });
  }
  if (!claims?.sub) return json(401, { error: 'unauthorized' });

  let body;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'invalid_json' });
  }
  const { type, app, kind } = body ?? {};
  if (type !== 'image' && type !== 'video') return json(400, { error: 'invalid_type' });
  if (!ALLOWED_KINDS[app]?.includes(kind)) return json(400, { error: 'invalid_app_or_kind' });

  const { config } = deps;
  // Accepts the code or the whole `customer-<code>.cloudflarestream.com` address.
  const streamCode = String(config.streamCustomerCode)
    .replace(/^customer-/, '')
    .replace(/\.cloudflarestream\.com.*$/, '');
  const name = deps.uuid();
  const labels = { app, env: config.env, kind, uploader: claims.sub };
  const headers = { Authorization: `Bearer ${config.apiToken}` };

  try {
    if (type === 'image') {
      const id = `${app}/${config.env}/${kind}/${name}`;
      const form = new FormData();
      form.set('id', id);
      form.set('requireSignedURLs', 'false');
      form.set('metadata', JSON.stringify(labels));
      const res = await deps.fetch(
        `${CLOUDFLARE}/accounts/${config.accountId}/images/v2/direct_upload`,
        { method: 'POST', headers, body: form },
      );
      const data = await res.json();
      if (!res.ok || !data?.success || !data.result?.uploadURL) throw new Error(JSON.stringify(data?.errors));
      return json(200, {
        id,
        uploadURL: data.result.uploadURL,
        url: `https://imagedelivery.net/${config.imagesAccountHash}/${id}/public`,
      });
    }

    const res = await deps.fetch(
      `${CLOUDFLARE}/accounts/${config.accountId}/stream/direct_upload`,
      {
        method: 'POST',
        headers: { ...headers, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          maxDurationSeconds: MAX_VIDEO_SECONDS,
          creator: `${app}/${config.env}`,
          meta: { ...labels, name },
        }),
      },
    );
    const data = await res.json();
    if (!res.ok || !data?.success || !data.result?.uploadURL || !data.result?.uid) {
      throw new Error(JSON.stringify(data?.errors));
    }
    return json(200, {
      id: data.result.uid,
      uploadURL: data.result.uploadURL,
      url: `https://customer-${streamCode}.cloudflarestream.com/${data.result.uid}/manifest/video.m3u8`,
    });
  } catch (error) {
    console.error('media-upload: Cloudflare reservation failed', error);
    return json(502, { error: 'upstream_failed' });
  }
}
