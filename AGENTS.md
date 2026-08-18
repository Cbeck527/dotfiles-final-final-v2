# AGENTS.md

This file is the canonical assistant-facing guide for this repository. It replaces the old split between `AGENTS.md` and `CLAUDE.md`.

## Overview
This repository is a Nix flake built around `nix-darwin`, Home Manager, and `nix-homebrew`.

Current flake outputs define two Darwin hosts and two pure Home Manager Linux hosts:

- `beckbook-pro` (personal)
- `mac-h99xrph3j9` (work)
- `sweetums` (Linux)
- `coder` (Linux, shared by all Coder workspaces)

All hosts are declared in `flake.nix`. Darwin hosts build `aarch64-darwin` systems, and `sweetums` and `coder` build `x86_64-linux` Home Manager activation packages.

## Repository Layout

- `flake.nix`: flake inputs, overlays, formatter, and host outputs
- `Justfile`: primary operator workflow
- `local.just`: local overrides loaded by `mod local`
- `hosts/darwin/<hostname>/default.nix`: nix-darwin host-specific configuration entry points
- `hosts/linux/<hostname>/default.nix`: pure Home Manager host-specific configuration entry points for non-NixOS Linux (`coder` is keyed by environment, not hostname)
- `hosts/linux/coder/hjem.nix`: Hjem-managed dotfiles for Coder workspaces (a Hjem module, not a Home Manager module)
- `hosts/linux/coder/dotfiles/`: raw dotfiles linked into `$HOME` by Hjem
- `lib/hjem.nix`: evaluates Hjem's per-user module standalone and emits a v3 manifest
- `modules/shared/machine.nix`: shared options for `machine.username` and `machine.home`
- `modules/shared/identity.nix`: shared identity options consumed by Git and GPG modules
- `modules/darwin/defaults.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/services.nix`, `modules/darwin/home-manager.nix`, `modules/darwin/emacs-macport.nix`: Darwin-only modules
- `modules/linux/nix.nix`: Linux Home Manager Nix client settings
- `modules/programs/git.nix`, `modules/programs/gpg.nix`, `modules/programs/tmux.nix`, `modules/programs/fish.nix`, `modules/programs/bash.nix`: reusable Home Manager program modules
- `modules/programs/llms/default.nix`, `modules/programs/llms/pi.nix`, `modules/programs/llms/omp.nix`: shared LLM CLI package setup
- `scripts/audit-flake-inputs.sh`: flake input audit helper
- `etc/patches/tea-custom-headers.patch`: patch used by the custom `tea` overlay
- `etc/doc/`: documentation assets

Keep new config split by evaluation type and concern. Darwin system behavior belongs in `modules/darwin/*.nix`, non-NixOS Linux Home Manager support belongs in `modules/linux/*.nix`, reusable Home Manager program modules belong in `modules/programs/*.nix`, shared options belong in `modules/shared/*.nix`, and host-specific choices belong in `hosts/<eval-type>/<hostname>/default.nix`.

## Commands
Use `just` from the repository root.

- `just switch`: apply the current host configuration. On Darwin, this runs `darwin-rebuild` in switch mode; on Linux, it builds `.#homeConfigurations.<hostname>.activationPackage` and runs `./result/activate`.
- `just check`: run `nix flake check`
- `just build`: build the current host's Darwin system or Home Manager activation package
- `just fmt`: format `*.nix` files with `nix fmt`
- `just login-shell-bash`: point the `/etc/passwd` login shell at `/bin/bash` (Linux; see the Coder login shell gotcha). Refuses to run until the fish handoff is linked into `~/.bashrc`.
- `just clean`: run `nix-collect-garbage`
- `just deep-clean`: delete old system generations, then garbage collect
- `just hjem-switch`: build the Hjem manifest and link dotfiles into `$HOME` (Coder workspaces only; `just switch` runs this automatically there)
- `just hjem-build`: build and validate the Hjem manifest without linking anything (Coder workspaces only)
- `just audit`: run `scripts/audit-flake-inputs.sh`
- `just update`: update all tracked flake input groups
- `just update-nix`, `just update-osx`, `just update-home`, `just update-extra`, `just update-llms`: update specific input groups
- `just lock`: relock all tracked flake input groups without updating them

`Justfile` loads `local.just` with `mod local`. Use `just local::check`, `just local::build`, and `just local::switch` for the local private config. Top-level `just check`, `just build`, and `just switch` do not use the local private path.

The `nx` fish function (defined in `modules/programs/fish.nix`) wraps `just` for running nix-config recipes from any directory: `nx switch`, `nx check`, `nx local::check`, etc.

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
- `hjem` (dotfile management, `coder` host only)
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
- `coder`: pure Home Manager Linux host under `hosts/linux/coder`, shared by every Coder workspace. Mirrors `sweetums` apart from `machine.username`/`machine.home` (`christopher-becker`), the Hjem CLI in `home.packages`, its dev/CLI tooling package set (including the fenix Rust toolchain, which is why its `pkgs` import applies `self.overlays.fenix`), and `custom.bash.fishHandoff.enable` (see the Coder login shell gotcha). Selected by hostname-independent `$CODER` detection in the `Justfile`. The only host using Hjem.

## Gotchas & Non-Obvious Patterns

### Nix implementation: Lix
This config uses **Lix** instead of standard Nix: `nix.package = pkgs.lix` in `modules/darwin/defaults.nix`. Don't assume CppNix-specific behavior.

### Formatter: treefmt-nix
`nix fmt` uses a `treefmt-nix` wrapper with `nixfmt` enabled. `flake.nix` declares the wrapper and its formatting check for both `aarch64-darwin` and `x86_64-linux`; `just fmt` runs the wrapper once for the repository.

### Relaxed sandbox for Emacs
Nix sandbox is set to `"relaxed"` (not the default `"true"`) because `modules/darwin/emacs-macport.nix` sets `__noChroot = true` on the Emacs derivation. Byte-compiling `url.el` triggers GnuTLS cert scanning of `/etc/ssl/certs`, which strict sandboxing blocks. If you change the Emacs derivation, this relationship must be maintained.

### Homebrew tap duplication
Taps are declared in **two places** — this is intentional:
1. `nix-homebrew.taps`: for linking to the pinned flake inputs (immutable taps)
2. `homebrew.taps`: for the generated Brewfile (uses short names like `homebrew/core` vs `homebrew/homebrew-core`)

Both must be kept in sync when adding or removing taps.

### Private config
Sensitive values live in a separate private flake: `nix-config-private`. It provides `darwinModules.<hostname>` for each Darwin host. Use `just local::check`, `just local::build`, or `just local::switch` when you need the local private path instead of the locked remote input. Never commit secrets or machine-private values.

### Nix config: accept-flake-config
`modules/darwin/defaults.nix` sets `nix.settings.accept-flake-config = true`, which auto-accepts `nixConfig` from flakes (e.g. `extra-substituters`). This is what allows `flake.nix`'s `nixConfig.extra-substituters` to take effect without manual confirmation.

### Coder workspace detection
Coder workspaces get a throwaway per-workspace hostname (e.g. `sloppy-joe`), so matching a flake output on `hostname` doesn't work there. The `Justfile` defines `target := if env('CODER', '') == "true" { "coder" } else { hostname }`, and `just build`/`just switch` use `{{ target }}`. Detection lives in the `Justfile` rather than `flake.nix` because reading environment variables during evaluation would require `--impure`. `$CODER` is set to `true` inside every Coder workspace.

### Coder login shell: bash, with a fish handoff
The Coder agent reads the login shell out of `/etc/passwd` and runs its own plumbing through it, so **fish must not be the login shell on a Coder workspace**. Two things break, and both were observed in `/tmp/coder-agent.log`:

- Template scripts **without a shebang** are piped to the login shell on stdin. Coder's default startup script is `set -e` plus a comment; fish reads that as `set --erase` with no argument, exits 2, and the agent reports lifecycle `start_error` — the workspace shows "startup script failed" in the UI even though nothing of substance failed. Scripts *with* a shebang are unaffected, which is why every other template script ran fine.
- Internal helpers are wrapped as `$SHELL -c 'cmd "$@"' -- args`. fish has no `$@`, so these exit 127. This kills devcontainer detection: `docker ps` fails, the container updater loop errors twice and stops for the life of the agent.

`modules/programs/bash.nix` therefore keeps bash as the login shell and defines `custom.bash.fishHandoff.enable`, which appends an `exec fish` to the end of `.bashrc` for interactive sessions only. The coder host enables it. Guards in that block (`$-`, a `__NIXCFG_FISH_HANDOFF` sentinel, `TERM`/`INSIDE_EMACS`, and a `command -v fish` existence check) are documented inline and are each load-bearing — read the comment before trimming any of them.

**Nix cannot own the `/etc/passwd` entry.** `chsh` is outside the Home Manager activation, so `just login-shell-bash` exists to set it and must be re-run after a workspace rebuild resets the passwd entry. Until it runs, the handoff is inert and fish is still the login shell.

Unrelated but adjacent: Coder modules that append to shell profiles fail on this host, because `~/.profile`, `~/.bashrc`, and `~/.config/fish/config.fish` are all read-only nix store symlinks. The `claude-code` module's `add_path_to_shell_profiles()` hits this and exits 1. It is harmless — `~/.local/bin` is already on `PATH` via `dotfiles/fish/conf.d/00-base.fish` — but it is a second, permanent red script in the Coder UI that is *not* a fish problem and should not be chased as one.

### Hjem (dotfiles) on the coder host
[Hjem](https://github.com/feel-co/hjem) manages `$HOME` files on Coder workspaces only. It is **not** a Home Manager module, and the two systems know nothing about each other:

- Hjem publishes module entry points for NixOS, nix-darwin, and Finix — but not for pure Home Manager hosts. `lib/hjem.nix` therefore evaluates Hjem's platform-agnostic per-user module (`modules/common/user.nix` inside the input, module class `"hjem"`) with `lib.evalModules`, then builds the v3 manifest the same way `modules/nixos/base.nix` does upstream. This reaches into the input's file layout, so a Hjem update can break it; the failure is a loud eval error, and the fix is to re-check `modules/common/user.nix` and `modules/nixos/base.nix` upstream. Hjem's `modules/nixos/systemd.nix` is deliberately not imported (it needs NixOS `utils`), so per-user systemd unit options are unavailable.
- **`just hjem-switch` builds the manifest before linking, and that ordering matters.** `hjem standalone switch --flake` links files *before* it realises their store paths, so any source that isn't already built — every file using `text` or `generator` — fails to activate with "source does not exist". The recipe instead builds `hjemConfigurations.<user>.manifestFile` (whose JSON string context pulls in every source) and passes the result to `--manifest`. The `manifest` attribute is still exposed for `nix eval` and for upstream's `--flake` workflow, with that caveat.
- New dotfiles must be `git add`ed before a switch sees them: the manifest is built from this repo as a git flake, so untracked files do not exist as far as Nix is concerned.
- Keep Hjem and Home Manager paths disjoint. Hjem defaults to `clobberFiles = false` here, so it backs up rather than overwrites existing paths (`.backup-` prefix), but nothing prevents the two from fighting over the same file.
- `nix flake check` warns `unknown flake output 'hjemConfigurations'`. That output name is the CLI's convention (`hjem standalone switch --flake` reads `hjemConfigurations."$USER"`), not a standard flake schema output. The warning is expected.
- State lives in `~/.local/state/hjem/standalone`. `hjem standalone generations`, `hjem standalone rollback`, and `hjem standalone expire-generations --keep-last N` manage it; there are no just recipes for those.

### Machine options: username/home
`modules/shared/machine.nix` defines darwin/Home Manager options for `machine.username` and `machine.home`. `beckbook-pro`, `sweetums`, and `coder` set them directly; `mac-h99xrph3j9` bridges them from the private module's `_module.args`. All modules that need the username or home directory read `config.machine.username` or `config.machine.home`.

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
