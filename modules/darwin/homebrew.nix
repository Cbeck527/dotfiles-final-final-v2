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
    "macupdater"
    "appcleaner"
    "apparency"

    # Other
    "aldente"
    "boltai"
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
      cleanup = "uninstall";
    };

    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];

    casks = lib.filter (c: !(builtins.elem c config.custom.homebrew.excludeCasks)) baseCasks;
  };
}
