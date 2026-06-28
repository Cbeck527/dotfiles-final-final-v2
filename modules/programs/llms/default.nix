{ pkgs, ... }:

{
  imports = [
    ./pi.nix
    ./omp.nix
    ./crush.nix
  ];

  home.packages = with pkgs; [
    claude-code
    codex
  ];
}
