// Deletes one image from Cloudflare Images by its id, for the signed-in user.
// The Cloudflare token stays here. Kept free of Deno APIs so `node --test` can
// run it.
//
// The token can delete ANY image in the account, so the function only acts when
// all of this holds:
//   1. the caller has a valid Clerk login;
//   2. the id is one of ours: `<app>/<env>/<kind>/<uuid>`, with an app and kind
//      on the upload allow-list, this project's environment, and a real uuid
//      (so nothing else in the account, and no odd path, ever reaches Cloudflare);
//   3. Cloudflare's own record of the image says THIS caller uploaded it, as
//      media-upload labelled it at the time.

import { authenticate, json } from './http.mjs';
import { isAllowed } from './media_upload.mjs';

const CLOUDFLARE = 'https://api.cloudflare.com/client/v4';
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * Splits `<app>/<env>/<kind>/<uuid>`, or returns null if `id` isn't exactly
 * that for an allowed app and kind in `env`.
 */
export function parseImageId(id, env) {
  if (typeof id !== 'string') return null;
  const parts = id.split('/');
  if (parts.length !== 4) return null;
  const [app, idEnv, kind, name] = parts;
  if (!isAllowed(app, kind)) return null;
  if (idEnv !== env) return null;
  if (!UUID.test(name)) return null;
  return { app, env: idEnv, kind, name };
}

/**
 * deps:
 *  - verifyToken(token): resolves to the token's claims (`sub`), or throws
 *  - fetch: injectable for tests
 *  - config: { accountId, apiToken, env }
 *
 * Answers: 200 { id, deleted: true } · 400 invalid_json / invalid_id ·
 * 401 unauthorized · 403 forbidden (not the uploader) · 404 not_found ·
 * 405 · 502 upstream_failed (Cloudflare's own error text is never passed on).
 */
export async function handleMediaDelete(request, deps) {
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' });

  const caller = await authenticate(request, deps.verifyToken);
  if (!caller) return json(401, { error: 'unauthorized' });

  let body;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'invalid_json' });
  }
  const { config } = deps;
  const parsed = parseImageId(body?.id, config.env);
  if (!parsed) return json(400, { error: 'invalid_id' });

  const id = body.id;
  // Cloudflare requires the id fully URL encoded; the slashes become %2F.
  const url = `${CLOUDFLARE}/accounts/${config.accountId}/images/v1/${encodeURIComponent(id)}`;
  const headers = { Authorization: `Bearer ${config.apiToken}` };

  try {
    const found = await deps.fetch(url, { method: 'GET', headers });
    if (found.status === 404) return json(404, { error: 'not_found' });
    const details = await found.json();
    if (!found.ok || !details?.success) throw new Error(JSON.stringify(details?.errors));

    // Cloudflare's record of who uploaded it, written by media-upload.
    const meta = details.result?.meta;
    const theirs =
      meta?.uploader === caller &&
      meta?.app === parsed.app &&
      meta?.env === parsed.env &&
      meta?.kind === parsed.kind;
    if (!theirs) return json(403, { error: 'forbidden' });

    const removed = await deps.fetch(url, { method: 'DELETE', headers });
    if (removed.status === 404) return json(404, { error: 'not_found' });
    const result = await removed.json();
    if (!removed.ok || !result?.success) throw new Error(JSON.stringify(result?.errors));
    return json(200, { id, deleted: true });
  } catch (error) {
    console.error('media-delete: Cloudflare request failed', error);
    return json(502, { error: 'upstream_failed' });
  }
}
