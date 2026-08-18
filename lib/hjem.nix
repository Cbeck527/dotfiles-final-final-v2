# Standalone Hjem evaluation for pure Home Manager hosts.
#
# Hjem ships module entry points for NixOS, nix-darwin, and Finix, but not for
# hosts that are only managed by Home Manager. Its per-user options live in a
# deliberately platform-agnostic module (`modules/common/user.nix`), so we
# evaluate that module directly and emit the v3 manifest that the
# `hjem standalone` CLI consumes.
#
# Returns:
#
# - `manifest`: the manifest attrset, for `hjem standalone switch --flake`.
# - `manifestFile`: the same manifest, realised as a store file. Prefer this
#   (`nix build` it, then `hjem standalone switch --manifest`): the CLI's
#   `--flake` path links files *before* it realises their store paths, so
#   sources that are not already built — anything using `text` or `generator` —
#   fail to activate. Building this derivation first realises every source,
#   because the JSON carries their store paths in its string context.
# - `config`, `options`: the evaluated module, for `nix eval` debugging.
{
  lib,
  hjem,
}:
{
  pkgs,
  username,
  home,
  modules ? [ ],
}:
let
  hjem-lib = hjem.hjem-lib.${pkgs.stdenv.hostPlatform.system};

  eval = lib.evalModules {
    # Hjem's per-user module declares `_class = "hjem"`.
    class = "hjem";
    specialArgs = { inherit hjem-lib pkgs; };
    modules = [
      "${hjem}/modules/common/user.nix"
      {
        # Normally supplied by the submodule name under `hjem.users.<username>`.
        _module.args.name = username;

        user = username;
        directory = home;
        clobberFiles = false;
      }
    ]
    ++ modules;
  };

  cfg = eval.config;

  # Same file sets and manifest shape that Hjem's own platform modules build.
  # Keep in sync with `modules/nixos/base.nix` in the Hjem input.
  files =
    lib.pipe
      [
        cfg.files
        cfg.xdg.cache.files
        cfg.xdg.config.files
        cfg.xdg.data.files
        cfg.xdg.state.files
      ]
      [
        (lib.concatMap lib.attrValues)
        (lib.filter (f: f.enable))
        (map hjem-lib.fileToJson)
      ];

  manifest = {
    version = 3;
    inherit files;
  };

  failed = map (a: a.message) (lib.filter (a: !a.assertion) cfg.assertions);
in
lib.throwIf (failed != [ ])
  ''
    Failed Hjem assertions for ${username}:
    ${lib.concatMapStringsSep "\n" (message: "- ${message}") failed}
  ''
  (
    lib.showWarnings cfg.warnings {
      inherit (eval) config options;
      inherit manifest;

      manifestFile = pkgs.writeText "hjem-manifest-${username}.json" (builtins.toJSON manifest);
    }
  )
