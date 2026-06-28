{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/darwin/defaults.nix
    ../../../modules/darwin/homebrew.nix
    ../../../modules/darwin/services.nix
    ../../../modules/darwin/home-manager.nix
    ../../../modules/darwin/emacs-macport.nix
  ];

  machine.username = "chris";
  machine.home = "/Users/chris";

  system.primaryUser = "chris";

  # home-manager customizations
  home-manager.users.${config.machine.username} = {
    imports = [
      ../../../modules/programs/llms
    ];

    programs.atuin = {
      settings = {
        sync_address = "https://shellsync.cmb.software";
      };
    };
    home.packages = with pkgs; [
      cowsay
      fortune
      qmd
      readwise-cli
      ffmpeg
    ];
  };

  homebrew.casks = [
    "openscad@snapshot"
    "discord"
    "iina"
    "inkscape"
    "jdownloader"
    "kicad"
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
