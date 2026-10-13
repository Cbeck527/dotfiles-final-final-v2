{ config, ... }:
let
  inherit (config.machine) username home;
in
{
  # Primary user account. nix-darwin doesn't create macOS users; this only tells
  # it (and Home Manager) where the existing account lives.
  users.users.${username} = {
    inherit home;
    description = "Chris Becker";
  };
}
