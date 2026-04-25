{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.sessionPath = [
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "$HOME/Library/pnpm"
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
    tree
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    ignores = [
      "# macOS"
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"
      ".Spotlight-V100"
      ".Trashes"

      "# Windows"
      "Thumbs.db"
      "ehthumbs.db"

      "# Editor backup and swap files"
      "*~"
      "*.swp"
      "*.swo"

      "# Local development environment"
      ".envrc"
    ];
    settings = {
      core.excludesFile = "~/.config/git/ignore";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      ls = "ls -GF";
      gls = "gls --color";
      la = "ls -la";

      rm = "rm -i";
      pull = "git pull";
      push = "git push";
      st = "git status";
      stt = "git status -uno";
      g = "git";
      gi = "git init";
      gd = "git diff";
      gst = "git status -b";
      gb = "git branch";
      gbd = "git branch -d";
      gco = "git checkout";
      gcob = "git checkout -b";
      gcm = "git checkout master";
      glg = "git log --graph --name-status";
      gsta = "git stash";
      gstal = "git stash list";
      rgsta = "git stash apply";
      gr = "git reset HEAD";
      grhch = "git reset --hard HEAD^";
      grhih = "git reset --hard HEAD";
      grsch = "git reset --soft HEAD^";
      ga = "git add";
      gaa = "git add .";
      gc = "git commit";
      gcmsg = "git commit -m";
      gcam = "git commit --amend";
      gl = "git pull origin B";
      gp = "git push origin B";
      gpom = "git push origin master";
      glom = "git pull origin master";
      gce = "git commit --allow-empty -m \"make pull request\"";

      fig = "docker-compose";
      dbtf = "${config.home.homeDirectory}/.local/bin/dbt";
    };

    initContent = ''
      export LANG=ja_JP.UTF-8

      autoload -Uz colors
      colors

      HISTFILE=~/.zsh_history
      HISTSIZE=1000000
      SAVEHIST=1000000

      setopt nonomatch

      autoload -U compinit
      compinit -u

      export LSCOLORS=exfxcxdxbxegedabagacad
      export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

      RPROMPT="%{''${reset_color}%}"

      autoload -Uz vcs_info
      setopt prompt_subst
      setopt histignorealldups
      setopt correct
      zstyle ':vcs_info:git:*' check-for-changes true
      zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
      zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
      zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
      zstyle ':vcs_info:*' actionformats '[%b|%a]'
      nix_info() {
        if [[ -n "$IN_NIX_SHELL" ]]; then
          nix_info_msg="%F{cyan}[nix]%f"
        else
          nix_info_msg=""
        fi
      }
      precmd () {
        vcs_info
        nix_info
      }
      RPROMPT="$RPROMPT\''${nix_info_msg}\''${vcs_info_msg_0_}"
      PROMPT="%{''${fg[green]}%}%* %c ]%{''${reset_color}%} "

      chpwd() { ls -GF }

      bindkey -v

      setopt auto_cd
      setopt auto_menu
      setopt auto_param_keys
      setopt auto_param_slash
      setopt auto_pushd
      setopt extended_glob
      setopt hist_ignore_all_dups
      setopt hist_ignore_space
      setopt hist_reduce_blanks
      setopt ignore_eof
      setopt interactive_comments
      setopt magic_equal_subst
      setopt mark_dirs
      setopt no_beep
      setopt no_flow_control
      setopt prompt_subst
      setopt print_eight_bit
      setopt pushd_ignore_dups
      setopt share_history

      zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

      glog() {
        git log --graph --all --format="%x09%an%x09%h %d %s" "$@"
      }

      gcl() {
        git checkout "$1"
        git branch --merged | egrep -v '\\*|develop|main' | xargs git branch -d
      }

      nix() {
        if [[ "$1" == "develop" && -t 0 ]]; then
          local arg
          for arg in "$@"; do
            if [[ "$arg" == "-c" || "$arg" == "--command" ]]; then
              command nix "$@"
              return
            fi
          done

          command nix "$@" -c "$SHELL"
          return
        fi

        command nix "$@"
      }

      eval "$(/opt/homebrew/bin/brew shellenv)"

      if command -v anyenv >/dev/null 2>&1; then
        eval "$(anyenv init -)"
      fi

      if [[ -f ~/.secrets ]]; then
        source ~/.secrets
      fi

      export GPG_TTY=$(tty)
    '';
  };
}
