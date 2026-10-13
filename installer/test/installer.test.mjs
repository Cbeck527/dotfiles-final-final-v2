import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { build } from "esbuild";

await build({
  entryPoints: ["src/index.ts"],
  bundle: true,
  format: "esm",
  platform: "node",
  loader: { ".sh": "text" },
  outfile: ".test/worker.mjs",
});
const { default: worker } = await import("../.test/worker.mjs");

const request = (query = "", method = "GET", path = "/") =>
  worker.fetch(new Request(`https://dotfiles.cmb.software${path}${query}`, { method }));

test("serves a shell script with defaults and a bodyless HEAD", async () => {
  const response = request();
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Content-Type"), "text/plain; charset=utf-8");
  assert.equal(response.headers.get("Cache-Control"), "no-store");
  const script = await response.text();
  assert.match(script, /^#!\/bin\/sh/);
  assert.match(script, /host='auto'\nref='trunk'\nbuild=1/);
  for (const shell of ["/bin/sh", "/bin/bash"]) {
    const syntax = spawnSync(shell, ["-n"], { input: script, encoding: "utf8" });
    assert.equal(syntax.status, 0, syntax.stderr);
  }
  const head = request("", "HEAD");
  assert.equal(head.status, 200);
  assert.equal(await head.text(), "");
});

test("renders all selected options", async () => {
  const script = await request("?host=coder&ref=cb/new-machine&build=0").text();
  assert.match(script, /host='coder'\nref='cb\/new-machine'\nbuild=0/);
});

test("rejects ambiguous, invalid, and injectable query values", async () => {
  for (const query of [
    "?host=unknown", "?host=", "?build=true", "?build=", "?ref=",
    "?host=coder&host=sweetums", "?ref=trunk&ref=other", "?extra=1",
    "?ref=-option", "?ref=a..b", "?ref=a//b", "?ref=a.lock", "?ref=a/.hidden",
    "?ref=a.", "?ref=a/", `?ref=${"a".repeat(129)}`,
    "?ref=%27%3Btouch%20%2Ftmp%2Fpwned", "?ref=%24%28id%29", "?ref=foo%0Aexit",
  ]) {
    const response = request(query);
    assert.equal(response.status, 400, query);
    const script = await response.text();
    const execution = spawnSync("/bin/sh", [], { input: script, encoding: "utf8" });
    assert.equal(execution.status, 1, query);
    assert.doesNotMatch(script, /git clone|install\.lix/);
  }
});

test("rejects unsupported paths and methods", async () => {
  assert.equal(request("", "GET", "/missing").status, 404);
  const response = request("", "POST");
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("Allow"), "GET, HEAD");
  const head = request("?build=no", "HEAD");
  assert.equal(head.status, 400);
  assert.equal(await head.text(), "");
});

test("builds the Linux activation package through sh and safely reuses a checkout", async (t) => {
  const machine = mockMachine(t);
  const script = await request("?host=coder").text();
  let result = machine.run(script);
  assert.equal(result.status, 0, result.stderr);
  assert.match(machine.log(), /git clone --branch trunk -- https:\/\/github.com\/Cbeck527\/dotfiles-final-final-v2.git/);
  assert.match(machine.log(), /--accept-flake-config build --no-write-lock-file .#homeConfigurations.coder.activationPackage/);
  assert.match(result.stdout, /CODER=true just hjem-switch/);
  machine.clearLog();
  result = machine.run(script);
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(machine.log(), /git clone|git .* (pull|reset|checkout|fetch) /);
  assert.doesNotMatch(machine.log(), /curl|sudo/);
});

test("auto detects Coder and each platform's hostname", async (t) => {
  for (const [env, output] of [
    [{ CODER: "true", MOCK_HOST: "throwaway" }, "homeConfigurations.coder.activationPackage"],
    [{ MOCK_HOST: "sweetums" }, "homeConfigurations.sweetums.activationPackage"],
    [{ MOCK_OS: "Darwin", MOCK_ARCH: "arm64", MOCK_HOST: "beckbook-pro" }, "darwinConfigurations.beckbook-pro.system"],
  ]) {
    const machine = mockMachine(t, env);
    const result = machine.run(await request().text());
    assert.equal(result.status, 0, result.stderr);
    assert.ok(machine.log().includes(`.#${output}`), machine.log());
    assert.doesNotMatch(machine.log(), /sudo|activate|hjem/);
  }
});

test("build=0 prepares an unknown host without invoking nix build", async (t) => {
  const machine = mockMachine(t, { MOCK_HOST: "new-machine" });
  const result = machine.run(await request("?ref=cb/new-machine&build=0").text());
  assert.equal(result.status, 0, result.stderr);
  assert.match(machine.log(), /git clone --branch cb\/new-machine/);
  assert.doesNotMatch(machine.log(), /nix .*build/);
});

test("rejects root, wrong platforms, unknown hosts, and blocked checkout paths before mutation", async (t) => {
  for (const env of [
    { MOCK_UID: "0" }, { MOCK_ARCH: "aarch64" }, { MOCK_OS: "FreeBSD" }, { MOCK_HOST: "unknown" },
  ]) {
    const machine = mockMachine(t, env);
    const result = machine.run(await request().text());
    assert.equal(result.status, 1);
    assert.doesNotMatch(machine.log(), /git clone|nix .*build|curl/);
  }
  const machine = mockMachine(t);
  mkdirSync(machine.checkout, { recursive: true });
  const result = machine.run(await request("?host=coder").text());
  assert.equal(result.status, 1);
  assert.match(result.stderr, /not a Git checkout/);
});

test("refuses to change an existing checkout's repository or branch", async (t) => {
  for (const env of [{ MOCK_ORIGIN: "https://example.com/other.git" }, { MOCK_BRANCH: "work-in-progress" }]) {
    const machine = mockMachine(t, env);
    mkdirSync(join(machine.checkout, ".git"), { recursive: true });
    const result = machine.run(await request("?host=coder").text());
    assert.equal(result.status, 1);
    assert.doesNotMatch(machine.log(), /git clone|git .* (pull|reset|checkout|fetch) |nix .*build/);
  }
});

test("propagates clone and build failures", async (t) => {
  for (const env of [{ MOCK_CLONE_FAIL: "1" }, { MOCK_BUILD_FAIL: "1" }]) {
    const machine = mockMachine(t, env);
    const result = machine.run(await request("?host=coder").text());
    assert.notEqual(result.status, 0);
    assert.doesNotMatch(result.stdout, /Built successfully/);
  }
});

function mockMachine(t, overrides = {}) {
  const root = mkdtempSync(join(tmpdir(), "nix-installer-test-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const home = join(root, "home with spaces");
  const bin = join(root, "bin");
  const log = join(root, "commands.log");
  mkdirSync(home);
  mkdirSync(bin);
  writeFileSync(log, "");
  symlinkSync("/bin/bash", join(bin, "bash"));
  symlinkSync("/bin/mkdir", join(bin, "mkdir"));
  const mock = readFileSync(new URL("commands.sh", import.meta.url), "utf8");
  for (const tool of ["id", "uname", "hostname", "scutil", "curl", "nix", "git"]) {
    writeFileSync(join(bin, tool), mock, { mode: 0o755 });
  }
  return {
    checkout: join(home, ".config/nix-config"),
    log: () => readFileSync(log, "utf8"),
    clearLog: () => writeFileSync(log, ""),
    run: (script) => spawnSync("/bin/sh", [], {
      input: script,
      encoding: "utf8",
      timeout: 5000,
      env: {
        HOME: home, PATH: bin, MOCK_LOG: log, MOCK_UID: "1000", CODER: "",
        MOCK_OS: "Linux", MOCK_ARCH: "x86_64", MOCK_HOST: "sweetums", MOCK_BRANCH: "trunk",
        MOCK_ORIGIN: "https://github.com/Cbeck527/dotfiles-final-final-v2.git",
        ...overrides,
      },
    }),
  };
}
