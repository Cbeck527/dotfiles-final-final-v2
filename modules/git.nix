{
  pkgs,
  lib,
  ...
}:

let
  gitEmail = lib.mkDefault "chris@becker.am";
  gitSigningKey = lib.mkDefault "FBC98F20D0EB443EA67B41C170FA7961EA5F66A9";
in
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Chris Becker";
      user.email = gitEmail;

      core = {
        editor = "emacsclient";
        excludesfile = "~/.gitignore";
        ignorecase = true;
        untrackedCache = true;
        preloadindex = true;
        fscache = true;
      };

      init = {
        defaultBranch = "trunk";
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

      credential = {
        helper = "osxkeychain";
      };

      aliases = {
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
        user = "Cbeck527";
      };

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
      key = gitSigningKey;
      format = "openpgp";
      signByDefault = true;
    };

    lfs.enable = true;

    ignores = [
      # Add your global gitignore patterns here if you have any
    ];

    # Use includes for local overrides
    includes = [
      {
        path = "~/.gitconfig.local";
      }
    ];

  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
}
