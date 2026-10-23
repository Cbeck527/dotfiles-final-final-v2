# Bootstrap installer

A small Cloudflare Worker renders the bootstrap script for
`https://dotfiles.cmb.software/`. This directory contains the scaffold; the Worker
and domain must be deployed before using that URL.

```sh
curl -fsSL 'https://dotfiles.cmb.software/' | sh
curl -fsSL 'https://dotfiles.cmb.software/?host=coder' | sh
curl -fsSL 'https://dotfiles.cmb.software/?host=beckbook-pro&ref=trunk' | sh
curl -fsSL 'https://dotfiles.cmb.software/?ref=cb/new-machine&build=0' | sh
```

Quote URLs containing `&`. To inspect a script before running it:

```sh
curl -fsSL 'https://dotfiles.cmb.software/?host=coder' -o /tmp/bootstrap.sh
less /tmp/bootstrap.sh
sh /tmp/bootstrap.sh
```

## Options

| Parameter | Default | Behavior |
| --- | --- | --- |
| `host` | `auto` | One of `auto`, `beckbook-pro`, `mac-h99xrph3j9`, `sweetums`, or `coder`. Auto uses `coder` when `$CODER=true`, otherwise the macOS LocalHostName or Linux short hostname. |
| `ref` | `trunk` | Git branch or tag to clone. Commit hashes are not supported. |
| `build` | `1` | `1` builds the selected configuration; `0` installs Lix and clones only. |

The Worker validates parameters, rejects unknown/duplicate keys, and quotes values
as shell literals. Invalid requests return HTTP 400 with a shell script that exits
unsuccessfully even if the caller omits curl's `-f`. Responses use `no-store` so
caches do not reuse a script rendered with different options. Only `GET /` and
`HEAD /` are supported.

## What runs on the machine

1. Check prerequisites, host/platform, and any existing checkout.
2. Reuse Nix/Lix if available; otherwise download the
   [official Lix installer](https://lix.systems/install/) and install with flakes,
   `trusted-users = root <current-user>`, `accept-flake-config = true`, and
   `warn-dirty = false`, matching `just coder-bootstrap`. The installer uses
   `--no-confirm`; sudo may still request your password. Existing installations
   are not upgraded or reconfigured.
3. Load Nix into this shell, then clone the public repository over HTTPS to
   `~/.config/nix-config`. Configure the push URL to use SSH.
4. Unless `build=0`, run `nix build` for the Darwin system or Linux Home Manager
   activation package. Leave `result` in the checkout and print activation commands.

Run as your normal user with Bash, curl, Git, and sudo access available. On macOS,
install Apple's command line tools first (`xcode-select --install`). The `sh`
entrypoint passes a quoted heredoc to Bash, where `set -euo pipefail` applies.
The Lix installer is downloaded completely before it executes. The script's
`main` function is defined before it runs, so a truncated function does not start
installing anything.

An existing checkout must belong to this repository and already be on the requested
branch or detached at the requested tag. It is reused as-is, including local edits;
the installer never pulls, resets, or switches it. A failed clone may leave a
checkout requiring manual repair. Re-running after a successful build will build
again using Nix's normal cache behavior.

Builds currently support the flake's Apple Silicon Darwin hosts and x86-64 Linux
hosts. These are existing machine configurations, with fixed usernames and home
directories; `host` does not create or rename a machine configuration. For a new
host, use `build=0`, add its configuration, and build from the checkout.

The flake has a private SSH input. Set up GitHub SSH authentication and host trust
for it before building; the Worker never receives credentials. The installer leaves
`flake.lock` unchanged. Linux machines need the init setup supported by the default
Lix installer; unusual containers without systemd need a manual Lix installation
first.

Activation is manual. The script prints commands that work before `just` or
`darwin-rebuild` is on PATH. For Coder it also prints the bash login-shell step after Home Manager activation. It does not install Homebrew,
activate dotfiles, or change the login shell.

## Develop and validate

Requires Node.js 24+, pnpm 11.25.0, and ShellCheck for `pnpm check`.

```sh
cd installer
pnpm install --frozen-lockfile
pnpm check
pnpm dev
```

In another terminal, inspect the local script without executing it:

```sh
curl -fsS 'http://localhost:8787/?host=coder&build=0'
```

`pnpm check` generates Worker types, checks TypeScript, runs HTTP and mocked shell
tests, lints the Bash source, and bundles with `wrangler deploy --dry-run`.
Tests use a temporary home directory and command stubs; they do not install Lix,
clone from GitHub, or build/activate a real machine configuration.

- `src/index.ts`: HTTP routing and error responses.
- `src/options.ts`: query defaults and validation.
- `src/render.ts`: shell quoting and the `sh` entrypoint.
- `src/bootstrap.sh`: client-side bootstrap flow, bundled as text by Wrangler.

Add new query options in `options.ts`, render their values in `render.ts`, and use
them in `bootstrap.sh`. When adding host support, update both the query allowlist
and the shell's platform/output mapping.

## Deploy when ready

```sh
pnpm exec wrangler login
pnpm check
pnpm deploy
```

Select the account that owns the `cmb.software` zone. `wrangler.jsonc` declares
`dotfiles.cmb.software` as a
[Worker Custom Domain](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/).
Deploying creates the Worker and configures that hostname and its certificate;
workers.dev and preview URLs are disabled. No storage bindings or secrets are
needed by the Worker.
