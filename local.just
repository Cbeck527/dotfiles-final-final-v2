# Local override commands (use local private config instead of flake input)

IMPURE := "false"

hostname := `hostname`

impure := if IMPURE == "true" { "--impure" } else { "" }

local_private := "--override-input nix-config-private \"path:$HOME/.config/nix-config-private\""

# Validate flake with local private config
[macos]
check:
    nix flake check {{ local_private }}

# Build with local private config
[macos]
build:
    nix build ".#darwinConfigurations.{{ hostname }}.system" {{ local_private }}

# Apply config with local private config
[macos]
switch:
    sudo darwin-rebuild switch {{ impure }} --verbose --flake ".#{{ hostname }}" {{ local_private }} --fallback
