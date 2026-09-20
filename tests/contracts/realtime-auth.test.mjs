import assert from "node:assert/strict";
import test from "node:test";
import { createGatewayRealtimeClient } from "../../packages/contracts/src/index.ts";

test("realtime client transports optional credentials without a URL secret", () => {
  let observed;
  class FakeSocket {
    constructor(...args) { observed = args; }
    addEventListener() {}
  }
  createGatewayRealtimeClient({ baseUrl: "http://localhost:8088", WebSocket: FakeSocket });
  assert.deepEqual(observed, ["ws://localhost:8088/api/v1/realtime"]);
  createGatewayRealtimeClient({ baseUrl: "http://localhost:8088", WebSocket: FakeSocket, authToken: "test credential" });
  assert.equal(observed[0], "ws://localhost:8088/api/v1/realtime");
  assert.equal(observed[1][0], "juliaflow");
  assert.equal(Buffer.from(observed[1][1].slice("juliaflow.bearer.".length), "base64url").toString("utf8"), "test credential");
});
