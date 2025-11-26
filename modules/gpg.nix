{
  pkgs,
  ...
}:

{
  programs.gpg = {
    enable = true;
    settings = {
      default-key = "FBC98F20D0EB443EA67B41C170FA7961EA5F66A9";
      no-emit-version = true;
      no-comments = true;
      keyid-format = "0xlong";
      with-fingerprint = true;
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      use-agent = true;
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "no-honor-keyserver-url";
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    # TODO support pinentry on linux
    # pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
    pinentry.package = pkgs.pinentry_mac;
    enableSshSupport = false;
  };
}
