{ pkgs, config, ... }:

{
  # Home Manager configuration shared by the macOS workstations
  targets.darwin.copyApps = {
    enable = true;
    directory = "Applications/HomeManager";
  };
  targets.darwin.linkApps.enable = false;

  programs.nh.darwinFlake = "${config.home.homeDirectory}/.config/nix-config/";

  programs.fish.interactiveShellInit = ''
    # Toggle solarized light/dark via ghostty config override
    function toggle-solarized --description "Toggle Ghostty between Solarized Dark/Light"
      set -l override_file ~/.config/ghostty/theme-override.ghostty
      if test -f $override_file
        rm $override_file
        echo "Solarized Dark activated, press  cmd + shift + ,  to activate."
      else
        echo 'theme = "iTerm2 Solarized Light"' > $override_file
        echo "Solarized Light activated, press  cmd + shift + ,  to activate."
      end
    end
  '';

  programs.ghostty = {
    enable = true;
    # Installed by the ghostty Homebrew cask
    package = null;
    settings = {
      font-size = 17;
      font-family = "TX-02";
      font-style = "Regular";
      font-style-bold = "Bold";
      font-thicken = true;

      theme = "iTerm2 Solarized Dark";
      cursor-style = "block";
      cursor-style-blink = false;

      window-theme = "system";
      window-padding-balance = true;
      window-padding-x = 6;
      window-padding-y = 1;

      clipboard-read = "allow";
      clipboard-write = "allow";

      shell-integration = "fish";
      shell-integration-features = "no-cursor";

      macos-titlebar-style = "native";
      macos-titlebar-proxy-icon = "hidden";
      macos-dock-drop-behavior = "new-window";

      keybind = "global:cmd+control+t=toggle_quick_terminal";

      auto-update = "off";
      config-file = "?theme-override.ghostty";
    };
  };

  home.sessionVariables = {
    BROWSER = "open";
    COLIMA_HOME = "${config.xdg.configHome}/colima";
  };

  # Locally compiled Emacs, ahead of the Homebrew one
  home.sessionPath = [
    "$HOME/Applications/Emacs.app/Contents/MacOS/bin"
    "/Applications/Emacs.app/Contents/MacOS/bin"
    "$HOME/Applications/Emacs.app/Contents/MacOS"
    "/Applications/Emacs.app/Contents/MacOS"
  ];

  programs.fish.shellAbbrs = {
    dnscache = "dscacheutil -flushcache";
    e = "emacs -nw";
    "o." = "open .";
  };

  home.packages = with pkgs; [
    # global nix utilities
    devenv

    # Shell & Terminal
    macmon

    # Development Tools
    gitea-cli

    # Cloud & Infrastructure
    colima

    # Languages / LSP
    astro-language-server

    # Other
    typst
    zstd

    # macOS
    minijinja
    pinentry_mac
    terminal-notifier
    mas
  ];
}
