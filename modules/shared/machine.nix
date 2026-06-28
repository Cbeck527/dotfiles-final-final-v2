{ lib, ... }:
{
  options.machine = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user login name";
    };
    home = lib.mkOption {
      type = lib.types.str;
      description = "Primary user home directory path";
    };
  };
}
