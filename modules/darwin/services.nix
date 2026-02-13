{
  config,
  lib,
  ...
}:

let
  cfg = config.services.caffeinate;
in
{
  options.services.caffeinate = {
    enable = lib.mkOption {
      description = "Whether to enable the caffeinate daemon";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
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
