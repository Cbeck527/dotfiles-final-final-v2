{ lib, ... }:

{
  options.identity = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "Chris Becker";
      description = "Full name for git commits";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "chris@becker.am";
      description = "Email for git commits";
    };
    gpgKey = lib.mkOption {
      type = lib.types.str;
      default = "FBC98F20D0EB443EA67B41C170FA7961EA5F66A9";
      description = "GPG key ID for signing";
    };
    githubUser = lib.mkOption {
      type = lib.types.str;
      default = "Cbeck527";
      description = "GitHub username";
    };
  };
}
