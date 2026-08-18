{ lib, config, ... }:

{
  options.custom.bash.fishHandoff.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Keep bash as the login shell in /etc/passwd, but exec fish for
      interactive sessions.

      Coder's agent reads the login shell from /etc/passwd and runs its own
      plumbing through it: shebang-less template scripts are piped to it on
      stdin, and internal helpers are wrapped as `$SHELL -c 'cmd "$@"' -- args`.
      Neither survives fish, which has no `set -e` and no `$@`. Pointing
      /etc/passwd back at bash fixes both while still landing every shell you
      actually type in at fish.
    '';
  };

  config = {
    programs.bash = {
      enable = true;

      # Ordered last so the rest of .bashrc (direnv, fzf, GPG_TTY) is fully
      # applied before the exec. That work is discarded when the handoff fires,
      # which is a few tens of milliseconds; the tradeoff is that if fish is
      # ever missing, the fallback is a completely set up bash.
      initExtra = lib.mkIf config.custom.bash.fishHandoff.enable (
        lib.mkOrder 2000 ''
          # Hand interactive sessions off to fish. See custom.bash.fishHandoff.
          #
          # Each guard is load-bearing:
          #   $-           Non-interactive shells must stay bash — this is the
          #                whole point of the handoff. Home Manager already
          #                returns early for those higher up in this file; the
          #                check is repeated because moving this block to
          #                bashrcExtra (which is *not* guarded) would otherwise
          #                break the coder agent far worse than fish alone did.
          #   guard var    Exported before the exec, so a deliberate `bash`
          #                launched from inside fish stays bash instead of
          #                bouncing straight back. This is the escape hatch.
          #   TERM/EMACS   Emacs TRAMP and `M-x shell` drive a dumb shell and
          #                parse its output; fish's prompt confuses them.
          #   command -v   Never exec something that may not exist. A partially
          #                activated nix profile would otherwise lock every
          #                interactive session out of the workspace.
          if [[ $- == *i* ]] \
            && [[ -z "''${__NIXCFG_FISH_HANDOFF:-}" ]] \
            && [[ "''${TERM:-dumb}" != "dumb" ]] \
            && [[ -z "''${INSIDE_EMACS:-}" ]] \
            && command -v fish > /dev/null 2>&1; then
            export __NIXCFG_FISH_HANDOFF=1
            # Preserve login-ness so fish sees the same shell class bash did.
            if shopt -q login_shell; then
              exec fish --login
            else
              exec fish
            fi
          fi
        ''
      );
    };
  };
}
