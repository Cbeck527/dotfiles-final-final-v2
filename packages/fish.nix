{ lib, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.mkMerge [
      ''
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
      ''

      (lib.mkOrder 2000 ''
        # Local machine overrides
        if test -f ~/.localrc.fish
          source ~/.localrc.fish
        end
      '')
    ];
  };
}
