# nix-config Justfile
set fallback := false

# List available recipes
default:
    @just --list

IMPURE := "false"

hostname := `hostname`
os := os()

impure := if IMPURE == "true" { "--impure" } else { "" }

# Channels
NIX_CHANNELS := "nixpkgs nixpkgs-master nixpkgs-stable"
HOME_CHANNELS := "home-manager"
OSX_CHANNELS := "nix-darwin nix-homebrew homebrew-core homebrew-cask"
EXTRA_CHANNELS := "fenix nix-config-private"
LLM_CHANNELS := "llm-agents-nix"

# Apply config for current hostname
[macos]
switch:
    sudo darwin-rebuild switch {{ impure }} --verbose --flake ".#{{ hostname }}" --fallback

# Validate flake without applying
[macos]
check:
    nix flake check

# Dry-run build for current hostname
[macos]
build:
    nix build ".#darwinConfigurations.{{ hostname }}.system" --dry-run

# Format all nix files
[macos]
fmt:
    nix fmt

# TODO: linux support
# [linux]
# switch:
#     nix build .#homeConfigurations.linux.activationPackage

# Garbage collect nix store
clean:
    nix-collect-garbage

# Full cleanup (requires sudo)
fclean:
    @echo "/!\ require to be root"
    sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old
    nix-collect-garbage -d

# Lock all flake inputs
lock: lock-nix lock-osx lock-home

lock-nix:
    nix flake lock {{ NIX_CHANNELS }}

lock-osx:
    nix flake lock {{ OSX_CHANNELS }}

lock-home:
    nix flake lock {{ HOME_CHANNELS }}

# Update all flake inputs
update: update-nix update-osx update-home update-extra update-llms

update-nix:
    nix flake update {{ NIX_CHANNELS }}

update-osx:
    nix flake update {{ OSX_CHANNELS }}

update-home:
    nix flake update {{ HOME_CHANNELS }}

update-extra:
    nix flake update {{ EXTRA_CHANNELS }}

# Update LLM-related flake inputs
update-llms:
    nix flake update {{ LLM_CHANNELS }}

# Alias for muscle memory
update-claude: update-llms

# Run flake input audit
audit:
    scripts/audit-flake-inputs.sh
