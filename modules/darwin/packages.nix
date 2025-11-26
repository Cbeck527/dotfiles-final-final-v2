{
  pkgs,
  username,
  ...
}:

{
  # Darwin-specific packages
  home-manager.users.${username}.home.packages = with pkgs; [
    pinentry_mac
    terminal-notifier
  ];
}
