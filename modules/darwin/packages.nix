{
  pkgs,
  username,
  ...
}:

{
  # Darwin-specific packages
  home-manager.users.${username}.home.packages = with pkgs; [
    minijinja
    pinentry_mac
    (python3.withPackages (ps: [ ps.pip ]))
    terminal-notifier
  ];
}
