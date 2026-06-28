# Eval-Type Host Structure Design

## Goal

Reorganize the repository so each path makes the Nix evaluation type obvious.
This should make new Linux machine onboarding easier to reason about while
keeping host configurations explicit and easy to skim.

## Current Problem

The current `machines/` tree mixes different kinds of modules:

- macOS hosts are nix-darwin system modules.
- `sweetums` is a Home Manager-only Linux module.
- `modules/home-manager.nix` is Darwin system glue that nests a Home Manager
  user configuration.
- `modules/home/headless.nix` is closer to a pure Home Manager module.

That makes the machine, OS, user, and system boundaries harder to see from file
paths alone.

## Design

Use evaluation type as the top-level host boundary:

```text
hosts/
  darwin/
    beckbook-pro/default.nix
    mac-h99xrph3j9/default.nix
  linux/
    sweetums/default.nix
  nixos/
    # future, only when a NixOS host exists

modules/
  darwin/
  linux/
  programs/
  shared/
```

The directory rules are:

- `hosts/darwin/*` contains nix-darwin host modules.
- `hosts/linux/*` contains pure Home Manager modules for non-NixOS Linux hosts.
- `hosts/nixos/*` is reserved for future NixOS system modules.
- `modules/darwin/*` contains nix-darwin/system modules.
- `modules/linux/*` contains Linux Home Manager support modules.
- `modules/programs/*` contains reusable Home Manager program modules.
- `modules/shared/*` contains cross-evaluation options and identity data.

## Host Shape

Hosts should stay top-heavy. A host file should show most of the machine's
personality directly: imports, username/home, packages, host-specific program
settings, and host-specific service settings.

Shared modules should be small building blocks, not hidden profiles. Avoid
creating a `profiles/` layer for now. If several future Linux hosts repeat the
same large block, add a small shared module only after the duplication is real.

## Linux Hosts

Non-NixOS Linux hosts remain pure Home Manager modules. `flake.nix` owns the
`home-manager.lib.homeManagerConfiguration` call and imports the host module.

A Linux host should look like this shape:

```nix
{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/shared/identity.nix
    ../../../modules/linux/nix.nix
    ../../../modules/programs/fish.nix
    ../../../modules/programs/git.nix
    ../../../modules/programs/gpg.nix
    ../../../modules/programs/tmux.nix
  ];

  machine.username = "chris";
  machine.home = "/home/chris";

  home = {
    username = config.machine.username;
    homeDirectory = config.machine.home;
    stateVersion = "25.05";

    packages = with pkgs; [
      just
      ripgrep
      bat
      eza
      fzf
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  programs.home-manager.enable = true;
  programs.bash.enable = true;
}
```

## Darwin Hosts

Darwin hosts remain nix-darwin system modules. They should import Darwin system
modules and configure their Home Manager user explicitly where host-specific
behavior matters.

The current Darwin Home Manager glue should move from `modules/home-manager.nix`
to a Darwin-scoped path such as `modules/darwin/home-manager.nix`, because it is
not a pure Home Manager module.

## Flake Outputs

`flake.nix` should keep the evaluation boundary clear:

- `darwinConfigurations` imports from `hosts/darwin/*`.
- `homeConfigurations` imports from `hosts/linux/*`.
- Future `nixosConfigurations` imports from `hosts/nixos/*`.

Do not introduce host builder helpers yet. Direct flake entries are easier to
read at the current scale.

## Migration Notes

Move or rename files without changing behavior first:

- `machines/beckbook-pro` -> `hosts/darwin/beckbook-pro`
- `machines/mac-h99xrph3j9` -> `hosts/darwin/mac-h99xrph3j9`
- `machines/sweetums` -> `hosts/linux/sweetums`
- `modules/machine.nix` -> `modules/shared/machine.nix`
- `modules/identity.nix` -> `modules/shared/identity.nix`
- `modules/git.nix` -> `modules/programs/git.nix`
- `modules/gpg.nix` -> `modules/programs/gpg.nix`
- `modules/tmux.nix` -> `modules/programs/tmux.nix`
- `modules/llms` -> `modules/programs/llms`
- `modules/home/nix.nix` -> `modules/linux/nix.nix`
- `modules/home-manager.nix` -> `modules/darwin/home-manager.nix`
- `modules/emacs-macport.nix` -> `modules/darwin/emacs-macport.nix`

After the move-only pass, split duplicated Home Manager shell/user setup only
where it clearly improves readability.

## Validation

Minimum validation after implementation:

- `git diff --check`
- `just fmt`
- `nix flake check --no-build --all-systems`
- `nix eval .#homeConfigurations.sweetums.activationPackage.drvPath`
- A Darwin configuration eval using the local private override when available

Full Linux activation package builds may need to run on an x86_64 Linux host.
