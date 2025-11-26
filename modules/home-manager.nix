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
      ];

      home.stateVersion = "25.05";

      programs.home-manager.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
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

      home.packages = with pkgs; [
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
        neofetch
        pstree
        tmux
        tree
        watch
        zoxide

        # Core Utilities
        curl
        findutils
        gawk
        gnumake
        gnupg
        gnused
        less
        parallel
        procps
        rsync
        wget

        # Search & Text Processing
        dasel
        fd
        jq
        ripgrep
        shellcheck
        silver-searcher
        yq

        # Development Tools
        automake
        chezmoi
        clang-tools
        cmake
        delta
        git
        git-lfs
        gh
        go
        hexyl
        just
        lua-language-server
        nixfmt-rfc-style
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
        terraform

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
