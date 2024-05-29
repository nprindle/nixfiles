{ pkgs, self, lib, config, ... }:

let
  homebrewPrefix = lib.strings.removeSuffix "/bin" (builtins.toString config.homebrew.brewPrefix);
in
{
  imports = [
    ./nix.nix
  ];

  networking = {
    computerName = "caspar";
    hostName = "caspar.local";
    localHostName = "caspar";
  };

  system = {
    keyboard = {
      enableKeyMapping = true;
      userKeyMapping =
        let
          escapeKey = 30064771113;
          capsLockKey = 30064771129;
          remap = from: to: { HIDKeyboardModifierMappingSrc = from; HIDKeyboardModifierMappingDst = to; };
        in
        [
          (remap escapeKey capsLockKey)
          (remap capsLockKey escapeKey)
        ];
    };

    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
        show-process-indicators = true;
        showhidden = true;
        mru-spaces = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        ShowStatusBar = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
      };
    };
  };

  environment = {
    loginShell = "${config.environment.variables.SHELL} --login";

    variables = {
      LC_CTYPE = "en_US.UTF-8";
      EDITOR = "nvim";
      SHELL = "${pkgs.fish}/bin/fish";

      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_PREFIX = homebrewPrefix;
      HOMEBREW_CELLAR = "${homebrewPrefix}/Cellar";
      HOMEBREW_REPOSITORY = homebrewPrefix;
    };

    systemPackages = [
      # nix stuff
      pkgs.nix-index
      pkgs.nix-tree
      pkgs.nix-diff

      # CLI/TUI utils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.gawk
      pkgs.coreutils
      pkgs.diffutils
      pkgs.findutils
      pkgs.patch
      pkgs.netcat
      pkgs.socat
      pkgs.nmap
      pkgs.bc
      pkgs.wget
      pkgs.curl
      pkgs.grpcurl
      pkgs.httpie
      pkgs.moreutils
      (lib.hiPrio (pkgs.parallel-full.override {
        willCite = true;
      })) # conflicts with 'parallel' from moreutils
      pkgs.tree
      pkgs.ripgrep
      pkgs.eza
      pkgs.bat
      pkgs.fzf
      pkgs.fd
      pkgs.rsync
      pkgs.gitAndTools.gitFull
      pkgs.hyperfine
      pkgs.tldr
      pkgs.cht-sh
      pkgs.watch
      pkgs.entr
      ## build systems/task runners/etc.
      pkgs.gnumake
      pkgs.autoconf
      pkgs.automake
      pkgs.cmake
      pkgs.bazelisk
      (pkgs.runCommandNoCCLocal "bazel-bazelisk-alias" { } ''
        mkdir -p "$out/bin"
        ln -s "${pkgs.bazelisk}/bin/bazelisk" "$out/bin/bazel"
      '')
      pkgs.buildozer
      pkgs.just
      ## cryptography and pki
      pkgs.gnupg
      pkgs.openssl
      pkgs.certstrap
      pkgs.certigo
      ## archival/compression
      pkgs.gnutar
      pkgs.gzip
      pkgs.xz
      pkgs.lz4
      pkgs.zstd
      pkgs.unar
      ## data and manipulation
      pkgs.jo
      pkgs.yq-go
      pkgs.crudini
      pkgs.sqlite
      ## TUI stuff
      pkgs.tz
      ## Docker/Kubernetes
      pkgs.dive
      pkgs.kubectl
      pkgs.k9s
      pkgs.kubernetes-helm
      self.packages.${pkgs.system}.envtpl
      pkgs.gomplate
      ## AWS
      pkgs.awscli2
      pkgs.aws-iam-authenticator
      (pkgs.ssm-session-manager-plugin.overrideAttrs {
        doCheck = false;
      })
      ## programming language support
      pkgs.pkg-config
      pkgs.delve
      pkgs.python3
      pkgs.pipx
      pkgs.rustup
      self.packages.${pkgs.system}.frum
      pkgs.shellcheck

      # media tools
      pkgs.ffmpeg
      pkgs.exiftool
      pkgs.imagemagick
      pkgs.pandoc
      pkgs.qpdf

      # macos stuff
      pkgs.pinentry_mac
    ];
  };

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraMono" "FiraCode" ]; })
    ];
  };

  programs = {
    bash.enable = true;
    fish.enable = true;
    gnupg.agent.enable = true;
  };

  services = {
    ollama = {
      enable = true;
      logFile = "/var/tmp/ollama.log";
    };
    pueue = {
      enable = true;
      logFile = "/var/tmp/pueued.log";
    };
  };

  homebrew = {
    enable = true;

    brews = [
      "awscurl"
    ];

    casks = [
      "amethyst"
      "kitty"
      "plover"
      "talon"
      "gimp"
    ];
  };

  users.users.wrenn = {
    home = "/Users/wrenn";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.wrenn = {
      imports = [
        self.hmModules.mixins.bash
        self.hmModules.mixins.btop
        self.hmModules.mixins.catppuccin
        self.hmModules.mixins.direnv
        self.hmModules.mixins.fish
        self.hmModules.mixins.gh
        self.hmModules.mixins.h
        self.hmModules.mixins.jq
        self.hmModules.mixins.jujutsu
        self.hmModules.mixins.zoxide
      ];

      home = {
        stateVersion = "22.11";

        sessionVariables = {
          TFENV_ARCH = "arm64";
        };

        packages = lib.flatten [
          (builtins.attrValues (import ./scripts.nix { inherit pkgs lib; }))
          self.packages.${pkgs.system}.jj-helpers
        ];

        shellAliases = lib.mergeAttrsList [
          {
            cat = "bat";
            ls = "eza --git";
            vi = "nvim";
            vim = "nvim";
          }
          (builtins.listToAttrs
            (builtins.map
              (n: {
                name = ".${toString n}";
                value = "cd ${builtins.concatStringsSep "/" (builtins.genList (_: "..") n)}";
              })
              (lib.lists.range 1 9)))
        ];
      };

      # extra fish init on top of fish mixin
      programs.fish = {
        loginShellInit = ''
          fish_add_path --move --prepend --path \
              "/usr/local/bin" \
              "/usr/local/sbin" \
              "/opt/local/bin"

          # set up extra homebrew variables
          if command --search ${homebrewPrefix}/bin/brew >/dev/null 2>&1
              # Used for C pre-processor/#include. Confirm paths with `clang -x c -v -E /dev/null`
              not set -q CPATH; and set CPATH ""
              set --global --export CPATH ${homebrewPrefix}/include:"$CPATH"

              # Used by linker. Confirm paths with `clang -Xlinker -v`
              not set -q LIBRARY_PATH; and set LIBRARY_PATH ""
              set --global --export LIBRARY_PATH ${homebrewPrefix}/lib:"$LIBRARY_PATH"

              not set -q MANPATH; and set MANPATH ""
              set --global --export MANPATH ${homebrewPrefix}/share/man:"$MANPATH"

              not set -q INFOPATH; and set INFOPATH ""
              set --global --export INFOPATH ${homebrewPrefix}/share/info:"$INFOPATH"

              fish_add_path --move --prepend --path \
                  "${homebrewPrefix}/bin" \
                  "${homebrewPrefix}/sbin"
          end

          # give NixOS paths priority over brew and system paths
          fish_add_path --move --prepend --path ${
            lib.strings.concatMapStringsSep " " (p: builtins.toJSON "${p}/bin")
              config.environment.profiles
          }

          fish_add_path --move --prepend --path \
              "$HOME/bin" \
              "$HOME/.local/bin" \
              "$HOME/Development/go/bin" \
              "$HOME/.docker/bin" \
              "$HOME/.krew/bin"

          set fish_user_paths $fish_user_paths
        '';

        interactiveShellInit = ''
          "${self.packages.${pkgs.system}.frum}/bin/frum" init | source
        '';
      };

      programs.h = {
        codeRoot = "$HOME/Development/code";
      };

      programs.go = {
        enable = true;
        package = pkgs.go_1_22;
        goPath = "Development/go";
      };

      programs.kitty = {
        enable = true;
        extraConfig = builtins.readFile ./kitty.conf;
        shellIntegration.mode = "enabled";
      };

      programs.git = {
        enable = true;
        userName = "Nicole Wren";
        userEmail = "wrenn@squareup.com";
        signing = {
          signByDefault = true;
          key = "DCC3076C9F46DFD330C3DFFDA4B4CC3C080B1C66";
        };
        aliases = {
          s = "status";
          cane = "commit --amend --no-edit";
          amend = "commit --amend";
          diffc = "diff --cached";
          conflicts = "diff --name-status --diff-filter=U";
          ff = "merge --ff-only";
          rh = "reset --hard";
          ri = "rebase --interactive";
          ls = "log --oneline";
          lr = "log --left-right --graph --oneline";
          graph = "log --graph --abbrev-commit --date=relative --pretty=format:'%C(bold blue)%h - %C(reset)%C(green)(%ar)%C(reset) - %s %C(dim)- %an%C(reset)%C(yellow)%d'";
          changed = "show --name-status --oneline";
          mkexec = "update-index --chmod=+x";
          root = "rev-parse --show-toplevel";
          ignored = ''! f(){ find "$(realpath --relative-to=. "$(git rev-parse --show-toplevel)")" -type f -exec git check-ignore -v {} + | awk '{if ($1 !~ /^\//) print $2}' ; }; f'';
          tag-sort = "tag --sort=v:refname";

          alias = ''! f(){ git config --get-regexp ^alias | cut -c 7- | sed -e "s/ \(.*\)/ = \1/"; }; f'';
          ignore = ''! f(){ curl -sL https://www.toptal.com/developers/gitignore/api/$@ ; }; f'';
        };
        extraConfig = {
          credential.helper = "osxkeychain";
          gist.private = true;
          color = {
            diff = "auto";
            status = "auto";
            branch = "auto";
            interactive = "auto";
          };
          log.mailmap = true;
          init.defaultBranch = "main";
          branch.autosetupmerge = true;
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
          rerere.enabled = 1;
          pull.ff = "only";
          push.default = "simple";
          diff = {
            renames = true;
            indentHeuristic = "on";
          };
          rebase = {
            autosquash = true;
            autostash = true;
          };
          merge = {
            summary = true;
            conflictstyle = "diff3";
          };
          mergetool = {
            prompt = false;
            keepBackup = false;
          };
        };
        ignores = [
          "*.iml"
          "*.swp"
          "*.swo"
          ".bundle"
          ".DS_Store"
          ".idea"
          ".rbx"
          "node_modules"
          "/tags"
          ".jj"
        ];
      };

      programs.jujutsu.settings = {
        user.email = "wrenn@squareup.com";
        signing = {
          sign-all = true;
          backend = "gpg";
          key = "DCC3076C9F46DFD330C3DFFDA4B4CC3C080B1C66";
        };
      };
    };
  };
}
