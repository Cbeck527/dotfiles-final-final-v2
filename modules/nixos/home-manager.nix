{
  pkgs,
  inputs,
  config,
  ...
}:
let
  inherit (config.machine) username;
in
{
  # Common Home Manager configuration shared across NixOS hosts. The user
  # account itself is defined in ./user.nix.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.${username} = {
      imports = [
        ../shared/identity.nix
        ../../packages/fish.nix
        ../../packages/gpg.nix
        ../../packages/git.nix
        ../../packages/my-prompt.nix
        ../../packages/tmux.nix
      ];

      home.stateVersion = "26.05";

      programs.home-manager.enable = true;

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
    };
  };
}
