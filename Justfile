# nix-config Justfile

# List available recipes
default:
    @just --list

IMPURE := "false"

hostname := `hostname`

# Coder workspaces get a throwaway per-workspace hostname, so they all share the
# `coder` config instead of matching on hostname. $CODER is set in the workspace.
target := if env('CODER', '') == "true" { "coder" } else { hostname }

impure := if IMPURE == "true" { "--impure" } else { "" }

# Hjem manages dotfiles on Coder workspaces only, out of band from Home Manager
hjem_manifest := '.#hjemConfigurations."' + `id -un` + '".manifestFile'
hjem_hook := if target == "coder" { "just hjem-switch" } else { "true" }

# Build and apply using local private config
mod local

NIX_CHANNELS := "nixpkgs treefmt-nix"
HOME_CHANNELS := "home-manager"
OSX_CHANNELS := "nix-darwin nix-homebrew homebrew-core homebrew-cask"
EXTRA_CHANNELS := "fenix my-prompt attic nix-config-private hjem"
LLM_CHANNELS := "llm-agents-nix"

# Apply config for current hostname
[macos]
[group('build')]
switch:
    sudo darwin-rebuild switch {{ impure }} --verbose --flake ".#{{ target }}" --fallback

[linux]
[group('build')]
switch:
    nix build ".#homeConfigurations.{{ target }}.activationPackage"
    # Standalone Home Manager has no `backupFileExtension` option (that lives on
    # the NixOS/nix-darwin wrapper modules), so pass it through the env vars the
    # activation script reads directly.
    HOME_MANAGER_BACKUP_EXT=hm-backup HOME_MANAGER_BACKUP_OVERWRITE=1 ./result/activate
    {{ hjem_hook }}

# Link Hjem-managed dotfiles into $HOME (Coder only)
# The manifest is built first so every source exists before hjem links it.
[linux]
[group('build')]
hjem-switch: _require-coder
    nix build '{{ hjem_manifest }}' --out-link result-hjem
    hjem standalone switch --manifest result-hjem

# Build Hjem-managed dotfiles without linking them (Coder only)
[linux]
[group('build')]
hjem-build: _require-coder
    hjem standalone build --manifest "$(nix build --no-link --print-out-paths '{{ hjem_manifest }}')"

[private]
_require-coder:
    @test "{{ target }}" = "coder" || { echo "this recipe only runs on Coder workspaces (\$CODER is unset)" >&2; exit 1; }

# Validate flake without applying
[macos]
[group('build')]
check:
    nix flake check

[linux]
[group('build')]
check:
    nix flake check

# Build config for current hostname
[macos]
[group('build')]
build:
    nix build ".#darwinConfigurations.{{ target }}.system"

[linux]
[group('build')]
build:
    nix build ".#homeConfigurations.{{ target }}.activationPackage"

# Format the repository with treefmt
[group('maintain')]
fmt:
    nix fmt

# Point the /etc/passwd login shell at bash (fish still runs interactively)
# chsh is outside Nix's reach, so re-run this after a workspace rebuild.
[linux]
[group('maintain')]
login-shell-bash:
    #!/usr/bin/env bash
    set -euo pipefail
    target=/bin/bash
    user="$(id -un)"
    current="$(getent passwd "$user" | cut -d: -f7)"
    if [[ "$current" == "$target" ]]; then
      echo "login shell is already $target"
      exit 0
    fi
    # Guard against stranding every interactive session in a bare bash: the
    # handoff has to be linked into ~/.bashrc before the passwd entry moves.
    if ! grep -q __NIXCFG_FISH_HANDOFF "$HOME/.bashrc" 2> /dev/null; then
      echo "refusing: fish handoff missing from ~/.bashrc — run 'just switch' first" >&2
      exit 1
    fi
    echo "login shell: $current -> $target"
    sudo chsh -s "$target" "$user"

# Install Lix with flakes and clone this repo to ~/.config/nix-config (Coder only)
[linux]
[group('maintain')]
coder-bootstrap: _require-coder
    #!/usr/bin/env bash
    # First-run setup for a fresh workspace; each step is skipped if already done.
    set -euo pipefail
    checkout="$HOME/.config/nix-config"
    repo_https=https://github.com/Cbeck527/dotfiles-final-final-v2.git
    repo_ssh=git@github.com:Cbeck527/dotfiles-final-final-v2.git

    if [[ -e /nix/receipt.json ]] || command -v nix > /dev/null; then
      echo "lix: already installed, skipping"
    else
      echo "lix: installing from install.lix.systems"
      # Flakes default to on, but the `--enable-flakes` flag is a toggle that turns
      # them OFF (checked with `nix-installer plan`); the env var sets it explicitly.
      curl -sSf -L https://install.lix.systems/lix | NIX_INSTALLER_ENABLE_FLAKES=true sh -s -- install \
        --no-confirm \
        --extra-conf "trusted-users = root $(id -un)" \
        --extra-conf "accept-flake-config = true" \
        --extra-conf "warn-dirty = false"
    fi

    if [[ -d "$checkout/.git" ]]; then
      echo "checkout: $checkout already exists, skipping clone"
    elif [[ -e "$checkout" ]]; then
      echo "checkout: $checkout exists but is not a git repo" >&2
      exit 1
    else
      echo "checkout: cloning into $checkout"
      mkdir -p "$(dirname "$checkout")"
      git clone "$repo_https" "$checkout"
      git -C "$checkout" remote set-url --push origin "$repo_ssh"
    fi

    echo
    echo "next steps:"
    echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh  # or open a new shell"
    echo "  cd $checkout && just switch"
    echo "  just login-shell-bash"

# Garbage collect nix store
[group('maintain')]
clean:
    nix-collect-garbage

# Full cleanup (requires sudo, deletes old generations)
[confirm]
[group('maintain')]
deep-clean:
    sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old
    nix-collect-garbage -d

# Run flake input audit
[group('maintain')]
audit:
    scripts/audit-flake-inputs.sh

# Update all flake inputs
[group('flake')]
update: update-nix update-osx update-home update-extra update-llms

# Lock missing flake inputs without updating existing lock entries
[group('flake')]
lock:
    nix flake lock

[private]
update-nix:
    nix flake update {{ NIX_CHANNELS }}

[private]
update-osx:
    nix flake update {{ OSX_CHANNELS }}

[private]
update-home:
    nix flake update {{ HOME_CHANNELS }}

[private]
update-extra:
    nix flake update {{ EXTRA_CHANNELS }}

[private]
update-llms:
    nix flake update {{ LLM_CHANNELS }}
