{
  pkgs,
  config,
  ...
}:
let
  inherit (config.machine) username home;
in
{
  imports = [
    ../machine.nix
    ./nix.nix
    ../identity.nix
    ../gpg.nix
    ../git.nix
    ../tmux.nix
  ];

  home = {
    username = username;
    homeDirectory = home;
    stateVersion = "25.05";
    packages = with pkgs; [
      just
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # nix-config wrapper: run just recipes from anywhere
      function nx --description "Run nix-config recipes via just"
        set -l justfile ~/.config/nix-config/Justfile
        set -l workdir ~/.config/nix-config

        if test (count $argv) -eq 0
          just --justfile $justfile --working-directory $workdir --list
        else
          just --justfile $justfile --working-directory $workdir $argv
        end
      end

      # nx tab completions (dynamic from Justfile recipes)
      complete -c nx -f -a "(just --justfile ~/.config/nix-config/Justfile --summary | string split ' ')"

      # Local machine overrides
      if test -f ~/.localrc.fish
        source ~/.localrc.fish
      end
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
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
    enableFishIntegration = false;
    theme = {
      punctuation = {
        foreground = "Default";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
