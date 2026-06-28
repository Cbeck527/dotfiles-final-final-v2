{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.custom.git.githubCredentialHelper.enable = lib.mkOption {
    type = lib.types.bool;
    default = pkgs.stdenv.isDarwin;
    description = "Use GitHub CLI as the Git credential helper for GitHub remotes.";
  };

  options.custom.git.extras.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable additional Git-adjacent tools like Git LFS, Jujutsu, and Delta.";
  };

  config = {
    programs.git = {
      enable = true;

      settings = {
        user.name = config.identity.name;
        user.email = config.identity.email;

        advice = {
          detachedHead = false;
        };

        core = {
          editor = "emacsclient";
          untrackedCache = true;
          preloadindex = true;
          fscache = true;
        };

        init = {
          defaultBranch = "main";
        };

        pull = {
          rebase = true;
        };

        push = {
          default = "simple";
        };

        fetch = {
          prune = true;
        };

        rebase = {
          autostash = true;
        };

        merge = {
          conflictstyle = "diff3";
        };

        diff = {
          colorMoved = "default";
        };

        alias = {
          up = "pull --rebase --autostash";
          rm-merged = "!git branch --format '%(refname:short) %(upstream:track)' | awk '$2 == \"[gone]\" { print $1 }' | xargs -r git branch -D";

          # Log & History
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          lgo = "log --graph --oneline --decorate --all";
          last = "log -1 HEAD --stat";
          history = "log -p --follow";

          # Branching
          br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
          co = "checkout";
          cob = "checkout -b";
          main = "!git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' | xargs git checkout";

          # Staging & Commits
          aa = "add --all";
          cm = "commit -m";
          amend = "commit --amend --no-edit";
          undo = "reset HEAD~1 --mixed";

          # Productivity
          wip = "!git add -A && git commit -m \"WIP: $(date '+%Y-%m-%d %H:%M:%S')\"";
          unwip = "!git log -1 --oneline | grep -q 'WIP:' && git reset HEAD~1 --mixed || echo 'Previous commit is not a WIP'";
          aliases = "config --get-regexp alias";
          contributors = "shortlog --summary --numbered";
        };

        github = {
          user = config.identity.githubUser;
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        credential = {
          helper = "osxkeychain";
        };
      }
      // lib.optionalAttrs config.custom.git.githubCredentialHelper.enable {
        # The empty string in the helper list resets inherited helpers (e.g. the
        # global osxkeychain above), so only `gh auth git-credential` is used for GitHub.
        "credential \"https://github.com\"" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };

        "credential \"https://gist.github.com\"" = {
          helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };

      signing = {
        key = config.identity.gpgKey;
        format = "openpgp";
        signByDefault = true;
      };

      lfs.enable = config.custom.git.extras.enable;

      ignores = [
        # Editor (Emacs)
        "TODOs.org"
        ".projectile"
        ".dir-locals.el"
        ".projectile-cache*"
        "*.elc"

        # Misc
        ".ignore"
        ".envrc"
        ".direnv/"
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        # macOS
        ".DS_Store"
        ".AppleDouble"
        ".LSOverride"
        "Icon"
        "._*"
        ".DocumentRevisions-V100"
        ".fseventsd"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".Trashes"
        ".VolumeIcon.icns"
        ".com.apple.timemachine.donotpresent"
        ".AppleDB"
        ".AppleDesktop"
        "Network Trash Folder"
        "Temporary Items"
        ".apdisk"
      ];

      # Use includes for local overrides
      includes = [
        {
          path = "~/.gitconfig.local";
        }
      ];

    };

    programs.jujutsu = lib.mkIf config.custom.git.extras.enable {
      enable = true;

      settings = {
        user = {
          name = config.identity.name;
          email = config.identity.email;
        };

        ui = {
          editor = "emacsclient";
        };

        signing = {
          behavior = "own";
          backend = "gpg";
          key = config.identity.gpgKey;
        };

        git = {
          private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
        };
      };
    };

    programs.delta = lib.mkIf config.custom.git.extras.enable {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
      options = {
        navigate = true;
        syntax-theme = "Solarized (dark)";
        features = "pretty";

        pretty = {
          line-numbers = true;
          map-styles = "bold purple => syntax #2e1533, bold cyan => syntax #1d473f";
          commit-style = "raw";
          file-style = "white auto";
          file-decoration-style = "black bold ul";
          file-modified-label = "changed: ";
          hunk-header-style = "raw";
          hunk-header-decoration-style = "";
          line-numbers-left-style = "black bold";
          line-numbers-right-style = "black bold";
          line-numbers-zero-style = "#869496";
        };

        magit = {
          line-numbers = false;
          keep-plus-minus-markers = true;
        };
      };
    };
  };
}
