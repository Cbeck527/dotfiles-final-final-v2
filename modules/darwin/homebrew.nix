{ config, lib, ... }:

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

  config.homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    brews = [ ];

    taps = [
      "hashicorp/tap"
    ];

    casks = lib.filter
      (c: !(builtins.elem c config.custom.homebrew.excludeCasks))
      baseCasks;
  };
}
