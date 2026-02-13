{
  pkgs,
  inputs,
  ...
}:
let
  username = "chris";
  userHome = "/Users/chris";
in
{
  imports = [
    ../../bootstrap/darwin.nix
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/services.nix
    ../../modules/darwin/packages.nix
    ../../modules/home-manager.nix
    ../../modules/emacs-macport.nix
  ];

  custom.emacs.liquidGlassIcons = true;

  system.primaryUser = username;

  _module.args = { inherit username userHome; };

  # nix-homebrew: manage Homebrew installation declaratively
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    # mutableTaps = true allows nix-darwin's homebrew.taps to work
    mutableTaps = true;
  };

  # home-manager customizations
  home-manager.users.${username} = {
    programs.atuin = {
      settings = {
        sync_address = "https://shellsync.cmb.software";
      };
    };
    home.packages = with pkgs; [
      claude-code
      ffmpeg
      terraform

      # Meshtastic/SDR
      natscli
      nats-server
      platformio-core
      urh
    ];
  };

  # Override macOS defaults in ../../modules/darwin/defaults.nix

  # Machine-specific homebrew packages
  homebrew.taps = [
    "facebook/fb"
    "getsentry/tools"
  ];

  homebrew.brews = [
    "flyctl"
  ];

  homebrew.casks = [
    "claude"
    "discord"
    "iina"
    "jdownloader"
    "qflipper"
    "tidal"
    "transmission"
    "xcodes-app"
    "xld"
    "yaak"
    "openscad@snapshot"
    "inkscape"
  ];
}
