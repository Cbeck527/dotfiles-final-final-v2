{
  pkgs,
  lib,
  username,
  ...
}:

let
  clearance = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "clearance";
    version = "1.3.1";

    src = pkgs.fetchurl {
      url = "https://github.com/prime-radiant-inc/clearance/releases/download/v${finalAttrs.version}/Clearance-${finalAttrs.version}-macOS.zip";
      hash = "sha256-k01mlq59SZTvuOEayAXLncQXETl+7rcD3j+FiYWHhEM=";
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
  home-manager.users.${username}.home.packages = [
    clearance
    pkgs.minijinja
    pkgs.pinentry_mac
    (pkgs.python3.withPackages (ps: [ ps.pip ]))
    pkgs.terminal-notifier
    pkgs.mas
  ];
}
