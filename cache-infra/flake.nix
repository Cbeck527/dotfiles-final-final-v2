{
  description = "attic3 cache infra development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
      ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          railway = pkgs.stdenvNoCC.mkDerivation rec {
            pname = "railway";
            version = "5.54.1";

            src = pkgs.fetchurl {
              url = "https://github.com/railwayapp/cli/releases/download/v${version}/railway-v${version}-aarch64-apple-darwin.tar.gz";
              hash = "sha256-cD+zmIMm6pgUwNvn/9qqJqw1B12L17suX8Yct5RyYRo=";
            };

            sourceRoot = ".";
            dontFixup = true;

            installPhase = ''
              runHook preInstall
              install -Dm755 railway "$out/bin/railway"
              runHook postInstall
            '';

            meta = {
              mainProgram = "railway";
              platforms = [ "aarch64-darwin" ];
            };
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              railway
              pkgs.nodejs
              pkgs.pnpm
            ];
          };
        }
      );
    };
}
