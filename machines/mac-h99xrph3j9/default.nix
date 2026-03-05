{
  pkgs,
  ...
}:
let
  username = "christopher.becker";
  userHome = "/Users/christopher.becker";
  workEmail = "REDACTED";
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
  system.defaults.universalaccess = { }; # work profile blocks changing this

  services.caffeinate.enable = true;

  _module.args = { inherit username userHome; };

  home-manager.users.${username} = {
    identity.email = workEmail;

    home.packages = with pkgs; [
      pkgs.pkgs-master.claude-code
      pkgs.pkgs-master.codex
      aws-sso-cli
      terraform_1_5_7
      terragrunt

      nodePackages_latest.prettier
    ];
  };

  custom.emacs = {
    macMetal = true;
    cflags.value = "-O3 -mcpu=native -fobjc-arc -DFD_SETSIZE=10000 -D_DARWIN_UNLIMITED_SELECT";
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
  };

  custom.homebrew.excludeCasks = [ "contexts" ];

  homebrew.taps = [ ];

  homebrew.brews = [ ];

  homebrew.casks = [
    "yaak"
  ];

  # TODO: handle mac app store apps?
  # 1PW for Safari - 1569813296
  # utc time - 1538245904
  # dato - 1470584107
  # wipr - 1662217862
}
