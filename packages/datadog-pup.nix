{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "datadog-pup";
  version = "0.27.0";
  src = fetchurl {
    url = "https://github.com/DataDog/pup/releases/download/v${finalAttrs.version}/pup_${finalAttrs.version}_Darwin_arm64.tar.gz";
    hash = "sha256-beHU+qv/wv9Fa3oBHlGKjipoIF2Wcnq8CFz1xlyeVwk=";
  };
  sourceRoot = ".";
  installPhase = ''
    install -Dm755 pup $out/bin/pup
  '';
})
