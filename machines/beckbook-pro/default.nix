{
  pkgs,
  ...
}:
let
  username = "chris";
  userHome = "/Users/chris";
in
{
  imports = [
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/services.nix
    ../../modules/home-manager.nix
    ../../modules/emacs-macport.nix
  ];

  system.primaryUser = username;

  _module.args = { inherit username userHome; };

  # home-manager customizations
  home-manager.users.${username} = {
    imports = [
      ../../modules/llms
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
