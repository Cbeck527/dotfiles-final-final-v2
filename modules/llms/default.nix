{ pkgs, ... }:

{
  imports = [
    ./pi.nix
  ];

  home.packages = with pkgs; [
    claude-code
    codex
  ];
}
