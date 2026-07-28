{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.try.homeModules.default
    ../../../modules/shared/machine.nix
    ../../../modules/shared/identity.nix
    ../../../modules/linux/nix.nix
    ../../../modules/programs/fish.nix
    ../../../modules/programs/gpg.nix
    ../../../modules/programs/git.nix
    ../../../modules/programs/tmux.nix
  ];

  machine.username = "chris";
  machine.home = "/home/chris";

  home = {
    username = config.machine.username;
    homeDirectory = config.machine.home;
    stateVersion = "25.05";

    packages = with pkgs; [
      just
      inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  programs.home-manager.enable = true;

  programs.try = {
    enable = true;
    package =
      (inputs.try.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        ruby = pkgs.ruby;
      }).overrideAttrs
        (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace try.rb \
              --replace-fail "/usr/bin/env ruby" "${pkgs.ruby}/bin/ruby"
          '';
        });
    path = "~/src/scratch";
  };

  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.load_dotenv = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--no-heading"
      "--no-line-number"
      "--context=0"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Solarized (dark)";
      style = "plain";
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    theme.punctuation.foreground = "Default";
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
