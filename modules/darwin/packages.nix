{
  pkgs,
  lib,
  username,
  ...
}:

let
  clearance = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "clearance";
    version = "1.2.3";

    src = pkgs.fetchurl {
      url = "https://github.com/prime-radiant-inc/clearance/releases/download/v${finalAttrs.version}/Clearance-${finalAttrs.version}-macOS.zip";
      hash = "sha256-7rRWJkl2+8aL7O9RHZSQYB1R/I2VG+ieaC0/uZsFA5w=";
    };

    nativeBuildInputs = [ pkgs.unzip ];
    sourceRoot = "Clearance.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Clearance.app
      cp -R . $out/Applications/Clearance.app
      runHook postInstall
    '';

    meta = {
      description = "Native macOS Markdown editor with YAML frontmatter support";
      homepage = "https://github.com/prime-radiant-inc/clearance";
      license = lib.licenses.asl20;
      platforms = lib.platforms.darwin;
    };
  });
in
{
  # Darwin-specific packages
  home-manager.users.${username}.home.packages = with pkgs; [
    clearance
    minijinja
    pinentry_mac
    (python3.withPackages (ps: [ ps.pip ]))
    terminal-notifier
    mas
  ];
}
