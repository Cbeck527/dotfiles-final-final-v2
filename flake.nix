{
  description = "Chris Becker's nix configuration for his hosts!";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # Pinned for terraform 1.5.7 (last MPL-licensed version)
    nixpkgs-terraform-157.url = "github:nixos/nixpkgs/9204ded9bd5d64ccff9341c6f9eb4407ed6f1c01";

    # Independently updatable: `make update.claude` or `nix flake update nixpkgs-claude-code`
    nixpkgs-claude-code.url = "github:nixos/nixpkgs/master";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Declarative Homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-config-private = {
      url = "git+ssh://git@github.com/cbeck527/nix-config-private.git";
    };
  };

  outputs =
    {
      self,
      fenix,
      nix-darwin,
      home-manager,
      nix-homebrew,
      nix-config-private,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      # Overlays to expose multiple nixpkgs channels
      overlays = {
        pkgs-stable = _: prev: {
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        };

        pkgs-unstable = _: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        };

        pkgs-master = _: prev: {
          pkgs-master = import inputs.nixpkgs-master {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        };

        terraform-157 = _: prev: {
          terraform_1_5_7 =
            (import inputs.nixpkgs-terraform-157 {
              inherit (prev.stdenv.hostPlatform) system;
            }).terraform_1;
        };

        claude-code = _: prev: {
          claude-code =
            (import inputs.nixpkgs-claude-code {
              inherit (prev.stdenv.hostPlatform) system;
              config.allowUnfree = true;
            }).claude-code;
        };

        fenix = fenix.overlays.default;
      };

      # macOS configurations
      darwinConfigurations = {
        beckbook-pro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs outputs; };
          modules = [
            { nixpkgs.overlays = builtins.attrValues self.overlays; }
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            nix-config-private.darwinModules.beckbook-pro
            ./machines/beckbook-pro/default.nix
          ];
        };

        # work
        mac-h99xrph3j9 = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs outputs; };
          modules = [
            { nixpkgs.overlays = builtins.attrValues self.overlays; }
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            nix-config-private.darwinModules.mac-h99xrph3j9
            ./machines/mac-h99xrph3j9/default.nix
          ];
        };
      };

      # TODO: set up linux machines with home-manager

    };
}
