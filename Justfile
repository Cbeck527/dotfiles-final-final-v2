# nix-config Justfile

# List available recipes
default:
    @just --list

IMPURE := "false"

hostname := `hostname`

impure := if IMPURE == "true" { "--impure" } else { "" }

# Build and apply using local private config
mod local

NIX_CHANNELS := "nixpkgs treefmt-nix"
HOME_CHANNELS := "home-manager"
OSX_CHANNELS := "nix-darwin nix-homebrew homebrew-core homebrew-cask"
EXTRA_CHANNELS := "fenix nix-config-private"
LLM_CHANNELS := "llm-agents-nix"

# Apply config for current hostname
[macos]
[group('build')]
switch:
    sudo darwin-rebuild switch {{ impure }} --verbose --flake ".#{{ hostname }}" --fallback

[linux]
[group('build')]
switch:
    nix build ".#homeConfigurations.{{ hostname }}.activationPackage"
    ./result/activate

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
    nix build ".#darwinConfigurations.{{ hostname }}.system"

[linux]
[group('build')]
build:
    nix build ".#homeConfigurations.{{ hostname }}.activationPackage"

# Format the repository with treefmt
[group('maintain')]
fmt:
    nix fmt

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
