// Pieces both media functions share, kept in one place because the login check
// is security-critical. Free of Deno APIs so `node --test` can run it.

export const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

/**
 * The caller's Clerk user id, or null for anything but a valid login token.
 * `verifyToken(token)` resolves to the token's claims, or throws.
 */
export async function authenticate(request, verifyToken) {
  const token = (request.headers.get('Authorization') ?? '').replace(/^Bearer /i, '');
  if (!token) return null;
  try {
    const claims = await verifyToken(token);
    return claims?.sub ? String(claims.sub) : null;
  } catch {
    return null;
  }
}
