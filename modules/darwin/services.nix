{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.caffeinate;
in
{
  options.services.caffeinate = {
    enable = mkOption {
      description = "Whether to enable the caffeinate daemon";
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.caffeinate = {
      script = ''
        exec /usr/bin/caffeinate -i -u -s -d
      '';
      serviceConfig = {
        RunAtLoad = true;
        UserName = "root";
        GroupName = "admin";
        KeepAlive = true;
      };
    };
  };
}
