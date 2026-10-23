{
  pkgs,
  config,
  inputs,
  ...
}:

{
  # Home Manager configuration shared by every host
  imports = [
    ../shared/identity.nix
    ../../packages/fish.nix
    ../../packages/gpg.nix
    ../../packages/git.nix
    ../../packages/my-prompt.nix
    ../../packages/tmux.nix
  ];

  programs.home-manager.enable = true;

  # Exports XDG_{CONFIG,CACHE,DATA,STATE}_HOME, and makes HM modules write to
  # ~/.config instead of ~/Library/Application Support on macOS.
  xdg.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less -q";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    GIT_MERGE_AUTOEDIT = "0";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.bin"
  ];

  programs.fish.shellAbbrs = {
    ga = "git add";
    gc = "git commit";
    gd = "git diff";
    gs = "git status";
  };

  programs.fzf = {
    enable = true;
    # Empty disables the widget: no ALT-C, and atuin owns CTRL-R
    changeDirWidget.command = "";
    historyWidget.command = "";
    defaultOptions = [ "--no-height" ];
    colors = {
      fg = "-1";
      bg = "-1";
      hl = "136";
      "fg+" = "254";
      "bg+" = "-1";
      "hl+" = "136";
      info = "136";
      prompt = "136";
      pointer = "230";
      marker = "230";
      spinner = "136";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.load_dotenv = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--no-heading"
      "--no-line-number"
      "--context=0"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Solarized (dark)";
      style = "plain";
    };
  };

  programs.eza = {
    enable = true;
    theme.punctuation.foreground = "Default";
    # The functions below replace HM's ls/ll/la/lt aliases, which would
    # otherwise shadow them.
    enableFishIntegration = false;
  };
  # eza reads ~/Library/Application Support on macOS unless told otherwise
  home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";

  programs.fish.functions =
    builtins.mapAttrs
      (_name: args: {
        wraps = "eza";
        inherit (args) description;
        body = "eza ${args.flags} --group-directories-first $argv";
      })
      {
        ls = {
          description = "List files with eza";
          flags = "-lF";
        };
        lsa = {
          description = "List all files including hidden";
          flags = "-lF --all --all";
        };
        ll = {
          description = "List files with permissions";
          flags = "-lF --octal-permissions";
        };
        l = {
          description = "List files in simple format";
          flags = "-1F";
        };
        lt = {
          description = "List files in tree format (2 levels)";
          flags = "-lF --tree --level=2";
        };
        ltl = {
          description = "List files in full tree format";
          flags = "-lF --tree";
        };
        lg = {
          description = "List files with git status";
          flags = "-lF --git --git-repos";
        };
        lm = {
          description = "List files sorted by modification time";
          flags = "-lF --sort=modified";
        };
        lz = {
          description = "List files sorted by size";
          flags = "-lF --sort=size";
        };
      };

  programs.attic-client = {
    enable = true;
    package = inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client;
    # TODO set up sops/age for secrets
    # settings = {
    #   default-server = "cmb-software";
    #   servers.cmb-software = {
    #     endpoint = "https://nix.cmb.software";
    #     token-file = "";
    #   };
    # };
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
      search_mode = "daemon-fuzzy";
      filter_mode = "host";
      enter_accept = false;
      # Disabled: commands containing tokens are synced to the atuin server.
      # Re-enable if syncing sensitive commands becomes a concern.
      secrets_filter = false;
      show_help = false;
      update_check = false;
      show_preview = false;
      show_tabs = false;
      show_numeric_shortcuts = false;
      command_chaining = true;
    };
  };

  programs.nh.enable = true;

  programs.uv = {
    enable = true;
    settings = {
      preview = true;
    };
  };

  home.packages = with pkgs; [
    # global nix utilities
    cachix

    # Shell & Terminal
    btop
    fastfetch
    htop
    pstree
    tree
    watch
    zmx

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
    jq
    yq

    # Development Tools
    chezmoi
    git-lfs
    hexyl
    vim

    # Network Tools
    doggo
    netcat
    nmap
    socat
    websocat

  ];
}
