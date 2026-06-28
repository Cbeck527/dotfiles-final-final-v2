# AGENTS.md

This file is the canonical assistant-facing guide for this repository. It replaces the old split between `AGENTS.md` and `CLAUDE.md`.

## Overview
This repository is a Nix flake built around `nix-darwin`, Home Manager, and `nix-homebrew`.

Current flake outputs define two Darwin hosts and one pure Home Manager Linux host:

- `beckbook-pro` (personal)
- `mac-h99xrph3j9` (work)
- `sweetums` (Linux)

All hosts are declared in `flake.nix`. Darwin hosts build `aarch64-darwin` systems, and `sweetums` builds an `x86_64-linux` Home Manager activation package.

## Repository Layout

- `flake.nix`: flake inputs, overlays, formatter, and host outputs
- `Justfile`: primary operator workflow
- `local.just`: local overrides loaded by `mod local`
- `hosts/darwin/<hostname>/default.nix`: nix-darwin host-specific configuration entry points
- `hosts/linux/<hostname>/default.nix`: pure Home Manager host-specific configuration entry points for non-NixOS Linux
- `modules/shared/machine.nix`: shared options for `machine.username` and `machine.home`
- `modules/shared/identity.nix`: shared identity options consumed by Git and GPG modules
- `modules/darwin/defaults.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/services.nix`, `modules/darwin/home-manager.nix`, `modules/darwin/emacs-macport.nix`: Darwin-only modules
- `modules/linux/nix.nix`: Linux Home Manager Nix client settings
- `modules/programs/git.nix`, `modules/programs/gpg.nix`, `modules/programs/tmux.nix`, `modules/programs/fish.nix`: reusable Home Manager program modules
- `modules/programs/llms/default.nix`, `modules/programs/llms/pi.nix`, `modules/programs/llms/omp.nix`: shared LLM CLI package setup
- `modules/programs/llms/crush.nix`: Crush (Charmbracelet) Home Manager module via NUR, imported only on `beckbook-pro`
- `scripts/audit-flake-inputs.sh`: flake input audit helper
- `etc/patches/tea-custom-headers.patch`: patch used by the custom `tea` overlay
- `etc/doc/`: documentation assets

Keep new config split by evaluation type and concern. Darwin system behavior belongs in `modules/darwin/*.nix`, non-NixOS Linux Home Manager support belongs in `modules/linux/*.nix`, reusable Home Manager program modules belong in `modules/programs/*.nix`, shared options belong in `modules/shared/*.nix`, and host-specific choices belong in `hosts/<eval-type>/<hostname>/default.nix`.

## Commands
Use `just` from the repository root.

- `just switch`: apply the current host configuration with `darwin-rebuild switch`
- `just check`: run `nix flake check`
- `just build`: build the current host's Darwin system or Home Manager activation package
- `just fmt`: format `*.nix` files with `nix fmt`
- `just clean`: run `nix-collect-garbage`
- `just deep-clean`: delete old system generations, then garbage collect
- `just audit`: run `scripts/audit-flake-inputs.sh`
- `just update`: update all tracked flake input groups
- `just update-nix`, `just update-osx`, `just update-home`, `just update-extra`, `just update-llms`: update specific input groups
- `just lock`: relock all tracked flake input groups without updating them
- `just lock-nix`, `just lock-osx`, `just lock-home`, `just lock-extra`, `just lock-llms`: relock specific input groups

`Justfile` loads `local.just` with `mod local`. In this checkout, `check`, `build`, and `switch` are overridden to use the local private config at `~/.config/nix-config-private` via `--override-input nix-config-private "path:$HOME/.config/nix-config-private"`.

The `nx` fish function (defined in `modules/programs/fish.nix`) wraps `just` for running nix-config recipes from any directory: `nx switch`, `nx check`, etc.

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
- `charmbracelet` (Charm tools NUR)
- `llm-agents-nix`
- private `nix-config-private`

### Overlays
`flake.nix` currently defines these overlays:

- `terraform-157`: exposes `terraform_1_5_7`
- `llm-agents`: exposes `claude-code`, `codex`, `omp`, `pi`, and `qmd`
- `readwise-cli`: packages a pinned upstream release
- `tea`: packages a custom patched `tea` build using `etc/patches/tea-custom-headers.patch`
- `datadog-pup`: packages the DataDog `pup` binary for macOS arm64
- `fenix`

### Shared configuration patterns

- `modules/darwin/defaults.nix` owns shared Darwin Nix settings, trusted users, shell setup, sandbox config, garbage collection, and the Darwin state version.
- `modules/darwin/home-manager.nix` owns the Darwin Home Manager integration and imports shared Home Manager program modules.
- `modules/darwin/homebrew.nix` defines the base cask set and the `custom.homebrew.excludeCasks` option used for host-specific filtering.
- `modules/darwin/services.nix` currently defines the `services.caffeinate` launchd daemon option.
- GUI apps are surfaced via `targets.darwin.copyApps.directory = "Applications/HomeManager"`.
- Host files commonly extend `home-manager.users.<name>` and `homebrew.*` for per-machine customization.
- `modules/shared/identity.nix` defines `options.identity` (name, email, gpgKey, githubUser) consumed by `modules/programs/git.nix` and `modules/programs/gpg.nix` via `config.identity.*`.

### Host-specific patterns
- `beckbook-pro`: sets `machine.username` and `machine.home` directly. Adds personal packages (qmd, readwise-cli, ffmpeg, terraform, SDR tools, etc.) and many additional casks.
- `mac-h99xrph3j9`: bridges `machine.username` and `machine.home` from the private module's `_module.args`. Uses `nix.settings.trusted-users = lib.mkAfter [ username ]` to add the work user. Excludes the `contexts` cask via `custom.homebrew.excludeCasks`. Uses the `datadog-pup` overlay and custom k9s views for Kubernetes work.
- `sweetums`: pure Home Manager Linux host under `hosts/linux/sweetums`.

## Gotchas & Non-Obvious Patterns

### Nix implementation: Lix
This config uses **Lix** instead of standard Nix: `nix.package = pkgs.lix` in `modules/darwin/defaults.nix`. Don't assume CppNix-specific behavior.

### Formatter: nixfmt
`nix fmt` uses `nixfmt` (not nixpkgs-fmt, alejandra, or nixfmt-rfc-style). The formatter is declared in `flake.nix` as `formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt`.

### Relaxed sandbox for Emacs
Nix sandbox is set to `"relaxed"` (not the default `"true"`) because `modules/darwin/emacs-macport.nix` sets `__noChroot = true` on the Emacs derivation. Byte-compiling `url.el` triggers GnuTLS cert scanning of `/etc/ssl/certs`, which strict sandboxing blocks. If you change the Emacs derivation, this relationship must be maintained.

### Homebrew tap duplication
Taps are declared in **two places** — this is intentional:
1. `nix-homebrew.taps`: for linking to the pinned flake inputs (immutable taps)
2. `homebrew.taps`: for the generated Brewfile (uses short names like `homebrew/core` vs `homebrew/homebrew-core`)

Both must be kept in sync when adding or removing taps.

### Private config
Sensitive values live in a separate private flake: `nix-config-private`. It provides `darwinModules.<hostname>` for each host. `local.just` overrides `check`, `build`, and `switch` to use a local path instead of the remote. Never commit secrets or machine-private values.

### Nix config: accept-flake-config
`modules/darwin/defaults.nix` sets `nix.settings.accept-flake-config = true`, which auto-accepts `nixConfig` from flakes (e.g. `extra-substituters`). This is what allows `flake.nix`'s `nixConfig.extra-substituters` to take effect without manual confirmation.

### Machine options: username/home
`modules/shared/machine.nix` defines darwin/Home Manager options for `machine.username` and `machine.home`. `beckbook-pro` and `sweetums` set them directly; `mac-h99xrph3j9` bridges them from the private module's `_module.args`. All modules that need the username or home directory read `config.machine.username` or `config.machine.home`.

### Ghostty theme override
`modules/darwin/home-manager.nix` configures Ghostty with `config-file = "?theme-override.ghostty"` — the `?` makes the config file optional. The `toggle-solarized` fish function creates/deletes `~/.config/ghostty/theme-override.ghostty` to switch between Solarized Dark and Light. Don't remove this without understanding the toggle mechanism.

### Fish `nx` wrapper
Users run nix-config operations via the `nx` fish function (e.g. `nx switch`), which wraps `just --justfile ~/.config/nix-config/Justfile --working-directory ~/.config/nix-config`. All just recipes can be run from any directory via `nx`.

### keep-outputs and keep-derivations
Both `nix.settings.keep-outputs` and `nix.settings.keep-derivations` are set to `true` in `modules/darwin/defaults.nix`. This increases disk usage but prevents GC from breaking running processes.

## Editing Guidelines

- Use 2-space indentation in Nix files.
- Keep attribute sets easy to scan. Prefer one logical concern per block.
- Prefer small, composable modules over large monolithic files.
- Follow the existing naming pattern: `modules/<eval-type-or-concern>/<feature>.nix` and `hosts/<eval-type>/<hostname>/default.nix`.
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
