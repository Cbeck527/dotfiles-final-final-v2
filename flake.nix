{
  description = "Chris Becker's nix configuration for his hosts!";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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

    # homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-homebrew.inputs.brew-src.url = "github:Homebrew/brew/5.1.14";
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

    # Charm tools (crush, glow, etc.)
    charmbracelet = {
      url = "github:charmbracelet/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM tooling
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

        llm-agents =
          _: prev:
          let
            agentPkgs = inputs.llm-agents-nix.packages.${prev.stdenv.hostPlatform.system};
          in
          {
            inherit (agentPkgs)
              claude-code
              codex
              pi
              qmd
              ;
          };

        readwise-cli = _: prev: {
          readwise-cli = prev.buildNpmPackage {
            pname = "readwise-cli";
            version = "0.5.3";
            src = prev.fetchFromGitHub {
              owner = "readwiseio";
              repo = "readwise-cli";
              rev = "e7b4f77ea00184222cd68a7eea07e6457780213e";
              hash = "sha256-dkyRRQHtdsprIVJvouqH4WKzXDq5AKRgfLNWxem7t3s=";
            };
            npmDepsHash = "sha256-U8YriPY/x9t9cZ3a4caq4oZRe396X3r0RKVJhTTRiNI=";
          };
        };

        # Custom tea build pinned to bfbec3f with CF Access custom headers patch
        tea = _: prev: {
          tea = (prev.buildGoModule.override { go = prev.go_1_26; }) {
            pname = "tea";
            version = "0.12.0-custom-headers";

            src = prev.fetchFromGitea {
              domain = "gitea.com";
              owner = "gitea";
              repo = "tea";
              rev = "bfbec3fc00e12d88a5490d42e64a984445135929";
              hash = "sha256-i10EMmaYl5gWVV5B4gLpX8ZVKxKb9pVsFkvBIvqQjkA=";
            };

            patches = [ ./etc/patches/tea-custom-headers.patch ];
            vendorHash = "sha256-FnKq34/0pPOUNRwB6T/kSrNo2gMm1H9ob1y9srTWstY=";

            ldflags = [
              "-s"
              "-w"
              "-X"
              "code.gitea.io/tea/modules/version.Version=0.12.0-custom-headers"
              "-X"
              "code.gitea.io/tea/modules/version.Tags=nixpkgs"
              "-X"
              "code.gitea.io/tea/modules/version.SDK=v0.24.1"
            ];

            checkFlags = [ "-skip=TestRepoFromPath_Worktree" ];
            nativeBuildInputs = [ prev.installShellFiles ];
            nativeCheckInputs = [ prev.writableTmpDirAsHomeHook ];

            postInstall = prev.lib.optionalString (prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) ''
              installShellCompletion --cmd tea \
                --bash <($out/bin/tea completion bash) \
                --fish <($out/bin/tea completion fish) \
                --zsh <($out/bin/tea completion zsh)
              mkdir -p $out/share/powershell
              $out/bin/tea completion pwsh > $out/share/powershell/tea.Completion.ps1
              $out/bin/tea man --out $out/share/man/man1/tea.1
            '';

            meta = {
              description = "Gitea CLI client with custom HTTP headers support";
              homepage = "https://gitea.com/gitea/tea";
              license = prev.lib.licenses.mit;
              mainProgram = "tea";
            };
          };
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
