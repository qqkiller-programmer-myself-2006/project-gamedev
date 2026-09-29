const TOKEN = /^[0-9a-f]{32}$/;
const MAX_BODY_BYTES = 64 * 1024;

function constantTimeEqual(left, right) {
  const leftBytes = new TextEncoder().encode(left);
  const rightBytes = new TextEncoder().encode(right);
  let difference = leftBytes.length ^ rightBytes.length;
  const length = Math.max(leftBytes.length, rightBytes.length);

  for (let index = 0; index < length; index += 1) {
    difference |= (leftBytes[index] ?? 0) ^ (rightBytes[index] ?? 0);
  }

  return difference === 0;
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function isTooLarge(request) {
  const contentLength = request.headers.get("content-length");
  return contentLength !== null && Number.isFinite(Number(contentLength)) && Number(contentLength) > MAX_BODY_BYTES;
}

export default {
  async fetch(request, env) {
    const authorization = request.headers.get("authorization") ?? "";
    const prefix = "Bearer ";
    const suppliedSecret = authorization.startsWith(prefix) ? authorization.slice(prefix.length) : "";
    if (!env.SERVER_SECRET || !constantTimeEqual(suppliedSecret, env.SERVER_SECRET)) {
      return json({ error: "Unauthorized" }, 401);
    }

    const url = new URL(request.url);
    const match = url.pathname.match(/^\/profiles\/([^/]+)$/);
    if (!match || !TOKEN.test(match[1])) {
      return json({ error: "Invalid token" }, 400);
    }
    const token = match[1];

    if (request.method === "GET") {
      const row = await env.DB.prepare("SELECT data FROM profiles WHERE token = ?").bind(token).first();
      if (!row) {
        return json({ error: "Not found" }, 404);
      }
      return json(JSON.parse(row.data));
    }

    if (request.method === "PUT") {
      if (isTooLarge(request)) {
        return json({ error: "Request body too large" }, 413);
      }

      const body = await request.arrayBuffer();
      if (body.byteLength > MAX_BODY_BYTES) {
        return json({ error: "Request body too large" }, 413);
      }

      let profile;
      try {
        profile = JSON.parse(new TextDecoder().decode(body));
      } catch {
        return json({ error: "Invalid JSON" }, 400);
      }
      if (profile === null || typeof profile !== "object" || Array.isArray(profile)) {
        return json({ error: "JSON object required" }, 400);
      }

      await env.DB.prepare(
        "INSERT INTO profiles (token, data, updated_at) VALUES (?, ?, ?) ON CONFLICT(token) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at",
      ).bind(token, JSON.stringify(profile), Math.floor(Date.now() / 1000)).run();
      return new Response(null, { status: 204 });
    }

    return json({ error: "Method not allowed" }, 405);
  },
};

export { constantTimeEqual };
