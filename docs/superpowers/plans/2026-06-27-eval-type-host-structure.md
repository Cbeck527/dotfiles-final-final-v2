# Eval-Type Host Structure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the nix-config repository so host paths are grouped by flake evaluation type, with non-NixOS Linux hosts remaining pure Home Manager modules.

**Architecture:** `hosts/darwin/*` will hold nix-darwin modules and `hosts/linux/*` will hold pure Home Manager modules. Shared reusable Home Manager program modules move under `modules/programs`, Darwin system modules stay under `modules/darwin`, Linux Home Manager support modules live under `modules/linux`, and cross-evaluation options move under `modules/shared`.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, Just, Lix/Nix evaluation commands.

---

## File Structure

Final tree shape:

```text
hosts/
  darwin/
    beckbook-pro/default.nix
    mac-h99xrph3j9/default.nix
  linux/
    sweetums/default.nix

modules/
  darwin/
    defaults.nix
    emacs-macport.nix
    home-manager.nix
    homebrew.nix
    services.nix
  linux/
    nix.nix
  programs/
    fish.nix
    git.nix
    gpg.nix
    llms/
    tmux.nix
  shared/
    identity.nix
    machine.nix
```

Responsibilities:

- `hosts/darwin/*`: one nix-darwin system module per macOS host.
- `hosts/linux/*`: one pure Home Manager module per non-NixOS Linux host.
- `modules/darwin/*`: Darwin system modules and Darwin-specific Home Manager glue.
- `modules/linux/*`: Home Manager modules that only make sense on non-NixOS Linux.
- `modules/programs/*`: reusable Home Manager program modules.
- `modules/shared/*`: options and identity data usable from Darwin and Home Manager evaluations.

## Task 1: Move Files Into Eval-Type Directories

**Files:**
- Move: `machines/beckbook-pro/default.nix` -> `hosts/darwin/beckbook-pro/default.nix`
- Move: `machines/mac-h99xrph3j9/default.nix` -> `hosts/darwin/mac-h99xrph3j9/default.nix`
- Move: `machines/sweetums/default.nix` -> `hosts/linux/sweetums/default.nix`
- Move: `modules/machine.nix` -> `modules/shared/machine.nix`
- Move: `modules/identity.nix` -> `modules/shared/identity.nix`
- Move: `modules/git.nix` -> `modules/programs/git.nix`
- Move: `modules/gpg.nix` -> `modules/programs/gpg.nix`
- Move: `modules/tmux.nix` -> `modules/programs/tmux.nix`
- Move: `modules/llms/` -> `modules/programs/llms/`
- Move: `modules/home/nix.nix` -> `modules/linux/nix.nix`
- Move: `modules/home-manager.nix` -> `modules/darwin/home-manager.nix`
- Move: `modules/emacs-macport.nix` -> `modules/darwin/emacs-macport.nix`
- Modify: `flake.nix`
- Modify: `hosts/darwin/beckbook-pro/default.nix`
- Modify: `hosts/darwin/mac-h99xrph3j9/default.nix`
- Modify: `hosts/linux/sweetums/default.nix`
- Modify: `modules/darwin/home-manager.nix`
- Modify: `modules/home/headless.nix`

- [ ] **Step 1: Create target directories**

```bash
mkdir -p hosts/darwin hosts/linux modules/shared modules/programs modules/linux
```

Expected: command exits with status 0.

- [ ] **Step 2: Move host and module files with Git**

```bash
git mv machines/beckbook-pro hosts/darwin/beckbook-pro
git mv machines/mac-h99xrph3j9 hosts/darwin/mac-h99xrph3j9
git mv machines/sweetums hosts/linux/sweetums
git mv modules/machine.nix modules/shared/machine.nix
git mv modules/identity.nix modules/shared/identity.nix
git mv modules/git.nix modules/programs/git.nix
git mv modules/gpg.nix modules/programs/gpg.nix
git mv modules/tmux.nix modules/programs/tmux.nix
git mv modules/llms modules/programs/llms
git mv modules/home/nix.nix modules/linux/nix.nix
git mv modules/home-manager.nix modules/darwin/home-manager.nix
git mv modules/emacs-macport.nix modules/darwin/emacs-macport.nix
```

Expected: command exits with status 0 and `git status --short` shows renames.

- [ ] **Step 3: Update flake host imports**

In `flake.nix`, change the three host module paths to:

```nix
            ./hosts/darwin/beckbook-pro/default.nix
```

```nix
            ./hosts/darwin/mac-h99xrph3j9/default.nix
```

```nix
            ./hosts/linux/sweetums/default.nix
```

Expected: no remaining `./machines/` references in `flake.nix`.

- [ ] **Step 4: Update Darwin host imports**

In `hosts/darwin/beckbook-pro/default.nix`, replace the import list with:

```nix
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/darwin/defaults.nix
    ../../../modules/darwin/homebrew.nix
    ../../../modules/darwin/services.nix
    ../../../modules/darwin/home-manager.nix
    ../../../modules/darwin/emacs-macport.nix
  ];
```

In the same file, change the LLM import to:

```nix
      ../../../modules/programs/llms
```

In `hosts/darwin/mac-h99xrph3j9/default.nix`, replace the import list with:

```nix
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/darwin/defaults.nix
    ../../../modules/darwin/homebrew.nix
    ../../../modules/darwin/services.nix
    ../../../modules/darwin/home-manager.nix
    ../../../modules/darwin/emacs-macport.nix
  ];
```

Expected: no `../../modules/` references remain in `hosts/darwin`.

- [ ] **Step 5: Update temporary Linux host import**

In `hosts/linux/sweetums/default.nix`, replace the import with:

```nix
  imports = [
    ../../../modules/home/headless.nix
  ];
```

Expected: `sweetums` still imports the temporary headless module until Task 2 removes it.

- [ ] **Step 6: Update moved Darwin Home Manager imports**

In `modules/darwin/home-manager.nix`, replace the `home-manager.users.${username}.imports` block with:

```nix
      imports = [
        ../shared/identity.nix
        ../programs/gpg.nix
        ../programs/git.nix
        ../programs/tmux.nix
      ];
```

Expected: `modules/darwin/home-manager.nix` imports from `../shared` and `../programs`.

- [ ] **Step 7: Update temporary headless module imports**

In `modules/home/headless.nix`, replace the import list with:

```nix
  imports = [
    ../shared/machine.nix
    ../linux/nix.nix
    ../shared/identity.nix
    ../programs/gpg.nix
    ../programs/git.nix
    ../programs/tmux.nix
  ];
```

Expected: the temporary module evaluates after the move.

- [ ] **Step 8: Verify references after the move**

Run:

```bash
rg -n "machines/|modules/machine\\.nix|modules/identity\\.nix|modules/git\\.nix|modules/gpg\\.nix|modules/tmux\\.nix|modules/llms|modules/home/nix\\.nix|modules/home-manager\\.nix|modules/emacs-macport\\.nix" flake.nix hosts modules
```

Expected: no output except references inside paths intentionally kept for `modules/home/headless.nix`.

- [ ] **Step 9: Run evaluation checks**

Run:

```bash
nix eval --show-trace .#homeConfigurations.sweetums.activationPackage.drvPath
nix flake check --no-build --all-systems --show-trace
```

Expected: both commands exit with status 0.

- [ ] **Step 10: Commit the move-only pass**

```bash
git add flake.nix hosts modules
git commit -m "flake: group hosts and modules by evaluation type"
```

Expected: commit succeeds.

## Task 2: Make Sweetums A Top-Heavy Pure Home Manager Host

**Files:**
- Create: `modules/programs/fish.nix`
- Modify: `hosts/linux/sweetums/default.nix`
- Delete: `modules/home/headless.nix`

- [ ] **Step 1: Create the shared Fish module**

Create `modules/programs/fish.nix` with exactly:

```nix
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # nix-config wrapper: run just recipes from anywhere
      function nx --description "Run nix-config recipes via just"
        set -l justfile ~/.config/nix-config/Justfile
        set -l workdir ~/.config/nix-config

        if test (count $argv) -eq 0
          just --justfile $justfile --working-directory $workdir --list
        else
          just --justfile $justfile --working-directory $workdir $argv
        end
      end

      # nx tab completions (dynamic from Justfile recipes)
      complete -c nx -f -a "(just --justfile ~/.config/nix-config/Justfile --summary | string split ' ')"

      # Local machine overrides
      if test -f ~/.localrc.fish
        source ~/.localrc.fish
      end
    '';
  };
}
```

Expected: Fish wrapper logic now has one reusable Home Manager module.

- [ ] **Step 2: Replace the Sweetums host with explicit Home Manager config**

Replace `hosts/linux/sweetums/default.nix` with exactly:

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
    ../../../modules/programs/gpg.nix
    ../../../modules/programs/git.nix
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
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  programs.home-manager.enable = true;
  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.load_dotenv = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--no-heading"
      "--no-line-number"
      "--context=0"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Solarized (dark)";
      style = "plain";
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    theme.punctuation.foreground = "Default";
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
```

Expected: `sweetums` no longer imports `modules/home/headless.nix`.

- [ ] **Step 3: Delete the temporary headless module and empty directory**

```bash
git rm modules/home/headless.nix
rmdir modules/home
```

Expected: `modules/home` no longer exists.

- [ ] **Step 4: Verify Sweetums evaluation**

Run:

```bash
nix eval --show-trace .#homeConfigurations.sweetums.activationPackage.drvPath
nix eval --show-trace --json .#homeConfigurations.sweetums.config.programs.fish.enable
nix eval --show-trace --json .#homeConfigurations.sweetums.config.programs.git.lfs.enable
```

Expected:

```text
first command prints a /nix/store/...home-manager-generation.drv path
second command prints true
third command prints false
```

- [ ] **Step 5: Commit the Linux host cleanup**

```bash
git add hosts/linux/sweetums/default.nix modules/programs/fish.nix
git commit -m "linux: make sweetums a pure home-manager host"
```

Expected: commit succeeds.

## Task 3: Use The Shared Fish Module On Darwin

**Files:**
- Modify: `modules/darwin/home-manager.nix`

- [ ] **Step 1: Add the shared Fish module to Darwin Home Manager imports**

In `modules/darwin/home-manager.nix`, replace the imports block with:

```nix
      imports = [
        ../shared/identity.nix
        ../programs/fish.nix
        ../programs/gpg.nix
        ../programs/git.nix
        ../programs/tmux.nix
      ];
```

Expected: Darwin Home Manager users get the shared `nx` wrapper from `modules/programs/fish.nix`.

- [ ] **Step 2: Narrow the Darwin Fish block to Darwin-only behavior**

In `modules/darwin/home-manager.nix`, replace the full `programs.fish` block with:

```nix
      programs.fish.interactiveShellInit = ''
        # Toggle solarized light/dark via ghostty config override
        function toggle-solarized --description "Toggle Ghostty between Solarized Dark/Light"
          set -l override_file ~/.config/ghostty/theme-override.ghostty
          if test -f $override_file
            rm $override_file
            echo "Solarized Dark activated, press  cmd + shift + ,  to activate."
          else
            echo 'theme = "iTerm2 Solarized Light"' > $override_file
            echo "Solarized Light activated, press  cmd + shift + ,  to activate."
          end
        end
      '';
```

Expected: common Fish setup lives in `modules/programs/fish.nix`; Darwin-only Ghostty toggling remains Darwin-scoped.

- [ ] **Step 3: Verify Darwin Home Manager config still includes both Fish init blocks**

Run:

```bash
nix eval --show-trace --raw \
  .#darwinConfigurations.beckbook-pro.config.home-manager.users.chris.programs.fish.interactiveShellInit \
  --override-input nix-config-private path:/Users/chris/.config/nix-config-private
```

Expected output includes both strings:

```text
function nx --description "Run nix-config recipes via just"
function toggle-solarized --description "Toggle Ghostty between Solarized Dark/Light"
```

- [ ] **Step 4: Commit the Fish extraction**

```bash
git add modules/darwin/home-manager.nix modules/programs/fish.nix
git commit -m "home-manager: share fish wrapper setup"
```

Expected: commit succeeds.

## Task 4: Update Repository Documentation

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-06-27-eval-type-host-structure-design.md` if implementation changes the agreed names

- [ ] **Step 1: Update the Repository Layout section in `AGENTS.md`**

Replace the layout bullets for old paths with:

```markdown
- `flake.nix`: flake inputs, overlays, formatter, and host outputs
- `Justfile`: primary operator workflow
- `local.just`: local overrides loaded by `mod local`
- `hosts/darwin/<hostname>/default.nix`: nix-darwin host-specific configuration entry points
- `hosts/linux/<hostname>/default.nix`: pure Home Manager host-specific configuration entry points for non-NixOS Linux
- `modules/shared/machine.nix`: shared options for `machine.username` and `machine.home`
- `modules/shared/identity.nix`: shared identity options consumed by Git and GPG modules
- `modules/darwin/defaults.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/services.nix`, `modules/darwin/home-manager.nix`, `modules/darwin/emacs-macport.nix`: Darwin-only modules
- `modules/linux/nix.nix`: Linux Home Manager Nix client settings
- `modules/programs/git.nix`, `modules/programs/gpg.nix`, `modules/programs/tmux.nix`, `modules/programs/fish.nix`: reusable Home Manager program modules
- `modules/programs/llms/default.nix`, `modules/programs/llms/pi.nix`, `modules/programs/llms/omp.nix`: shared LLM CLI package setup
- `modules/programs/llms/crush.nix`: Crush (Charmbracelet) Home Manager module via NUR, imported only on `beckbook-pro`
- `scripts/audit-flake-inputs.sh`: flake input audit helper
- `etc/patches/tea-custom-headers.patch`: patch used by the custom `tea` overlay
- `etc/doc/`: documentation assets
```

Expected: old `machines/*`, `modules/home-manager.nix`, `modules/machine.nix`, and `modules/llms/*` layout bullets are gone.

- [ ] **Step 2: Update architecture and host-specific wording in `AGENTS.md`**

Make these exact wording changes:

```markdown
Keep new config split by evaluation type and concern. Darwin system behavior belongs in `modules/darwin/*.nix`, non-NixOS Linux Home Manager support belongs in `modules/linux/*.nix`, reusable Home Manager program modules belong in `modules/programs/*.nix`, shared options belong in `modules/shared/*.nix`, and host-specific choices belong in `hosts/<eval-type>/<hostname>/default.nix`.
```

```markdown
- `modules/darwin/home-manager.nix` owns the Darwin Home Manager integration and imports shared Home Manager program modules.
```

```markdown
- `sweetums`: pure Home Manager Linux host under `hosts/linux/sweetums`.
```

```markdown
- `modules/shared/machine.nix` defines darwin/Home Manager options for `machine.username` and `machine.home`.
```

Expected: `AGENTS.md` describes the new structure and the pure Home Manager Linux host.

- [ ] **Step 3: Update design spec if implementation names changed**

Run:

```bash
rg -n "machines/|modules/home/|modules/home-manager\\.nix|modules/machine\\.nix|modules/identity\\.nix|modules/llms" docs/superpowers/specs/2026-06-27-eval-type-host-structure-design.md
```

Expected: output only appears in the "Current Problem" or "Migration Notes" sections. If output appears in final-design sections, update those lines to match the implemented paths.

- [ ] **Step 4: Commit documentation updates**

```bash
git add AGENTS.md docs/superpowers/specs/2026-06-27-eval-type-host-structure-design.md
git commit -m "docs: update repo structure guide"
```

Expected: commit succeeds.

## Task 5: Final Validation

**Files:**
- No planned file edits.

- [ ] **Step 1: Check formatting and whitespace**

Run:

```bash
git diff --check trunk
just fmt
git diff --check trunk
```

Expected: both `git diff --check` commands exit with status 0. `just fmt` exits with status 0.

- [ ] **Step 2: Run flake evaluation checks**

Run:

```bash
nix eval --show-trace .#homeConfigurations.sweetums.activationPackage.drvPath
nix flake check --no-build --all-systems --show-trace
```

Expected: both commands exit with status 0.

- [ ] **Step 3: Run Darwin evaluation with the local private input**

Run:

```bash
nix eval --show-trace \
  .#darwinConfigurations.beckbook-pro.config.home-manager.users.chris.programs.git.lfs.enable \
  --override-input nix-config-private path:/Users/chris/.config/nix-config-private
```

Expected:

```text
true
```

- [ ] **Step 4: Check stale path references**

Run:

```bash
rg -n "machines/|modules/home/headless\\.nix|modules/home/nix\\.nix|modules/home-manager\\.nix|modules/machine\\.nix|modules/identity\\.nix|modules/git\\.nix|modules/gpg\\.nix|modules/tmux\\.nix|modules/llms" .
```

Expected: any output is limited to historical design/migration notes under `docs/superpowers`. Source files and `AGENTS.md` do not contain stale live paths.

- [ ] **Step 5: Review final diff**

Run:

```bash
git status --short
git diff --stat trunk
git diff --find-renames trunk -- flake.nix hosts modules AGENTS.md docs
```

Expected: diff shows path moves, import updates, Sweetums inlined as a pure Home Manager host, a shared Fish module, and documentation updates.

- [ ] **Step 6: Commit final formatting changes if `just fmt` changed files**

If `git status --short` shows formatting-only changes after Task 5 Step 1, run:

```bash
git add flake.nix hosts modules AGENTS.md docs
git commit -m "style: format eval-type host structure"
```

Expected: commit succeeds only when there are formatting changes.
