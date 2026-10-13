{ pkgs, inputs, ... }:

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
    fzf
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
