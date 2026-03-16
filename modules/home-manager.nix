{
  pkgs,
  username,
  userHome,
  ...
}:

{
  # Common user configuration shared across all machines
  users.users.${username} = {
    home = userHome;
    description = username;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.${username} = {
      imports = [
        ./identity.nix
        ./gpg.nix
        ./git.nix
        ./tmux.nix
      ];

      home.stateVersion = "25.05";

      targets.darwin.copyApps = {
        enable = true;
        directory = "Applications/HomeManager";
      };
      targets.darwin.linkApps.enable = false;

      programs.home-manager.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          # nix-config wrapper: run just recipes from anywhere
          function nx --description "Run nix-config recipes via just"
            set -l justfile ~/.config/nix-config/Justfile
            set -l workdir ~/.config/nix-config

            if test (count $argv) -eq 0
              just --justfile $justfile --working-directory $workdir --list
            else
              just --justfile $justfile --working-directory $workdir $argv
            end
          end

          # nx tab completions (dynamic from Justfile recipes)
          complete -c nx -f -a "(just --justfile ~/.config/nix-config/Justfile --summary | string split ' ')"

          # Local machine overrides
          if test -f ~/.localrc.fish
            source ~/.localrc.fish
          end
        '';
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global = {
            load_dotenv = true;
          };
        };
      };

      programs.atuin = {
        enable = true;
        enableFishIntegration = true;
        flags = [
          "--disable-up-arrow"
        ];
        daemon = {
          enable = true;
        };
        settings = {
          dialect = "us";
          style = "compact";
          filter_mode = "host";
          enter_accept = false;
          secrets_filter = false;
          show_help = false;
          update_check = false;
          show_preview = false;
          show_tabs = false;
        };
      };

      programs.ripgrep = {
        enable = true;
        arguments = [
          "--no-heading"
          "--no-line-number"
          "--context=0"
        ];
      };

      home.packages = with pkgs; [
        # GUI Apps (moved from Homebrew casks)
        alacritty
        kitty
        obsidian
        slack
        wireshark
        keka
        _1password-cli

        # Shell & Terminal
        aspell
        bat
        btop
        cowsay
        eza
        fastfetch
        fortune
        fzf
        htop
        pstree
        tree
        watch
        zoxide

        # Core Utilities
        curl
        findutils
        gawk
        gnumake
        gnused
        less
        parallel
        rsync
        wget

        # Search & Text Processing
        dasel
        fd
        jq
        shellcheck
        silver-searcher
        yq

        # Development Tools
        automake
        chezmoi
        clang-tools
        cmake
        dprint
        git-lfs
        gh
        go
        hexyl
        just
        lua-language-server
        nixfmt
        nodejs_24
        stylua
        vim

        # Better Rust w/ nix-community fenix
        cargo-deny
        cargo-expand
        cargo-fuzz
        (pkgs.fenix.stable.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ])
        rust-analyzer-nightly

        # Cloud & Infrastructure
        awscli
        colima
        ctop
        docker
        docker-buildx
        k9s
        kubectl
        kubernetes-helm

        # Languages / LSP
        astro-language-server
        awk-language-server
        basedpyright
        bash-language-server
        buf # protobufs
        dockerfile-language-server
        emacs-lsp-booster
        fish-lsp
        go-grip
        golangci-lint
        gopls
        nil # nix lsp
        terraform-ls
        typescript-language-server
        uv
        vscode-langservers-extracted
        yaml-language-server

        # Network Tools
        netcat
        nmap
        socat
        websocat

        # Other
        typst
        zstd
      ];
    };
  };
}
