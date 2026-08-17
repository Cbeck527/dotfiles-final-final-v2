{
  pkgs,
  lib,
  ...
}:

{
  # package config
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = pkgs.lix;
    settings = {
      warn-dirty = false;
      # "relaxed" allows per-derivation sandbox opt-out via __noChroot.
      # Required for emacs-macport: byte-compiling url.el triggers GnuTLS
      # cert scanning of /etc/ssl/certs, which strict sandboxing blocks.
      sandbox = "relaxed";

      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [ "@admin" ];

      # Auto-accept nixConfig from flakes (e.g. extra-substituters)
      accept-flake-config = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      keep-outputs = true;
      keep-derivations = true;

      extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
        "x86_64-darwin"
      ];
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };

  programs.nix-index.enable = true;

  # Add shells installed by nix to /etc/shells file
  environment.shells = with pkgs; [
    bashInteractive
    fish
    zsh
  ];

  # Enable zsh for compatibility, but use fish as default shell
  programs.zsh.enable = true;
  environment.variables.SHELL = "${pkgs.fish}/bin/fish";

  environment = {
    systemPackages = with pkgs; [
      coreutils
      findutils
      diffutils
      gnused
      gnutls

      # global nix utilities
      cachix
      devenv
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    ibm-plex
  ];

  programs = {
    fish.enable = true;
  };

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      mru-spaces = false;
      dashboard-in-overlay = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "Nlsv";
      ShowExternalHardDrivesOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
    };

    universalaccess = {
      closeViewScrollWheelToggle = true;
      closeViewZoomFollowsFocus = true;
    };

    CustomUserPreferences = {
      "com.apple.finder" = {
        FXInfoPanesExpanded = {
          Comments = 1;
          General = 1;
          MetaData = 1;
          Name = 1;
          OpenWith = 1;
          Privileges = 1;
        };
      };
      "com.apple.NetworkBrowser" = {
        BrowseAllInterfaces = 1;
      };
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = true;
      };
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Use touch ID for sudo auth
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
