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
    "alacritty"
    "ghostty"
    "kitty"

    # Browsers
    "firefox"
    "google-chrome"
    "orion"

    # Productivity
    "1password-cli"
    "alfred"
    "contexts"
    "rectangle-pro"
    "textexpander"
    "cleanshot"
    "obsidian"

    # Development
    "sublime-text"
    "bbedit"

    # QuickLook plugins
    "qlcolorcode"
    "qlmarkdown"
    "qlstephen"
    "qlvideo"
    "quicklook-json"
    "quicklookase"
    "syntax-highlight"
    "suspicious-package"

    # Utilities
    "bartender"
    "choosy"
    "keka"
    "macupdater"
    "appcleaner"
    "apparency"

    # Communication
    "slack"

    # Other
    "aldente"
    "boltai"
    "wireshark-app"
  ];
in
{
  options.custom.homebrew.excludeCasks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Casks to exclude from homebrew installation";
  };

  # nix-managed homebrew installation
  config.nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  # nix-managed brew taps, formulae, and taps
  config.homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];

    casks = lib.filter (c: !(builtins.elem c config.custom.homebrew.excludeCasks)) baseCasks;
  };
}
