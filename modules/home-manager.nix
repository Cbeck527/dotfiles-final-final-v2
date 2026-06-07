{
  pkgs,
  lib,
  inputs,
  username,
  userHome,
  ...
}:

{
  # Common user configuration shared across all machines
  users.users.${username} = {
    home = userHome;
    description = username;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.${username} = {
      imports = [
        ./identity.nix
        ./gpg.nix
        ./git.nix
        ./tmux.nix
        ./llms
      ];

      home.stateVersion = "25.05";

      targets.darwin.copyApps = {
        enable = true;
        directory = "Applications/HomeManager";
      };
      targets.darwin.linkApps.enable = false;

      programs.home-manager.enable = true;

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

          # Local machine overrides
          if test -f ~/.localrc.fish
            source ~/.localrc.fish
          end
        '';
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global = {
            load_dotenv = true;
          };
        };
      };

      programs.atuin = {
        enable = true;
        enableFishIntegration = true;
        flags = [
          "--disable-up-arrow"
        ];
        daemon = {
          enable = true;
        };
        settings = {
          dialect = "us";
          style = "compact";
          filter_mode = "host";
          enter_accept = false;
          secrets_filter = false;
          show_help = false;
          update_check = false;
          show_preview = false;
          show_tabs = false;
        };
      };

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
        settings = {
          font-size = 17;
          font-family = "TX-02";
          font-style = "Regular";
          font-style-bold = "Bold";
          font-thicken = true;

          theme = "iTerm2 Solarized Dark";
          cursor-style = "block";
          cursor-style-blink = false;

          window-theme = "system";
          window-padding-balance = true;
          window-padding-x = 6;
          window-padding-y = 1;

          clipboard-read = "allow";
          clipboard-write = "allow";

          shell-integration = "fish";
          shell-integration-features = "no-cursor";

          macos-titlebar-style = "native";
          macos-titlebar-proxy-icon = "hidden";
          macos-dock-drop-behavior = "new-window";

          keybind = "global:cmd+control+t=toggle_quick_terminal";

          auto-update = "off";
          config-file = "?theme-override.ghostty";
        };
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
        enableFishIntegration = false;
        theme = {
          punctuation = {
            foreground = "Default";
          };
        };
      };

      programs.uv = {
        enable = true;
        settings = {
          preview = true;
        };
      };

      programs.k9s = {
        enable = true;
        aliases = {
          dp = "deployments";
          sec = "v1/secrets";
          jo = "jobs";
          cr = "clusterroles";
          crb = "clusterrolebindings";
          ro = "roles";
          rb = "rolebindings";
          np = "networkpolicies";
        };

        settings = {
          k9s = {
            liveViewAutoRefresh = true;
            screenDumpDir = "${userHome}/Downloads/k9s-screen-dumps";
            refreshRate = 2;
            maxConnRetry = 5;
            readOnly = false;
            noExitOnCtrlC = false;
            skipLatestRevCheck = false;
            disablePodCounting = false;
            ui = {
              enableMouse = false;
              logoless = true;
              reactive = true;
            };
            shellPod = {
              image = "debian:bookworm-slim";
              namespace = "default";
              limits = {
                cpu = "100m";
                memory = "256Mi";
              };
            };
            imageScans = {
              enable = false;
              exclusions = {
                namespaces = [ ];
                labels = { };
              };
            };
            logger = {
              tail = 100;
              buffer = 5000;
              sinceSeconds = -1;
              textWrap = false;
              showTime = false;
            };
            thresholds = {
              cpu = {
                critical = 90;
                warn = 70;
              };
              memory = {
                critical = 90;
                warn = 70;
              };
            };
          };
        };

        plugins = {
          debug_container = {
            shortCut = "Shift-D";
            description = "Add debug container";
            dangerous = true;
            scopes = [ "containers" ];
            command = "sh";
            background = false;
            confirm = true;
            args = [
              "-c"
              "kubectl --kubeconfig=$KUBECONFIG debug -it -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.13 --share-processes -- bash"
            ];
          };
          node-root-shell = {
            shortCut = "Shift-S";
            description = "Run root shell on node";
            dangerous = true;
            scopes = [ "nodes" ];
            command = "bash";
            background = false;
            confirm = true;
            args = [
              "-c"
              ''
                host="$1"
                json='
                {
                  "apiVersion": "v1",
                  "spec": {
                    "hostIPC": true,
                    "hostNetwork": true,
                    "hostPID": true
                '
                if ! [[ -z "$host" ]]; then
                  json+=",
                  \"nodeSelector\" : {
                    \"kubernetes.io/hostname\" : \"$host\"
                  }
                  ";
                fi
                json+='
                  }
                }
                '
                kubectl run -ti --image ubuntu:latest --rm --privileged --restart=Never --overrides="$json" root --command -- nsenter -t 1 -m -u -n -i -- bash -l
              ''
            ];
          };
          eks-node-viewer = {
            shortCut = "Shift-X";
            description = "eks-node-viewer";
            scopes = [ "node" ];
            background = false;
            command = "sh";
            args = [
              "-c"
              "eks-node-viewer --kubeconfig $KUBECONFIG --resources cpu,memory --extra-labels karpenter.sh/nodepool,eks-node-viewer/node-age --node-sort=creation=dsc"
            ];
          };
        };

      };

      programs.obsidian = {
        enable = true;
        cli.enable = true;
      };

      home.packages = with pkgs; [
        obsidian

        # Shell & Terminal
        aspell
        btop
        cowsay
        fastfetch
        fortune
        fzf
        htop
        macmon
        pstree
        tree
        watch
        zoxide

        # Core Utilities
        curl
        findutils
        gawk
        gnumake
        gnused
        less
        parallel
        rsync
        wget

        # Search & Text Processing
        dasel
        fd
        jq
        shellcheck
        yq

        # Development Tools
        automake
        chezmoi
        clang-tools
        cmake
        dprint
        git-lfs
        gh
        go
        hexyl
        just
        lua-language-server
        tea
        nixfmt
        nodejs
        pnpm
        stylua
        vim

        # Better Rust w/ nix-community fenix
        cargo-deny
        cargo-expand
        cargo-fuzz
        (pkgs.fenix.stable.withComponents [
          "cargo"
          "clippy"
          "rust-analyzer"
          "rust-src"
          "rustc"
          "rustfmt"
        ])

        # Cloud & Infrastructure
        awscli
        colima
        ctop
        docker
        docker-buildx
        kubectl
        kubernetes-helm

        # Languages / LSP
        astro-language-server
        awk-language-server
        basedpyright
        bash-language-server
        buf # protobufs
        dockerfile-language-server
        fish-lsp
        go-grip
        golangci-lint
        gopls
        nil # nix lsp
        terraform-ls
        typescript
        typescript-language-server
        vscode-langservers-extracted
        yaml-language-server

        # Network Tools
        netcat
        nmap
        socat
        websocat

        # Other
        typst
        zstd
      ];
    };
  };
}
