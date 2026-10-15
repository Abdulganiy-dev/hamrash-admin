import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.9.6';

import { handleMediaUpload } from '../_shared/media_upload.mjs';

// Deploy with --no-verify-jwt:
//   supabase functions deploy media-upload --no-verify-jwt --project-ref <ref>
// Supabase's own JWT check only knows tokens Supabase signed, and our users
// sign in with Clerk, so the gateway would reject every call. This function
// verifies the Clerk token itself (against Clerk's public keys) and answers 401
// to anything else, so nothing is left open.
//
// Secrets (set per Supabase project, never in the repo; see secrets.env.example):
//   CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN (Images Edit + Stream Edit only),
//   CLOUDFLARE_IMAGES_ACCOUNT_HASH, CLOUDFLARE_STREAM_CUSTOMER_CODE,
//   CLERK_JWKS_URL, MEDIA_ENV ('dev' | 'prod')
// A missing secret stops the function at startup and names the secret, instead
// of becoming an empty string that fails later or files media under the wrong
// environment.
const env = (name: string): string => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing secret: ${name}`);
  return value;
};

const jwks = createRemoteJWKSet(new URL(env('CLERK_JWKS_URL')));

Deno.serve((request) =>
  handleMediaUpload(request, {
    verifyToken: async (token: string) => (await jwtVerify(token, jwks)).payload,
    fetch,
    uuid: () => crypto.randomUUID(),
    config: {
      accountId: env('CLOUDFLARE_ACCOUNT_ID'),
      apiToken: env('CLOUDFLARE_API_TOKEN'),
      env: env('MEDIA_ENV'),
      imagesAccountHash: env('CLOUDFLARE_IMAGES_ACCOUNT_HASH'),
      streamCustomerCode: env('CLOUDFLARE_STREAM_CUSTOMER_CODE'),
    },
  }),
);
