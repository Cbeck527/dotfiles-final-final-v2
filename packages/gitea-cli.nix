{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:
let
  # Nix system -> release asset platform suffix and hash of its .xz asset.
  assets = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-ZxWsWjLQp9oo6lHuD5r4L850xr3GVzxnIw61CD0Teek=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-HgQ1BTPY5kICzTkI3iflJ1toi9PVaKVZRk5HamktLig=";
    };
    x86_64-linux = {
      platform = "linux-amd64";
      hash = "sha256-cgnGW3+hnPL4OYtiZcUkc7nT+pW4Dsmf0xHYUnSxVDM=";
    };
  };
  system = stdenv.hostPlatform.system;
  asset = assets.${system} or (throw "gitea-cli: no release asset for ${system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gitea-cli";
  version = "0.1.0";
  src = fetchurl {
    url = "https://gitea.com/gitea/cli/releases/download/v${finalAttrs.version}/gitea-cli-${finalAttrs.version}-${asset.platform}.xz";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ installShellFiles ];

  # The release asset is a bare xz-compressed binary, not a tarball.
  unpackPhase = ''
    xz -dc "$src" > gt
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 gt $out/bin/gt
    runHook postInstall
  '';
  # Completions and the man page come from running the binary, so skip them when cross-compiling.
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd gt \
      --bash <($out/bin/gt completion bash) \
      --fish <($out/bin/gt completion fish) \
      --zsh <($out/bin/gt completion zsh)
    $out/bin/gt man > gt.1
    installManPage gt.1
  '';

  meta = {
    description = "Official command line client for Gitea";
    homepage = "https://gitea.com/gitea/cli";
    license = lib.licenses.mit;
    mainProgram = "gt";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
