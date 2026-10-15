import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.9.6';

import { handleMediaDelete } from '../_shared/media_delete.mjs';

// Deletes one Cloudflare image by id, only for the person who uploaded it. See
// _shared/media_delete.mjs for the rules.
//
// Deploy with --no-verify-jwt, for the same reason as media-upload: Supabase's
// own JWT check only knows tokens Supabase signed, and our users sign in with
// Clerk. This function verifies the Clerk token itself and answers 401 to
// anything else.
//   supabase functions deploy media-delete --no-verify-jwt --project-ref <ref>
//
// Uses the same project secrets as media-upload, so there is nothing new to set:
//   CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN (Images Edit covers delete),
//   CLERK_JWKS_URL, MEDIA_ENV ('dev' | 'prod')
// A missing secret stops the function at startup and names the secret.
const env = (name: string): string => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing secret: ${name}`);
  return value;
};

const jwks = createRemoteJWKSet(new URL(env('CLERK_JWKS_URL')));

Deno.serve((request) =>
  handleMediaDelete(request, {
    verifyToken: async (token: string) => (await jwtVerify(token, jwks)).payload,
    fetch,
    config: {
      accountId: env('CLOUDFLARE_ACCOUNT_ID'),
      apiToken: env('CLOUDFLARE_API_TOKEN'),
      env: env('MEDIA_ENV'),
    },
  }),
);
