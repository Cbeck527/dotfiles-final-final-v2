# AGENTS.md

This file is the canonical assistant-facing guide for this repository. It replaces the old split between `AGENTS.md` and `CLAUDE.md`.

## Overview
This repository is a macOS Nix flake built around `nix-darwin`, Home Manager, and `nix-homebrew`.

Current flake outputs define two Darwin hosts:

- `beckbook-pro` (personal)
- `mac-h99xrph3j9` (work)

Both hosts are declared in `flake.nix` and build `aarch64-darwin` systems.

## Repository Layout

- `flake.nix`: flake inputs, overlays, formatter, and `darwinConfigurations`
- `Justfile`: primary operator workflow
- `local.just`: local overrides loaded by `mod local`
- `bootstrap/darwin.nix`: shared base Nix settings, shells, and `system.stateVersion`
- `machines/<hostname>/default.nix`: host-specific configuration entry points
- `modules/home-manager.nix`: shared Home Manager user configuration
- `modules/identity.nix`, `modules/git.nix`, `modules/gpg.nix`, `modules/tmux.nix`, `modules/emacs-macport.nix`: shared feature modules
- `modules/llms/default.nix` and `modules/llms/pi.nix`: shared LLM CLI package setup
- `modules/crush.nix`: Crush (Charmbracelet) Home Manager module via NUR — only imported on `beckbook-pro`
- `modules/darwin/defaults.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/packages.nix`, `modules/darwin/services.nix`: Darwin-only modules
- `scripts/audit-flake-inputs.sh`: flake input audit helper
- `etc/patches/tea-custom-headers.patch`: patch used by the custom `tea` overlay
- `etc/doc/`: documentation assets

Keep new config split by concern. Shared behavior belongs in `modules/*.nix`, Darwin-only behavior belongs in `modules/darwin/*.nix`, and host overrides belong in `machines/<hostname>/default.nix`.

## Commands
Use `just` from the repository root.

- `just switch`: apply the current host configuration with `darwin-rebuild switch`
- `just check`: run `nix flake check`
- `just build`: build `.#darwinConfigurations.<hostname>.system`
- `just fmt`: format `*.nix` files with `nix fmt`
- `just clean`: run `nix-collect-garbage`
- `just deep-clean`: delete old system generations, then garbage collect
- `just audit`: run `scripts/audit-flake-inputs.sh`
- `just update`: update all tracked flake input groups
- `just update-nix`, `just update-osx`, `just update-home`, `just update-extra`, `just update-llms`: update specific input groups
- `just lock`: relock all tracked flake input groups without updating them
- `just lock-nix`, `just lock-osx`, `just lock-home`, `just lock-extra`, `just lock-llms`: relock specific input groups

`Justfile` loads `local.just` with `mod local`. In this checkout, `check`, `build`, and `switch` are overridden to use the local private config at `~/.config/nix-config-private` via `--override-input nix-config-private "path:$HOME/.config/nix-config-private"`.

The `nx` fish function (defined in `modules/home-manager.nix`) wraps `just` for running nix-config recipes from any directory: `nx switch`, `nx check`, etc.

## Current Architecture

### Flake inputs
The main inputs currently include:

- `nixpkgs` on `nixpkgs-unstable`
- `nixpkgs-terraform-157` for the pinned Terraform overlay
- `nix-darwin`
- `home-manager`
- `nix-homebrew`
- pinned `homebrew-core`, `homebrew-cask`
- `fenix`
- `llm-agents-nix`
- private `nix-config-private`

### Overlays
`flake.nix` currently defines these overlays:

- `terraform-157`: exposes `terraform_1_5_7`
- `llm-agents`: exposes `claude-code`, `codex`, `pi`, and `qmd`
- `readwise-cli`: packages a pinned upstream release
- `tea`: packages a custom patched `tea` build using `etc/patches/tea-custom-headers.patch`
- `fenix`

### Shared configuration patterns

- `bootstrap/darwin.nix` owns shared Nix settings, trusted users, shell setup, and the Darwin state version.
- `modules/home-manager.nix` owns the shared user layer and imports `identity.nix`, `gpg.nix`, `git.nix`, `tmux.nix`, and `modules/llms`.
- `modules/darwin/homebrew.nix` defines the base cask set and the `custom.homebrew.excludeCasks` option used for host-specific filtering.
- `modules/darwin/packages.nix` adds Darwin-specific Home Manager packages.
- `modules/darwin/services.nix` currently defines the `services.caffeinate` launchd daemon option.
- GUI apps are surfaced via `targets.darwin.copyApps.directory = "Applications/HomeManager"`.
- Host files commonly extend `home-manager.users.<name>` and `homebrew.*` for per-machine customization.
- `modules/identity.nix` defines `options.identity` (name, email, gpgKey, githubUser) consumed by `git.nix` and `gpg.nix` via `config.identity.*`.

### Host-specific patterns
- `beckbook-pro`: sets `_module.args = { inherit username userHome; }` to pass username/userHome to all imported modules. Adds personal packages (qmd, readwise-cli, ffmpeg, terraform, SDR tools, etc.) and many additional casks.
- `mac-h99xrph3j9`: receives `username` via `_module.args` from its private module (not defined locally like `beckbook-pro`). Uses `nix.settings.trusted-users = lib.mkAfter [ username ]` to add the work user. Excludes the `contexts` cask via `custom.homebrew.excludeCasks`. Defines a local `datadog-pup` derivation and custom k9s views for Kubernetes work.

## Gotchas & Non-Obvious Patterns

### Nix implementation: Lix
This config uses **Lix** instead of standard Nix: `nix.package = pkgs.lix` in `modules/darwin/defaults.nix`. Don't assume CppNix-specific behavior.

### Formatter: nixfmt
`nix fmt` uses `nixfmt` (not nixpkgs-fmt, alejandra, or nixfmt-rfc-style). The formatter is declared in `flake.nix` as `formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt`.

### Relaxed sandbox for Emacs
Nix sandbox is set to `"relaxed"` (not the default `"true"`) because `modules/emacs-macport.nix` sets `__noChroot = true` on the Emacs derivation. Byte-compiling `url.el` triggers GnuTLS cert scanning of `/etc/ssl/certs`, which strict sandboxing blocks. If you change the Emacs derivation, this relationship must be maintained.

### Homebrew tap duplication
Taps are declared in **two places** — this is intentional:
1. `nix-homebrew.taps`: for linking to the pinned flake inputs (immutable taps)
2. `homebrew.taps`: for the generated Brewfile (uses short names like `homebrew/core` vs `homebrew/homebrew-core`)

Both must be kept in sync when adding or removing taps.

### Private config
Sensitive values live in a separate private flake: `nix-config-private`. It provides `darwinModules.<hostname>` for each host. `local.just` overrides `check`, `build`, and `switch` to use a local path instead of the remote. Never commit secrets or machine-private values.

### Nix config: accept-flake-config
`bootstrap/darwin.nix` sets `nix.settings.accept-flake-config = true`, which auto-accepts `nixConfig` from flakes (e.g. `extra-substituters`). This is what allows `flake.nix`'s `nixConfig.extra-substituters` to take effect without manual confirmation.

### Module args: username/userHome
`beckbook-pro` defines `username` and `userHome` locally and passes them via `_module.args`, making them available as function arguments to all imported modules. `mac-h99xrph3j9` receives `username` from its private module's `_module.args` instead. Modules that declare `username` or `userHome` as function parameters must be used on hosts that provide them.

### Ghostty theme override
`modules/home-manager.nix` configures Ghostty with `config-file = "?theme-override.ghostty"` — the `?` makes the config file optional. The `toggle-solarized` fish function creates/deletes `~/.config/ghostty/theme-override.ghostty` to switch between Solarized Dark and Light. Don't remove this without understanding the toggle mechanism.

### Fish `nx` wrapper
Users run nix-config operations via the `nx` fish function (e.g. `nx switch`), which wraps `just --justfile ~/.config/nix-config/Justfile --working-directory ~/.config/nix-config`. All just recipes can be run from any directory via `nx`.

### keep-outputs and keep-derivations
Both `nix.settings.keep-outputs` and `nix.settings.keep-derivations` are set to `true` in `bootstrap/darwin.nix`. This increases disk usage but prevents GC from breaking running processes.

## Editing Guidelines

- Use 2-space indentation in Nix files.
- Keep attribute sets easy to scan. Prefer one logical concern per block.
- Prefer small, composable modules over large monolithic files.
- Follow the existing naming pattern: `modules/<feature>.nix`, `modules/darwin/<feature>.nix`, and `machines/<hostname>/default.nix`.
- Keep shell scripts in `bash` with `set -euo pipefail`.
- When changing overlays or custom package sources in `flake.nix`, update hashes and any related files in `etc/patches/` together.
- When changing flake inputs, review both `flake.lock` and the output of `just audit`.

## Validation
There is no separate test suite in this repository.

- Minimum validation for config changes: `just check`
- Safer pre-apply validation: `just build`
- Run `just fmt` after editing Nix files
- Run `just audit` whenever `flake.lock` changes

## Commit And PR Guidance

- Prefer concise semantic commit messages. Scopes such as `flake:`, `darwin:`, `home-manager:`, or a host name are useful when they add clarity.
- Pull requests should say which hosts or modules changed, which validation commands were run, and whether `just switch` is still expected as a manual follow-up.
- Include screenshots only for documentation or visual asset changes under `etc/doc/`.

## Security

- Do not commit secrets or machine-private values.
- Sensitive settings belong in the private `nix-config-private` flake input or other untracked local configuration.
- Review `flake.lock` changes carefully before applying them to a live machine.
