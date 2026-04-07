{
  config,
  lib,
  inputs,
  username,
  ...
}:

let
  baseCasks = [
    # Terminal emulators
    "ghostty"

    # Browsers
    "firefox"
    "google-chrome"
    "orion"

    # Productivity
    "alfred"
    "contexts"
    "rectangle-pro"
    "textexpander"
    "cleanshot"

    # Development
    "sublime-text"
    "sublime-merge"

    # QuickLook plugins
    "qlmarkdown"
    "qlstephen"
    "syntax-highlight"
    "suspicious-package"

    # Utilities
    "bartender"
    "choosy"
    "appcleaner"
    "apparency"
    "keka"
    "1password"
    "1password-cli"
    "latest"

  ];
in
{
  options.custom.homebrew.excludeCasks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Casks to exclude from homebrew installation";
  };

  # manage homebrew installation with nix
  config.nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;

    # taps in /opt/homebrew/Library/Taps/ are linked to nix store
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  # manage homebrew taps, formulae, casks etc with nix-darwin
  config.homebrew = {
    enable = true;
    enableFishIntegration = true;

    global = {
      autoUpdate = false; # HOMEBREW_NO_AUTO_UPDATE=1
    };

    onActivation = {
      # auto-update itself and all formulae during nix-darwin system activation
      # NOTE: we pin taps with nix-homebrew so this won't update formulae definitions
      autoUpdate = true;

      # upgrade outdated formulae during nix-darwin system activation
      upgrade = true;

      # remove formulae not declared in this config
      cleanup = "uninstall";
    };

    # NOTE: this may look repetitive, but we have to re-declare our taps for the
    # generated Brewfile to use them
    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];

    casks = lib.filter (c: !(builtins.elem c config.custom.homebrew.excludeCasks)) baseCasks;
  };
}
