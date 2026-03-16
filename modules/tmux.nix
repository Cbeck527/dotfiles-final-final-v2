{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    historyLimit = 50000;
    mouse = true;
    escapeTime = 0;
    keyMode = "vi";
    focusEvents = true;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = tmux-fzf;
        extraConfig = ''
          set-environment -g TMUX_FZF_LAUNCH_KEY "C-f"
          set-environment -g TMUX_FZF_PREVIEW 0
          set-environment -g TMUX_FZF_SWITCH_CURRENT 1
        '';
      }
      {
        plugin = prefix-highlight;
        extraConfig = ''
          set -g @prefix_highlight_fg 'cyan,bold'
          set -g @prefix_highlight_bg 'default'
          set -g @prefix_highlight_show_copy_mode 'on'
          set -g @prefix_highlight_copy_mode_attr 'fg=yellow,bold'
          set -g @prefix_highlight_copy_prompt 'Copy'
          set -g @prefix_highlight_show_sync_mode 'on'
          set -g @prefix_highlight_sync_mode_attr 'fg=red,bold'
          set -g @prefix_highlight_sync_prompt 'SYNC'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
          set -g @continuum-boot 'off'
        '';
      }
    ];

    extraConfig = ''
      # -- global ------------------------------------------------------------------
      unbind C-b
      bind a send-prefix
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # -- navigation --------------------------------------------------------------
      bind C-c command-prompt -p 'New session name: ' 'new-session -s "%%"'

      # window navigation
      unbind n
      unbind p
      bind C-n next-window
      bind C-p previous-window
      bind C-a last-window

      unbind '"'
      unbind '%'
      bind S split-window -v -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"

      # new window with name
      bind-key C command-prompt -p 'New window name:' "new-window -n %%"

      # pane navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind > swap-pane -D
      bind < swap-pane -U

      # maximize current pane
      bind Q resize-pane -Z

      # pane resizing
      bind -r H resize-pane -L 2
      bind -r J resize-pane -D 2
      bind -r K resize-pane -U 2
      bind -r L resize-pane -R 2

      # -- display -----------------------------------------------------------------
      set -g set-titles on
      set -g set-titles-string '#S-#I-#P #W'
      set -g display-panes-time 800
      set -g display-time 4000

      # activity
      set -g monitor-activity on
      set -g visual-activity off

      set -g renumber-windows on
      set -g status-interval 5
      setw -g automatic-rename on
      # timing
      set -sg repeat-time 600

      # statusline
      set -g status-justify absolute-centre
      set -g status-left '#[fg=default][ #[fg=blue]#S #[fg=default]]'
      set -g status-right '#{prefix_highlight} #(whoami)@#H'
      set -g status-right-length 1000
      set -g status-left-length 1000
      set -g status-style fg=cyan,bg=black
      setw -g window-status-current-format '#[fg=red]( #[fg=white]#I- #W#[fg=red]#F )'
      setw -g window-status-format '#I #W#F '

      # -- custom ------------------------------------------------------------------
      bind C-y setw synchronize-panes
      bind C-x setw synchronize-panes

      # keep status-keys as emacs (vi mode-keys set above via keyMode)
      set -g status-keys emacs

      # copy mode
      bind Enter copy-mode
      bind-key -T copy-mode Escape send-keys -X cancel
      bind-key -T copy-mode-vi Escape send-keys -X cancel
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel
      bind-key -T copy-mode-vi H send -X start-of-line
      bind-key -T copy-mode-vi L send -X end-of-line

      # buffers
      bind b list-buffers
      bind p paste-buffer
      bind P choose-buffer

      bind J select-layout even-vertical
      bind H select-layout even-horizontal

      # source local overrides
      source -q ~/.tmux.conf.local
    '';
  };
}
