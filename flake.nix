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

    # $HOME file management, used only by the `coder` host
    hjem = {
      url = "github:feel-co/hjem";
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
      mkHjemConfiguration = import ./lib/hjem.nix {
        inherit (inputs.nixpkgs) lib;
        inherit (inputs) hjem;
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
              claude-code
              codex
              omp
              pi
              ;
          };

        # NOTE: use my fork's release until https://gitea.com/gitea/tea/pulls/1130 gets merged
        tea =
          _: prev:
          let
            # Nix system -> release asset platform suffix and hash of its .xz asset.
            assets = {
              aarch64-darwin = {
                platform = "darwin-arm64";
                hash = "sha256-7kdPG9//Opclb+GCLcSVHBfdHL8lDvAb6kGU8vdAZk8=";
              };
              aarch64-linux = {
                platform = "linux-arm64";
                hash = "sha256-wL1eY2OurmMSXhSNoMr2JZQ8/nFB0xGLARhAXnXpZ+w=";
              };
              x86_64-linux = {
                platform = "linux-amd64";
                hash = "sha256-3OHTZw6lvv724ix8Lt1UiT5CI1I1tAfCvJzxC4DPYto=";
              };
            };
            system = prev.stdenv.hostPlatform.system;
            asset = assets.${system} or (throw "tea: no release asset for ${system}");
          in
          {
            tea = prev.stdenv.mkDerivation (finalAttrs: {
              pname = "tea";
              version = "0.16.0-custom-headers";
              src = prev.fetchurl {
                url = "https://gitea.com/chrisbecker/tea/releases/download/v${finalAttrs.version}/tea-${finalAttrs.version}-${asset.platform}.xz";
                inherit (asset) hash;
              };
              nativeBuildInputs = [ prev.installShellFiles ];

              # The release asset is a bare xz-compressed binary, not a tarball.
              unpackPhase = ''
                xz -dc "$src" > tea
              '';
              installPhase = ''
                runHook preInstall
                install -Dm755 tea $out/bin/tea
                runHook postInstall
              '';
              # Completions and the man page come from running the binary, so skip them when cross-compiling.
              postInstall = prev.lib.optionalString (prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) ''
                installShellCompletion --cmd tea \
                  --bash <($out/bin/tea completion bash) \
                  --fish <($out/bin/tea completion fish) \
                  --zsh <($out/bin/tea completion zsh)
                $out/bin/tea man --out $out/share/man/man1/tea.1
              '';

              meta = {
                description = "Gitea CLI client with custom HTTP headers support";
                homepage = "https://gitea.com/chrisbecker/tea";
                license = prev.lib.licenses.mit;
                mainProgram = "tea";
                platforms = builtins.attrNames assets;
                sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
              };
            });
          };

        datadog-pup = _: prev: {
          datadog-pup = prev.stdenv.mkDerivation (finalAttrs: {
            pname = "datadog-pup";
            version = "0.27.0";
            src = prev.fetchurl {
              url = "https://github.com/DataDog/pup/releases/download/v${finalAttrs.version}/pup_${finalAttrs.version}_Darwin_arm64.tar.gz";
              hash = "sha256-beHU+qv/wv9Fa3oBHlGKjipoIF2Wcnq8CFz1xlyeVwk=";
            };
            sourceRoot = ".";
            installPhase = ''
              install -Dm755 pup $out/bin/pup
            '';
          });
        };

        fenix = fenix.overlays.default;
      };

      # macOS configurations
      darwinConfigurations = {

        # Personal
        beckbook-pro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.overlays = [
                self.overlays.fenix
                self.overlays.terraform-157
                self.overlays.llm-agents
                self.overlays.tea
                self.overlays.datadog-pup
              ];
            }
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            nix-config-private.darwinModules.beckbook-pro
            ./hosts/darwin/beckbook-pro/default.nix
          ];
        };

        # work
        mac-h99xrph3j9 = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.overlays = [
                self.overlays.fenix
                self.overlays.terraform-157
                self.overlays.llm-agents
                self.overlays.tea
                self.overlays.datadog-pup
              ];
            }
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            nix-config-private.darwinModules.mac-h99xrph3j9
            ./hosts/darwin/mac-h99xrph3j9/default.nix
          ];
        };
      };

      # NixOS configurations
      nixosConfigurations = {
        # VPS
        sweetums = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ self.overlays.tea ]; }
            home-manager.nixosModules.home-manager
            ./hosts/nixos/sweetums/default.nix
          ];
        };
      };

      # Linux Home Manager configurations
      homeConfigurations = {
        # Shared config for every Coder workspace; workspace hostnames vary, so
        # the Justfile selects this config when $CODER is set.
        coder = home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = [ self.overlays.fenix ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./hosts/linux/coder/default.nix
          ];
        };
      };

      # Hjem-managed dotfiles. Coder workspaces only, applied out of band from
      # Home Manager with `just hjem-switch`. The output name is the Hjem CLI's
      # convention: `hjem standalone switch --flake` reads
      # `hjemConfigurations."$USER"`. See lib/hjem.nix for why the just recipes
      # build `manifestFile` and pass it to `--manifest` instead.
      hjemConfigurations = {
        christopher-becker = mkHjemConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };
          inherit (self.homeConfigurations.coder.config.machine) username home;
          modules = [
            ./hosts/linux/coder/hjem.nix
          ];
        };
      };

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
