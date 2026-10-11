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
    # NOTE: temporarily commented out in favor of manual build fom
    # https://github.com/jimeh/build-emacs-for-macos/
    # ../../../modules/darwin/emacs-macport.nix
  ];

  machine.username = "chris";
  machine.home = "/Users/chris";

  system.primaryUser = "chris";

  # home-manager customizations
  home-manager.users.${config.machine.username} = {
    imports = [
      ../../../packages/llms
    ];

    programs.atuin = {
      settings = {
        sync_address = "https://shellsync.cmb.software";
      };
    };
    home.packages = with pkgs; [
      cowsay
      fortune
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
    "slack"
    "wireshark-app"
  ];
}
