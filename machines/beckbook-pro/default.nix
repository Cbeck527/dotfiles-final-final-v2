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

  system.primaryUser = username;

  _module.args = { inherit username userHome; };

  # home-manager customizations
  home-manager.users.${username} = {
    imports = [
      ../../modules/crush.nix
    ];

    programs.atuin = {
      settings = {
        sync_address = "https://shellsync.cmb.software";
      };
    };
    home.packages = with pkgs; [
      qmd
      readwise-cli
      ffmpeg
      terraform
      flyctl

      # Meshtastic/SDR
      natscli
      nats-server
      platformio-core
      urh
    ];
  };

  homebrew.casks = [
    "openscad@snapshot"
    "discord"
    "iina"
    "inkscape"
    "claude"
    "jdownloader"
    "kicad"
    "qflipper"
    "reader"
    "telegram"
    "transmission"
    "xcodes-app"
    "xld"
    "yaak"
    "slack"
    "wireshark-app"
  ];
}
