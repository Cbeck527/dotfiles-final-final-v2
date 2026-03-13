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
    programs.atuin = {
      settings = {
        sync_address = "https://shellsync.cmb.software";
      };
    };
    home.packages = with pkgs; [
      claude-code
      codex
      pi
      ffmpeg
      terraform
      flyctl

      # GUI Apps
      discord
      iina
      inkscape
      openscad-unstable

      # Meshtastic/SDR
      natscli
      nats-server
      platformio-core
      urh
    ];
  };

  homebrew.casks = [
    "claude"
    "jdownloader"
    "kicad"
    "qflipper"
    "transmission"
    "xcodes-app"
    "xld"
    "yaak"
  ];
}
