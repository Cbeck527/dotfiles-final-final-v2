{
  description = "Chris Becker's nix configuration for his hosts!";

  inputs = {
    # use unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Pinned for terraform 1.5.7 (last MPL-licensed version)
    nixpkgs-terraform-157.url = "github:nixos/nixpkgs/9204ded9bd5d64ccff9341c6f9eb4407ed6f1c01";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # better Rust
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM tooling (claude-code, pi)
    llm-agents-nix.url = "github:numtide/llm-agents.nix";

    # private config with sensitive information
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
      overlays = {
        terraform-157 = _: prev: {
          terraform_1_5_7 =
            (import inputs.nixpkgs-terraform-157 {
              inherit (prev.stdenv.hostPlatform) system;
            }).terraform_1;
        };

        llm-agents = _: prev: {
          claude-code = inputs.llm-agents-nix.packages.${prev.stdenv.hostPlatform.system}.claude-code;
          pi = inputs.llm-agents-nix.packages.${prev.stdenv.hostPlatform.system}.pi;
        };

        fenix = fenix.overlays.default;
      };

      # macOS configurations
      darwinConfigurations = {

        # Personal
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

      # Format: `nix fmt` or `make fmt`
      formatter.aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt;

      # TODO: set up linux machines with home-manager

    };
}
