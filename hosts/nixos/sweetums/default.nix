{ pkgs, config, ... }:
let
  # Public keys allowed to log in over SSH
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGIwjJ4f/Ipv019+XD1WPkbDt/ArshotElsNN6OuR70"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1Z5TAqmq1BeJwutTbFqEcYhIY087GnY1U06fESzGobkjnbYfsaSkg4WixK/O4WUCBSVcHmg05Hida9vbx475yt+fHr5Azwmhpl8i5rEhb1ZIguoCUdDJQq7AQU5wvyy0hTzn8yZU/ARO9ttVVgFvw9wwh0Mx4AnhQ62BicFqIWlTHaSL7OgPYqL9WFPv9xnejLLE8X+2AYvLTO66lqHpUG+Y3/RGCkjdytdAkPSyagN32MA3jZnOyoi2yuAyAgn5IUZ5yYsrAhxcs+tOOiObdvbh6ghCqaHH+wK00zGIYFA8ypu7n8NBPxxrbb6RYIWfOx6/Rl5+6VcDLPpG0xALA9W09LSEMO9Pj1aNVgGgX/9u5Aaq3KQCRNNPX4mkc7ofC4aULlBG5vN9dIMvTqDGi5+UjZtHFhds/RGFsVg6MX8dQvGH9GRoWVqS8IzKHEIZnRxSZ9qbOkv2+rnRRvveFXdgN81hPfZDVNBz/pRzZBQvOaGoH4uiEhOBGUyRGRwk="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzCOy0HrMg1yJzQRUwii9C617wbpHJM2GcmejvL0Oos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAFk/aMKAU0lLI2O/gb8bxJxE6pOVGp5mDBWmt8kmyt"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSwonGyarOw1ZTyNaawO6twMZydc8ZwP/2w6yTPxRRR"
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/shared/machine.nix
    ../../../modules/nixos/defaults.nix
    ../../../modules/nixos/user.nix
    ../../../modules/nixos/home-manager.nix
  ];

  machine.username = "chris";
  machine.home = "/home/chris";

  networking.hostName = "sweetums";
  networking.domain = "";

  boot.tmp.cleanOnBoot = true;

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.${config.machine.username}.openssh.authorizedKeys.keys = sshKeys;

  # The primary user has no password, so sudo can't prompt for one
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.${config.machine.username} = {
    home.packages = with pkgs; [
      statix
      zmx
    ];

    # Headless server: no gh credential helper, and no jj/delta/LFS
    custom.git.githubCredentialHelper.enable = false;
    custom.git.extras.enable = false;

    programs.bash.enable = true;
  };

  # The installer image shipped "23.11"; raised to the installed release before
  # any stateful service existed. Read the NixOS release notes before changing.
  system.stateVersion = "26.05";
}
