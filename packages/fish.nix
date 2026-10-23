{ lib, ... }:

let
  # In the completion pager, act like a vim motion; otherwise fall back to the
  # key's normal readline action.
  pagerOr = pager: fallback: ''
    if commandline --paging-mode
      commandline -f ${pager}
    else
      commandline -f ${fallback}
    end
  '';
in
{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      # bash-style `!!` and `unset`
      "!!" = {
        position = "anywhere";
        function = "last_history_item";
      };
      unset = {
        position = "command";
        expansion = "set -e";
      };
    };

    functions = {
      last_history_item = "echo $history[1]";
      _custom_complete_j = pagerOr "down-line" "execute";
      _custom_complete_k = pagerOr "up-line" "kill-line";
      _custom_complete_l = pagerOr "forward-char" "clear-screen";
    };

    # Rendered into fish_user_key_bindings
    binds = {
      # vim-like autocomplete navigation
      "ctrl-h".command = "backward-char";
      "ctrl-j".command = "_custom_complete_j";
      "ctrl-k".command = "_custom_complete_k";
      "ctrl-l".command = "_custom_complete_l";
      # C-x C-e like in bash
      "ctrl-x,ctrl-e".command = "edit_command_buffer";
    };

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
