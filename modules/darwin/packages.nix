{
  pkgs,
  username,
  ...
}:

{
  # Darwin-specific packages
  home-manager.users.${username}.home.packages = [
    pkgs.minijinja
    pkgs.pinentry_mac
    (pkgs.python3.withPackages (ps: [ ps.pip ]))
    pkgs.terminal-notifier
    pkgs.mas
  ];
}
