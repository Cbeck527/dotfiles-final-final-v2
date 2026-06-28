# Debian Bootstrap

This repo can manage Linux user configuration with Home Manager. On Debian, it
does not manage root-owned system state unless the machine is migrated to NixOS,
so a few bootstrap steps still happen outside the flake.

These notes assume:

- the machine is Debian or Debian-like Linux
- Nix or Lix is already installed in multi-user mode
- the primary user is `chris`
- the checkout lives at `~/.config/nix-config`

## 1. Load Nix In The Current Shell

After a fresh Lix install, log out and back in before continuing. The installer
adds the shell bootstrap under `/etc`, so a new login shell should already have
`nix` and the rest of the Nix tools on `PATH`.

If working in the same shell that ran the installer, load the profile script
manually:

```bash
unset __ETC_PROFILE_NIX_SOURCED
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix --version
```

## 2. Configure The Nix Daemon

The Lix installer writes `/etc/nix/nix.conf` and includes
`/etc/nix/nix.custom.conf`. Put local daemon settings in the custom file so the
installer-owned file stays intact.

```bash
sudo tee /etc/nix/nix.custom.conf >/dev/null <<'EOF'
# Local daemon settings for nix-config Linux hosts.
trusted-users = root chris

accept-flake-config = true
warn-dirty = false

keep-outputs = true
keep-derivations = true

substituters = https://cache.nixos.org/ https://cache.numtide.com https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF

sudo systemctl restart nix-daemon.socket
sudo systemctl restart nix-daemon.service 2>/dev/null || true
```

Verify the effective config:

```bash
nix config show | rg 'trusted-users|accept-flake-config|warn-dirty|keep-outputs|keep-derivations|substituters|trusted-public-keys'
```

## 3. Build And Activate Home Manager

From the repo root:

```bash
just build
just switch
```

`just build` builds `.#homeConfigurations.$(hostname).activationPackage`.
`just switch` builds the same activation package and runs `./result/activate`.

If `just` is not available yet, use Nix directly:

```bash
nix build ".#homeConfigurations.$(hostname).activationPackage"
./result/activate
```

After activation, load Home Manager session variables in the current shell:

```bash
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

## 4. Make Home Manager Fish The Login Shell

Home Manager installs fish into the user profile. After `just switch`, add that
fish path to `/etc/shells` and make it the user's login shell.

```bash
fish_path="$(which fish)"
grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
chsh -s "$fish_path" "$USER"
```

Log out and back in, then verify:

```bash
echo "$SHELL"
fish -ic 'type nx; nx build'
```

## 5. Validate

```bash
nix flake check
just build
fish -ic 'type just; type rg; type bat; type eza; type fzf'
gpgconf --list-dirs agent-socket
tmux -V
```

On Linux, `nix flake check` may report that incompatible Darwin systems were
omitted. That is expected.
