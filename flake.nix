{
  description = "Chris Becker's nix configuration for his hosts!";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
      "https://nix.cmb.software/machines"
      "https://my-prompt.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "machines:eauOgUdO2pwUeNnOb0m4RrWzi6wKFTnYm18PKoPbwYw="
      "my-prompt.cachix.org-1:aIzUDavhE5lzcsn6awg73yVAUnjMrAeqPATi3XrIZ0Q="
    ];
  };

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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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

    # LLM tooling
    llm-agents-nix.url = "github:numtide/llm-agents.nix";

    # https://github.com/Cbeck527/my-prompt
    my-prompt.url = "github:cbeck527/my-prompt";

    attic.url = "github:zhaofengli/attic";

    # private config with sensitive information
    nix-config-private.url = "git+ssh://git@github.com/cbeck527/nix-config-private.git";
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
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
      treefmtEval = forAllSystems (
        system:
        inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );

      # Every host gets every overlay; each one only adds or replaces attributes
      # it names, so an overlay a host never uses costs nothing.
      hostOverlays = [
        self.overlays.fenix
        self.overlays.terraform-157
        self.overlays.llm-agents
        self.overlays.gitea-cli
        self.overlays.datadog-pup
      ];

      mkDarwin =
        hostname:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = hostOverlays; }
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            nix-config-private.darwinModules.${hostname}
            ./hosts/darwin/${hostname}/default.nix
          ];
        };
    in
    {
      overlays = {
        terraform-157 = _: prev: {
          terraform_1_5_7 =
            (import inputs.nixpkgs-terraform-157 {
              inherit (prev.stdenv.hostPlatform) system;
            }).terraform_1;
        };

        llm-agents =
          _: prev:
          let
            agentPkgs = inputs.llm-agents-nix.packages.${prev.stdenv.hostPlatform.system};
          in
          {
            inherit (agentPkgs)
              amp
              claude-code
              codex
              omp
              pi
              ;
          };

        gitea-cli = _: prev: {
          gitea-cli = prev.callPackage ./packages/gitea-cli.nix { };
        };

        datadog-pup = _: prev: {
          datadog-pup = prev.callPackage ./packages/datadog-pup.nix { };
        };

        fenix = fenix.overlays.default;
      };

      # macOS configurations
      darwinConfigurations = {
        # Personal
        beckbook-pro = mkDarwin "beckbook-pro";

        # work
        mac-h99xrph3j9 = mkDarwin "mac-h99xrph3j9";
      };

      # NixOS configurations
      nixosConfigurations = {
        # VPS
        sweetums = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = hostOverlays; }
            home-manager.nixosModules.home-manager
            ./hosts/nixos/sweetums/default.nix
          ];
        };
      };

      # Linux Home Manager configurations
      homeConfigurations = {
        bambi = home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = hostOverlays;
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/linux/bambi/default.nix
          ];
        };

        # Shared config for every Coder workspace; workspace hostnames vary, so
        # the Justfile selects this config when $CODER is set.
        coder = home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = hostOverlays;
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/linux/coder/default.nix
          ];
        };
      };

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
