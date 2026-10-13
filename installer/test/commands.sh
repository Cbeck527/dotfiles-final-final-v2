#!/bin/bash
set -euo pipefail
tool="${0##*/}"
printf '%s %s\n' "$tool" "$*" >> "$MOCK_LOG"
case "$tool" in
  id) if [[ "$1" == -u ]]; then printf '%s' "$MOCK_UID"; else printf chris; fi ;;
  uname) if [[ "$1" == -s ]]; then printf '%s' "$MOCK_OS"; else printf '%s' "$MOCK_ARCH"; fi ;;
  hostname|scutil) printf '%s' "$MOCK_HOST" ;;
  curl) printf 'Unexpected download\n' >&2; exit 99 ;;
  nix)
    if [[ "$1" == --version ]]; then printf 'nix (Lix) mock'; else exit "${MOCK_BUILD_FAIL:-0}"; fi
    ;;
  git)
    case "$*" in
      --version) printf 'git mock' ;;
      'check-ref-format '*) ;;
      'clone '*) [[ "${MOCK_CLONE_FAIL:-0}" == 0 ]] || exit 1; /bin/mkdir -p "${!#}/.git" ;;
      *'remote get-url origin') printf '%s' "$MOCK_ORIGIN" ;;
      *'symbolic-ref --quiet --short HEAD') printf '%s' "$MOCK_BRANCH" ;;
      *'rev-parse --verify '*) exit 1 ;;
      *'remote set-url --push origin '*) ;;
      *) printf 'Unexpected git call: %s\n' "$*" >&2; exit 99 ;;
    esac
    ;;
esac
