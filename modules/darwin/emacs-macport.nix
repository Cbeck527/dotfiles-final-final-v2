{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.emacs;

  emacs-macport =
    (pkgs.emacs-macport.override {
      withDbus = false;
      withImageMagick = false;
      withNativeCompilation = true;
      withSQLite3 = true;
      withTreeSitter = true;
      withWebP = true;
    }).overrideAttrs
      (old: {
        # Opt out of sandbox: byte-compiling url.el triggers GnuTLS cert
        # scanning of /etc/ssl/certs. Requires sandbox = "relaxed" in nix settings.
        __noChroot = true;

        configureFlags = old.configureFlags ++ lib.optionals cfg.macMetal [ "--with-mac-metal" ];

        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE =
            if cfg.cflags.append then
              "${old.env.NIX_CFLAGS_COMPILE or ""} ${cfg.cflags.value}"
            else
              cfg.cflags.value;
        };
      });

  emacs-lsp-booster = pkgs.emacs-lsp-booster.override {
    emacs = emacs-macport;
  };
in
{
  options.custom.emacs = {
    macMetal = lib.mkEnableOption "Mac Metal acceleration for Emacs" // {
      default = true;
    };
    cflags = {
      value = lib.mkOption {
        type = lib.types.str;
        default = "-O3 -mcpu=native -fobjc-arc -DFD_SETSIZE=10000 -D_DARWIN_UNLIMITED_SELECT";
        description = "CFLAGS for Emacs compilation";
      };
      append = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "If true, append to base NIX_CFLAGS_COMPILE; if false, replace entirely";
      };
    };
  };

  config = {
    home-manager.users.${config.machine.username}.home.packages = [
      emacs-macport
      emacs-lsp-booster
    ];
  };
}
