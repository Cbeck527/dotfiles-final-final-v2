{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.emacs;

  liquidGlassIcons = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jimeh/emacs-liquid-glass-icons/6e25183fe5a4bdda88458cef44ff7cb0ce678d49/Resources/Assets.car";
    sha256 = "sha256-1XTC872AnytHyfqZB3J805EdwJmRYxvexl1sTnmtZTg=";
  };

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
        configureFlags = old.configureFlags ++ [ "--with-mac-metal" ];

        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE or ""} -O3 -mcpu=native -fobjc-arc";
        };

        postInstall =
          (old.postInstall or "")
          + lib.optionalString cfg.liquidGlassIcons ''
            if [ -d "$out/Applications/Emacs.app/Contents/Resources" ]; then
              echo "Installing liquid-glass-icons Assets.car"
              cp ${liquidGlassIcons} "$out/Applications/Emacs.app/Contents/Resources/Assets.car"

              plist="$out/Applications/Emacs.app/Contents/Info.plist"
              if ! grep -q "CFBundleIconName" "$plist"; then
                echo "Setting CFBundleIconName in Info.plist"
                ${pkgs.gnused}/bin/sed -i '/<\/dict>/i \
    <key>CFBundleIconName</key>\
    <string>EmacsLG1</string>' "$plist"
              fi
            fi
          '';
      });
in
{
  options.custom.emacs = {
    liquidGlassIcons = lib.mkEnableOption "liquid-glass icons for Emacs";
  };

  config = {
    environment.systemPackages = [ emacs-macport ];
  };
}
