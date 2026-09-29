import { describe, expect, it } from "vitest";
import worker from "./index.js";

const token = "0123456789abcdef0123456789abcdef";
const secret = "test-server-secret";

function database() {
  const rows = new Map();
  return {
    rows,
    prepare() {
      let parameters;
      return {
        bind(...values) {
          parameters = values;
          return this;
        },
        async first() {
          return rows.has(parameters[0]) ? { data: rows.get(parameters[0]).data } : null;
        },
        async run() {
          rows.set(parameters[0], { data: parameters[1], updated_at: parameters[2] });
          return { success: true };
        },
      };
    },
  };
}

function request(method, path, body, authorization = `Bearer ${secret}`) {
  return new Request(`https://profiles.example${path}`, {
    method,
    headers: {
      authorization,
      ...(body === undefined ? {} : { "content-type": "application/json" }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

describe("profile worker", () => {
  it("requires the server secret", async () => {
    const response = await worker.fetch(request("GET", `/profiles/${token}`, undefined, "Bearer wrong"), {
      SERVER_SECRET: secret,
      DB: database(),
    });
    expect(response.status).toBe(401);
  });

  it("stores and retrieves JSON profiles", async () => {
    const env = { SERVER_SECRET: secret, DB: database() };
    const put = await worker.fetch(request("PUT", `/profiles/${token}`, { gems: 42, prestige: 3 }), env);
    expect(put.status).toBe(204);

    const get = await worker.fetch(request("GET", `/profiles/${token}`, undefined), env);
    expect(get.status).toBe(200);
    expect(await get.json()).toEqual({ gems: 42, prestige: 3 });
  });

  it("rejects invalid tokens and non-object JSON", async () => {
    const env = { SERVER_SECRET: secret, DB: database() };
    expect((await worker.fetch(request("GET", "/profiles/not-a-token", undefined), env)).status).toBe(400);
    expect((await worker.fetch(request("PUT", `/profiles/${token}`, ["not", "an", "object"]), env)).status).toBe(400);
  });

  it("rejects bodies over 64 KiB", async () => {
    const env = { SERVER_SECRET: secret, DB: database() };
    const largeProfile = { value: "x".repeat(64 * 1024) };
    const response = await worker.fetch(request("PUT", `/profiles/${token}`, largeProfile), env);
    expect(response.status).toBe(413);
  });

  it("returns 404 for an unknown profile", async () => {
    const response = await worker.fetch(request("GET", `/profiles/${token}`, undefined), {
      SERVER_SECRET: secret,
      DB: database(),
    });
    expect(response.status).toBe(404);
  });
});
