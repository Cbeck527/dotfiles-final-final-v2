{
  description = "Chris Becker's nix configuration for his hosts!";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

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
  };

  outputs =
    {
      self,
      fenix,
      nix-darwin,
      home-manager,
      nix-homebrew,
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
            ./machines/mac-h99xrph3j9/default.nix
          ];
        };
      };

      # TODO: set up linux machines with home-manager

    };
}
