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

      fish_greeting = "";
      cat = {
        wraps = "bat --paging=never";
        body = "bat --paging=never $argv";
      };
      grep = "command grep --color=auto $argv";
      gcd = {
        description = "cd to the root of a git repository";
        body = "cd (git rev-parse --show-toplevel)";
      };
      reload = {
        wraps = "exec fish";
        description = "Reload the fish shell";
        body = "exec fish $argv";
      };
      incognito = {
        description = "Start a new fish shell in incognito mode (no history)";
        # INCOGNITO_MODE is for the prompt's indicator
        body = "env INCOGNITO_MODE=on fish -P";
      };
      tn = {
        description = "Change tmux window name";
        body = ''
          if test (count $argv) -ne 1
            echo "Usage: tn <name>"
            return 1
          end
          tmux rename-window $argv[1]
        '';
      };
      ssh-add-keys = {
        description = "Add common SSH keys to agent";
        body = ''
          ssh-add ~/.ssh/id_ed25519 2>/dev/null
          ssh-add ~/.ssh/id_rsa 2>/dev/null
        '';
      };
      colors = ''
        for color in red green yellow blue magenta cyan white black
          printf "%b%s\t\t%b%s\t\t%b%s\t\t%b%s\n" \
            (set_color $color) $color \
            (set_color br$color) "bright_$color" \
            (set_color -o $color) bold_$color \
            (set_color -o br$color) "bold_bright_$color"
        end
      '';
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

      ''
        # Solarized dark syntax highlighting
        set -g fish_color_autosuggestion 586e75
        set -g fish_color_cancel --reverse
        set -g fish_color_command 93a1a1
        set -g fish_color_comment 586e75
        set -g fish_color_cwd green
        set -g fish_color_cwd_root red
        set -g fish_color_end 268bd2
        set -g fish_color_error dc322f
        set -g fish_color_escape 00a6b2
        set -g fish_color_history_current --bold
        set -g fish_color_host normal
        set -g fish_color_match --background=brblue
        set -g fish_color_normal normal
        set -g fish_color_operator 00a6b2
        set -g fish_color_param 839496
        set -g fish_color_quote 657b83
        set -g fish_color_redirection 6c71c4
        set -g fish_color_search_match red
        set -g fish_color_selection white --bold --background=brblack
        set -g fish_color_status red
        set -g fish_color_user brgreen
        set -g fish_color_valid_path --underline

        # Solarized dark completion pager
        set -g fish_pager_color_progress fdf6e3
        set -g fish_pager_color_prefix 586e75
        set -g fish_pager_color_completion fdf6e3
        set -g fish_pager_color_description b58900
        set -g fish_pager_color_selected_background --background=93a1a1
        set -g fish_pager_color_selected_prefix 073642
        set -g fish_pager_color_selected_completion 93a1a1
        set -g fish_pager_color_selected_description 073642
        set -g fish_pager_color_secondary_prefix 93a1a1
        set -g fish_pager_color_secondary_completion
        set -g fish_pager_color_secondary_description

        # Colorize man pages
        set -gx LESS_TERMCAP_mb (set_color -o blue)
        set -gx LESS_TERMCAP_md (set_color -o cyan)
        set -gx LESS_TERMCAP_me (set_color normal)
        set -gx LESS_TERMCAP_so (set_color -b white black)
        set -gx LESS_TERMCAP_se (set_color normal)
        set -gx LESS_TERMCAP_us (set_color -u magenta)
        set -gx LESS_TERMCAP_ue (set_color normal)
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
