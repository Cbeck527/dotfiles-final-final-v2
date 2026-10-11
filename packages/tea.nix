# NOTE: use my fork's release until https://gitea.com/gitea/tea/pulls/1130 gets merged
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
      hash = "sha256-7kdPG9//Opclb+GCLcSVHBfdHL8lDvAb6kGU8vdAZk8=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-wL1eY2OurmMSXhSNoMr2JZQ8/nFB0xGLARhAXnXpZ+w=";
    };
    x86_64-linux = {
      platform = "linux-amd64";
      hash = "sha256-3OHTZw6lvv724ix8Lt1UiT5CI1I1tAfCvJzxC4DPYto=";
    };
  };
  system = stdenv.hostPlatform.system;
  asset = assets.${system} or (throw "tea: no release asset for ${system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tea";
  version = "0.16.0-custom-headers";
  src = fetchurl {
    url = "https://gitea.com/chrisbecker/tea/releases/download/v${finalAttrs.version}/tea-${finalAttrs.version}-${asset.platform}.xz";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ installShellFiles ];

  # The release asset is a bare xz-compressed binary, not a tarball.
  unpackPhase = ''
    xz -dc "$src" > tea
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 tea $out/bin/tea
    runHook postInstall
  '';
  # Completions and the man page come from running the binary, so skip them when cross-compiling.
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd tea \
      --bash <($out/bin/tea completion bash) \
      --fish <($out/bin/tea completion fish) \
      --zsh <($out/bin/tea completion zsh)
    $out/bin/tea man --out $out/share/man/man1/tea.1
  '';

  meta = {
    description = "Gitea CLI client with custom HTTP headers support";
    homepage = "https://gitea.com/chrisbecker/tea";
    license = lib.licenses.mit;
    mainProgram = "tea";
    platforms = builtins.attrNames assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
