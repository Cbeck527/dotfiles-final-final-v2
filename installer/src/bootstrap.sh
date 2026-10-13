#!/usr/bin/env bash
set -euo pipefail

main() {
  # __INSTALLER_OPTIONS__
  : "${host:?}" "${ref:?}" "${build:?}"
  local checkout="$HOME/.config/nix-config"
  local repo_https=https://github.com/Cbeck527/dotfiles-final-final-v2.git
  local repo_ssh=git@github.com:Cbeck527/dotfiles-final-final-v2.git
  local os arch user output origin branch tag_commit installer

  user="$(id -un)"
  [[ "$(id -u)" != 0 ]] || fail 'Run as your normal user; the Lix installer uses sudo when needed.'
  for tool in curl git; do
    command -v "$tool" >/dev/null || fail "Install $tool before running this installer."
  done
  git --version >/dev/null
  git check-ref-format --branch "$ref" >/dev/null

  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin|Linux) ;;
    *) fail "Unsupported operating system: $os" ;;
  esac
  if [[ "$host" == auto ]]; then
    if [[ "${CODER:-}" == true ]]; then
      host=coder
    elif [[ "$os" == Darwin ]]; then
      host="$(scutil --get LocalHostName)"
    else
      host="$(hostname -s)"
    fi
  fi

  if [[ "$build" == 1 ]]; then
    case "$os/$arch/$host" in
      Darwin/arm64/beckbook-pro|Darwin/arm64/mac-h99xrph3j9)
        output="darwinConfigurations.$host.system"
        ;;
      Linux/x86_64/sweetums|Linux/x86_64/coder)
        output="homeConfigurations.$host.activationPackage"
        ;;
      *) fail "No configuration for $os/$arch/$host. Select ?host=... or use ?build=0 to prepare a new host." ;;
    esac
  fi

  if [[ -e "$checkout" || -L "$checkout" ]]; then
    [[ -e "$checkout/.git" ]] || fail "$checkout exists but is not a Git checkout."
    origin="$(git -C "$checkout" remote get-url origin)"
    [[ "$origin" == "$repo_https" || "$origin" == "$repo_ssh" ]] || fail "$checkout belongs to a different repository."
    branch="$(git -C "$checkout" symbolic-ref --quiet --short HEAD || true)"
    if [[ "$branch" != "$ref" ]]; then
      tag_commit="$(git -C "$checkout" rev-parse --verify "refs/tags/$ref^{commit}" 2>/dev/null || true)"
      [[ -z "$branch" && -n "$tag_commit" && "$tag_commit" == "$(git -C "$checkout" rev-parse HEAD)" ]] ||
        fail "Existing checkout is not on $ref. Change its ref yourself or request its current branch."
    fi
    printf 'checkout: reusing %s (no pull or reset)\n' "$checkout"
  fi

  load_nix
  if command -v nix >/dev/null; then
    printf 'nix: reusing %s\n' "$(nix --version)"
  else
    [[ ! -e /nix/receipt.json ]] || fail 'A Nix receipt exists but nix is unavailable. Repair the existing installation first.'
    printf '%s\n' 'lix: installing from install.lix.systems'
    installer="$(mktemp)"
    trap 'rm -f "$installer"' EXIT
    curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
      https://install.lix.systems/lix --output "$installer"
    # --enable-flakes toggles the default off; the environment variable sets it.
    NIX_INSTALLER_ENABLE_FLAKES=true sh "$installer" install --no-confirm \
      --extra-conf "trusted-users = root $user" \
      --extra-conf 'accept-flake-config = true' \
      --extra-conf 'warn-dirty = false' </dev/null
    rm -f "$installer"
    trap - EXIT
    load_nix
    command -v nix >/dev/null || fail 'Lix installed but nix is unavailable in this shell.'
  fi

  if [[ ! -e "$checkout/.git" ]]; then
    mkdir -p "$HOME/.config"
    git clone --branch "$ref" -- "$repo_https" "$checkout" </dev/null
    git -C "$checkout" remote set-url --push origin "$repo_ssh"
  fi

  if [[ "$build" == 0 ]]; then
    printf 'Ready: %s\nBuild skipped. Add/select a host configuration before building.\n' "$checkout"
    return
  fi

  cd "$checkout"
  printf 'building: %s\n' "$output"
  printf '%s\n' 'The private flake input requires GitHub SSH access on this machine.'
  if ! nix --extra-experimental-features 'nix-command flakes' --accept-flake-config \
    build --no-write-lock-file ".#$output" </dev/null; then
    fail 'Build failed. Check the Nix error above, including SSH access to private inputs; then rerun the installer.'
  fi

  printf '\nBuilt successfully. To activate after reviewing the configuration:\n'
  printf '  cd %q\n' "$checkout"
  if [[ "$os" == Darwin ]]; then
    printf '  sudo ./result/sw/bin/darwin-rebuild switch --flake .#%s\n' "$host"
  else
    printf '%s\n' '  HOME_MANAGER_BACKUP_EXT=hm-backup HOME_MANAGER_BACKUP_OVERWRITE=1 ./result/activate'
    if [[ "$host" == coder ]]; then
      printf '%s\n' '  CODER=true just hjem-switch' '  just login-shell-bash'
    fi
  fi
}

load_nix() {
  if ! command -v nix >/dev/null && [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    unset __ETC_PROFILE_NIX_SOURCED
    # The installer owns this profile script; it may read unset variables.
    set +u
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    set -u
  fi
}

fail() {
  printf 'installer: %s\n' "$*" >&2
  exit 1
}

main
