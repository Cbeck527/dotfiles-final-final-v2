# AGENTS.md

This file is the canonical assistant-facing guide for this repository. It replaces the old split between `AGENTS.md` and `CLAUDE.md`.

## Overview
This repository is a Nix flake built around `nix-darwin`, Home Manager, and `nix-homebrew`.

Current flake outputs define two Darwin hosts, one NixOS host, and one pure Home Manager Linux host:

- `beckbook-pro` (personal)
- `mac-h99xrph3j9` (work)
- `sweetums` (NixOS VPS)
- `coder` (Linux, shared by all Coder workspaces)

All hosts are declared in `flake.nix`. Darwin hosts build `aarch64-darwin` systems, `nixosConfigurations.sweetums` builds an `x86_64-linux` NixOS system, and `coder` builds an `x86_64-linux` Home Manager activation package.

## Repository Layout

- `flake.nix`: flake inputs, overlays, formatter, and host outputs
- `Justfile`: primary operator workflow
- `local.just`: local overrides loaded by `mod local`
- `hosts/darwin/<hostname>/default.nix`: nix-darwin host-specific configuration entry points
- `hosts/nixos/<hostname>/default.nix`: NixOS host-specific configuration entry points, next to that host's `hardware-configuration.nix`
- `hosts/linux/<hostname>/default.nix`: pure Home Manager host-specific configuration entry points for non-NixOS Linux (`coder` is keyed by environment, not hostname)
- `modules/shared/machine.nix`: shared options for `machine.username` and `machine.home`
- `modules/shared/identity.nix`: shared identity options consumed by Git and GPG modules
- `modules/shared/nix.nix`: Nix settings common to every host (Lix, flakes, `accept-flake-config`, `warn-dirty`); imported by nix-darwin, NixOS, and standalone Home Manager alike
- `modules/home/base.nix`, `modules/home/dev.nix`, `modules/home/darwin.nix`: Home Manager layers (see Configuration layers)
- `modules/darwin/defaults.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/services.nix`, `modules/darwin/emacs-macport.nix`: Darwin-only system modules
- `modules/darwin/user.nix`: the primary macOS user account (`home`, `description`), built from `config.machine.*`
- `modules/nixos/defaults.nix`: shared NixOS system settings (trusted users, GC, no channels, `git`/`just`)
- `modules/nixos/user.nix`: the primary NixOS user account, built from `config.machine.*` (wheel, fish login shell, no password)
- `packages/git.nix`, `packages/gpg.nix`, `packages/tmux.nix`, `packages/fish.nix`, `packages/bash.nix`, `packages/my-prompt.nix`, `packages/k9s.nix`: reusable Home Manager program modules
- `packages/llms/default.nix`, `packages/llms/pi.nix`, `packages/llms/omp.nix`: shared LLM CLI package setup
- `packages/tea.nix`, `packages/datadog-pup.nix`: `callPackage`-style derivations, exposed through the overlays of the same name in `flake.nix`
- `scripts/audit-flake-inputs.sh`: flake input audit helper
- `etc/doc/`: documentation assets
- `installer/`: Cloudflare Worker that renders the bootstrap script served at `dotfiles.cmb.software` (TypeScript, its own `flake.nix` and pnpm workspace; see `installer/README.md`)

Keep new config split by evaluation type and concern. Darwin system behavior belongs in `modules/darwin/*.nix`, NixOS system behavior belongs in `modules/nixos/*.nix`, Home Manager configuration belongs in the `modules/home/*.nix` layer that matches which hosts should get it (each host file imports its layers explicitly), reusable Home Manager program modules belong in `packages/*.nix`, custom package derivations belong in `packages/<name>.nix` (wired up via an overlay in `flake.nix`), shared options belong in `modules/shared/*.nix`, and host-specific choices belong in `hosts/<eval-type>/<hostname>/default.nix`.

## Commands
Use `just` from the repository root.

- `just switch`: apply the current host configuration. On Darwin, this runs `darwin-rebuild` in switch mode; on NixOS (detected by `/etc/NIXOS`), it runs `sudo nixos-rebuild switch`; on other Linux, it builds `.#homeConfigurations.<hostname>.activationPackage` and runs `./result/activate`.
- `just deploy <host> <user@address>`: switch a NixOS host over SSH from another machine. Evaluation happens locally (so the private input resolves with local credentials); building and activation happen on the target.
- `just check`: run `nix flake check`
- `just build`: build the current host's Darwin system, NixOS system, or Home Manager activation package
- `just fmt`: format `*.nix` files with `nix fmt`
- `just coder-bootstrap`: install Lix and clone this repo to `~/.config/nix-config` on a fresh Coder workspace (see Coder workspace detection)
- `just login-shell-bash`: point the `/etc/passwd` login shell at `/bin/bash` (Linux; see the Coder login shell gotcha). Refuses to run until the fish handoff is linked into `~/.bashrc`.
- `just clean`: run `nix-collect-garbage`
- `just deep-clean`: delete old system generations, then garbage collect
- `just audit`: run `scripts/audit-flake-inputs.sh`
- `just update`: update all tracked flake input groups
- `just update-nix`, `just update-osx`, `just update-home`, `just update-extra`, `just update-llms`: update specific input groups (private recipes, hidden from `just --list`)
- `just lock`: lock missing flake inputs without updating existing lock entries

Linux-only recipes (`login-shell-bash`, `coder-bootstrap`) don't appear in `just --list` on macOS.

`Justfile` loads `local.just` with `mod local`. Use `just local::check`, `just local::build`, and `just local::switch` for the local private config. Top-level `just check`, `just build`, and `just switch` do not use the local private path.

The `nx` fish function (defined in `packages/fish.nix`) wraps `just` for running nix-config recipes from any directory: `nx switch`, `nx check`, `nx local::check`, etc.

## Current Architecture

### Flake inputs
The main inputs currently include:

- `nixpkgs` on `nixpkgs-unstable`
- `nixpkgs-terraform-157` for the pinned Terraform overlay
- `nix-darwin`
- `home-manager`
- `nix-homebrew`
- pinned `homebrew-core`, `homebrew-cask`
- `treefmt-nix`
- `fenix`
- `llm-agents-nix`
- `my-prompt` (prompt binary, with its own Cachix cache)
- `attic` (attic-client)
- private `nix-config-private`

### Overlays
`flake.nix` currently defines these overlays:

- `terraform-157`: exposes `terraform_1_5_7`
- `llm-agents`: exposes `claude-code`, `codex`, `omp`, and `pi`
- `tea`: calls `packages/tea.nix`, which packages prebuilt release binaries from the `chrisbecker/tea` fork (custom HTTP headers support), with a per-system asset/hash table
- `datadog-pup`: calls `packages/datadog-pup.nix`, which packages the DataDog `pup` binary for macOS arm64
- `fenix`

### Configuration layers
Hosts differ along two axes — platform (nix-darwin, NixOS, standalone Home Manager) and role (workstation, server, dev box) — so system config is layered by platform and Home Manager config by role. Home Manager layers are plain HM modules (no `home-manager.users` wrapper), so the same file works embedded in nix-darwin/NixOS or standalone.

There is no shared Home Manager wiring module. Every host file spells out its own Home Manager setup, by design: repetition is preferred over indirection, so a host file alone shows what its user gets. On nix-darwin and NixOS hosts that means one `home-manager = { useGlobalPkgs; useUserPackages; backupFileExtension = "hm-backup"; extraSpecialArgs = { inherit inputs; }; }` block, then `home-manager.users.<name>` with an `imports` list of `modules/home/*.nix` layers, `home.stateVersion`, and host-specific settings. `coder` imports the same layers at the top level of its standalone Home Manager config. Keep the layer order `base` → `darwin` → `dev` → extras: `home.packages` order follows import order, and changing it changes the derivation hash without changing the package set. Inside them, use `config.home.homeDirectory`, not `config.machine.*`: the `machine` options exist at the system level, not in the HM module scope on Darwin/NixOS.

| Layer | Contents | Imported by |
| --- | --- | --- |
| `modules/shared/nix.nix` | Lix, flakes, `accept-flake-config`, `warn-dirty` | `modules/darwin/defaults.nix`, `modules/nixos/defaults.nix`, `coder` |
| `modules/home/base.nix` | identity, fish (abbrs, functions, key binds, solarized colors), git, gpg, tmux, my-prompt, `xdg.enable` and the shared session variables/PATH, direnv, ripgrep, bat, eza (fish functions; HM's eza aliases off), fzf (atuin owns Ctrl-R), attic-client, atuin, nh, uv, and the core CLI package set (including `zmx`) | every host |
| `modules/home/darwin.nix` | copyApps, `nh.darwinFlake`, Ghostty and `toggle-solarized`, macOS session variables, abbrs, and Emacs.app PATH entries, and the macOS workstation package set | both Darwin hosts |
| `modules/home/dev.nix` | k9s (`packages/k9s.nix`), zoxide (`j`), XDG-relocated language toolchain variables, and dev tooling: Go, Node, Python, the fenix Rust toolchain, language servers, Docker/Kubernetes/AWS CLIs | `beckbook-pro`, `mac-h99xrph3j9`, `coder` |

`home.stateVersion` is set in each host file, never in a shared layer: `25.05` on both Darwin hosts and `coder`, `26.05` on `sweetums`. Settings that differ per host (e.g. `custom.git.extras.enable`, off on `coder`) are set in the narrower layer or host file rather than overridden with `mkForce`.

`flake.nix` applies one overlay list, `hostOverlays`, to every host's `pkgs`, so a shared layer can use any overlaid package. Darwin hosts are built with `mkDarwin <hostname>`, which also pulls in `nix-config-private.darwinModules.<hostname>`.

### Shared configuration patterns

- `modules/darwin/defaults.nix` owns Darwin-specific Nix settings (sandbox, trusted users, `keep-*`, GC), shell setup, `system.defaults`, and the Darwin state version.
- `modules/darwin/user.nix` declares the existing macOS user account (`home`, `description`) for nix-darwin and Home Manager; it does not create the user.
- `modules/darwin/homebrew.nix` defines the base cask set and the `custom.homebrew.excludeCasks` option used for host-specific filtering.
- `modules/darwin/services.nix` currently defines the `services.caffeinate` launchd daemon option.
- GUI apps are surfaced via `targets.darwin.copyApps.directory = "Applications/HomeManager"`.
- Host files commonly extend `home-manager.users.<name>` and `homebrew.*` for per-machine customization.
- `modules/shared/identity.nix` defines `options.identity` (name, email, gpgKey, githubUser) consumed by `packages/git.nix` and `packages/gpg.nix` via `config.identity.*`.

### Host-specific patterns
- `beckbook-pro`: sets `machine.username` and `machine.home` directly. Imports `packages/llms` on top of the `base`/`darwin`/`dev` layers, points atuin at a self-hosted sync server, adds a few personal packages (ffmpeg, cowsay, fortune), and many additional casks. `modules/darwin/emacs-macport.nix` is commented out in favor of a manual Emacs build.
- `mac-h99xrph3j9`: bridges `machine.username` and `machine.home` from the private module's `_module.args`. Uses `nix.settings.trusted-users = lib.mkAfter [ username ]` to add the work user. Excludes the `contexts` cask via `custom.homebrew.excludeCasks`. Uses the `datadog-pup` overlay and custom k9s views for Kubernetes work.
- `sweetums` (NixOS): a KVM VPS booting via BIOS with GRUB on `/dev/vda`. `hardware-configuration.nix` was copied from the provider's install and should only change if the disk layout does. The host file holds the SSH public keys, shared by `root` and `chris`. `chris` has no password and gets passwordless sudo through `security.sudo.wheelNeedsPassword = false`. Home Manager runs as a NixOS module, so `just switch` applies system and user config together. The host imports only the `base` layer, plus a few packages and the headless git settings, all under `home-manager.users.<name>`. SSH hardening (disabling root login) is the planned next step. The same VPS ran Debian with a standalone `homeConfigurations.sweetums` until it was reinstalled with NixOS.
- `coder`: pure Home Manager Linux host under `hosts/linux/coder`, shared by every Coder workspace. Imports `modules/shared/nix.nix`, `modules/home/base.nix`, `modules/home/dev.nix`, and `packages/bash.nix` directly. The host file adds `machine.username`/`machine.home` (`christopher-becker`), Coder-only packages (`delta`, `herdr`) in `home.packages`, headless git settings, and `custom.bash.fishHandoff.enable` (see the Coder login shell gotcha). Selected by hostname-independent `$CODER` detection in the `Justfile`.

## Gotchas & Non-Obvious Patterns

### Nix implementation: Lix
This config uses **Lix** instead of standard Nix: `nix.package = pkgs.lix` in `modules/shared/nix.nix`, which every host imports. Don't assume CppNix-specific behavior.

### Formatter: treefmt-nix
`nix fmt` uses a `treefmt-nix` wrapper with `nixfmt` enabled. `flake.nix` declares the wrapper and its formatting check for `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`; `just fmt` runs the wrapper once for the repository.

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
`modules/shared/nix.nix` sets `nix.settings.accept-flake-config = true` on every host, which auto-accepts `nixConfig` from flakes (e.g. `extra-substituters`). This is what allows `flake.nix`'s `nixConfig.extra-substituters` to take effect without manual confirmation.

### Coder workspace detection
Coder workspaces get a throwaway per-workspace hostname (e.g. `sloppy-joe`), so matching a flake output on `hostname` doesn't work there. The `Justfile` defines `target := if env('CODER', '') == "true" { "coder" } else { hostname }`, and `just build`/`just switch` use `{{ target }}`. Detection lives in the `Justfile` rather than `flake.nix` because reading environment variables during evaluation would require `--impure`. `$CODER` is set to `true` inside every Coder workspace. Fresh workspaces are bootstrapped with `just coder-bootstrap`: it runs the Lix installer with `NIX_INSTALLER_ENABLE_FLAKES=true` and `--extra-conf` for `trusted-users`, `accept-flake-config`, and `warn-dirty`, then clones this repo to `~/.config/nix-config`. It is idempotent (skips when `/nix/receipt.json` or the checkout exists) and needs `just`, `git`, and `curl` on the image before Nix exists. Do not pass the installer's `--enable-flakes` flag: flakes default to on and the flag is a toggle that turns them off (verified with `nix-installer plan linux --enable-flakes`, which emits `extra-experimental-features = nix-command` without `flakes`).

### Coder login shell: bash, with a fish handoff
The Coder agent reads the login shell out of `/etc/passwd` and runs its own plumbing through it, so **fish must not be the login shell on a Coder workspace**. Two things break, and both were observed in `/tmp/coder-agent.log`:

- Template scripts **without a shebang** are piped to the login shell on stdin. Coder's default startup script is `set -e` plus a comment; fish reads that as `set --erase` with no argument, exits 2, and the agent reports lifecycle `start_error` — the workspace shows "startup script failed" in the UI even though nothing of substance failed. Scripts *with* a shebang are unaffected, which is why every other template script ran fine.
- Internal helpers are wrapped as `$SHELL -c 'cmd "$@"' -- args`. fish has no `$@`, so these exit 127. This kills devcontainer detection: `docker ps` fails, the container updater loop errors twice and stops for the life of the agent.

`packages/bash.nix` therefore keeps bash as the login shell and defines `custom.bash.fishHandoff.enable`, which appends an `exec fish` to the end of `.bashrc` for interactive sessions only. The coder host enables it. Guards in that block (`$-`, a `__NIXCFG_FISH_HANDOFF` sentinel, `TERM`/`INSIDE_EMACS`, and a `command -v fish` existence check) are documented inline and are each load-bearing — read the comment before trimming any of them.

**Nix cannot own the `/etc/passwd` entry.** `chsh` is outside the Home Manager activation, so `just login-shell-bash` exists to set it and must be re-run after a workspace rebuild resets the passwd entry. Until it runs, the handoff is inert and fish is still the login shell.

Unrelated but adjacent: Coder modules that append to shell profiles fail on this host, because `~/.profile`, `~/.bashrc`, and `~/.config/fish/config.fish` are all read-only nix store symlinks. The `claude-code` module's `add_path_to_shell_profiles()` hits this and exits 1. It is harmless — `~/.local/bin` is already on `PATH` via `home.sessionPath` in `modules/home/base.nix` — but it is a second, permanent red script in the Coder UI that is *not* a fish problem and should not be chased as one.

### NixOS hosts
- **Lockout risk.** A bad `users`, `services.openssh`, or `networking` change can lock you out of a remote host. Use `nixos-rebuild dry-activate` (or `switch-to-configuration dry-activate` on a built system) to see which units will restart, and keep an existing SSH session open while confirming a switch from a second one. GRUB keeps previous generations for rollback, but on a VPS reaching GRUB means the provider's console.
- **No channels.** `nix.channel.enable = false` in `modules/nixos/defaults.nix`; `NIX_PATH` resolves `nixpkgs` through the flake registry (`nixpkgs=flake:nixpkgs`), which `nixosSystem` pins to this flake's `nixpkgs` input.
- **`nixpkgs-unstable`.** NixOS hosts build from the same `nixpkgs-unstable` input as everything else, not from a stable `nixos-YY.MM` branch.
- **Builds on the target don't see the flake's extra caches.** `nixConfig.extra-substituters` only applies when Nix evaluates the flake locally. `just deploy` builds on the target through its own daemon, so a cache an input needs must also be in the host's `nix.settings.substituters`/`trusted-public-keys` (`sweetums` adds `my-prompt.cachix.org`). The first deploy after adding a cache still builds without it, since the daemon only reads the new `nix.conf` once that generation is active.
- **Cached inputs must not `follows` our nixpkgs.** An input's CI cache only holds builds made against that input's own locked nixpkgs. `my-prompt` therefore has no `inputs.nixpkgs.follows` in `flake.nix`; adding one changes its derivation and every host compiles it from source again.
- **Fish is the login shell.** Unlike the `coder` host, nothing on a NixOS host runs plumbing through the login shell from `/etc/passwd`, so `modules/nixos/user.nix` sets fish directly and `custom.bash.fishHandoff` is not used.
- **No password on the primary user.** `modules/nixos/user.nix` sets none, so each host must either set `security.sudo.wheelNeedsPassword = false` or give the user a `hashedPassword`; otherwise `sudo` is unusable.
- **`stateVersion`.** `sweetums` was raised from the installer's `23.11` to `26.05` before it ran any stateful service (the two built byte-identical systems). Don't change it again without reading the release notes.

### Machine options: username/home
`modules/shared/machine.nix` defines darwin/Home Manager options for `machine.username` and `machine.home`. `beckbook-pro`, `sweetums`, and `coder` set them directly; `mac-h99xrph3j9` bridges them from the private module's `_module.args`. All modules that need the username or home directory read `config.machine.username` or `config.machine.home`.

### Ghostty theme override
`modules/home/darwin.nix` configures Ghostty with `config-file = "?theme-override.ghostty"` — the `?` makes the config file optional. The `toggle-solarized` fish function creates/deletes `~/.config/ghostty/theme-override.ghostty` to switch between Solarized Dark and Light. Don't remove this without understanding the toggle mechanism.

### Fish `nx` wrapper
Users run nix-config operations via the `nx` fish function (e.g. `nx switch`), which wraps `just --justfile ~/.config/nix-config/Justfile --working-directory ~/.config/nix-config`. All just recipes can be run from any directory via `nx`.

### keep-outputs and keep-derivations
Both `nix.settings.keep-outputs` and `nix.settings.keep-derivations` are set to `true` in `modules/darwin/defaults.nix` and `modules/nixos/defaults.nix`. This increases disk usage but prevents GC from breaking running processes.

## Editing Guidelines

- Use 2-space indentation in Nix files.
- Keep attribute sets easy to scan. Prefer one logical concern per block.
- Prefer small, composable modules over large monolithic files.
- Follow the existing naming pattern: `modules/<eval-type-or-concern>/<feature>.nix` and `hosts/<eval-type>/<hostname>/default.nix`.
- Keep shell scripts in `bash` with `set -euo pipefail`.
- When changing overlays in `flake.nix` or package sources in `packages/`, update every hash together (e.g. all per-system assets in `packages/tea.nix` when bumping its version).
- When changing flake inputs, review both `flake.lock` and the output of `just audit`.

## Validation
There is no separate test suite in this repository.

- Minimum validation for config changes: `just check`. It does **not** evaluate `darwinConfigurations` (`nix flake check` skips that output), so a broken Darwin host passes; also run `nix eval --raw .#darwinConfigurations.<host>.system.drvPath`. `mac-h99xrph3j9` only evaluates on a machine with access to the private repos its private module fetches; elsewhere, eval individual options (`config.home-manager.users`, `config.homebrew.casks`) and leave the full build to the work machine.
- Refactors that should not change behavior: compare each host's top-level `drvPath` before and after. Identical paths prove a no-op; otherwise use `nix-diff` on the two `.drv` files. Moving `home.packages` between layers, or reordering a host's Home Manager `imports`, reorders `buildEnv` paths and changes the hash without changing the set — compare sorted package names to confirm.
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
