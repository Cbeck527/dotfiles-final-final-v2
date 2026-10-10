{ pkgs, config, ... }:
let
  inherit (config.machine) username home;
in
{
  # Primary user account. No password is set: login is SSH keys only, so give
  # the host either passwordless sudo for wheel or a hashedPassword.
  users.users.${username} = {
    isNormalUser = true;
    inherit home;
    description = "Chris Becker";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  # Installs fish system-wide and registers it in /etc/shells
  programs.fish.enable = true;
}
