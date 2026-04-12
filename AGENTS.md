# AGENTS.md

This file is the canonical assistant-facing guide for this repository. It replaces the old split between `AGENTS.md` and `CLAUDE.md`.

## Overview
This repository is a macOS Nix flake built around `nix-darwin`, Home Manager, and `nix-homebrew`.

Current flake outputs define two Darwin hosts:

- `beckbook-pro`
- `mac-h99xrph3j9`

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

## Current Architecture

### Flake inputs
The main inputs currently include:

- `nixpkgs` on `nixpkgs-unstable`
- `nixpkgs-terraform-157` for the pinned Terraform overlay
- `nix-darwin`
- `home-manager`
- `nix-homebrew`
- pinned `homebrew-core` and `homebrew-cask`
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
- `modules/darwin/packages.nix` adds Darwin-specific packages, including the custom `clearance` package.
- `modules/darwin/services.nix` currently defines the `services.caffeinate` launchd daemon option.
- GUI apps are surfaced via `targets.darwin.copyApps.directory = "Applications/HomeManager"`.
- Host files commonly extend `home-manager.users.<name>` and `homebrew.*` for per-machine customization.

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
