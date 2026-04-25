{
  pkgs,
  username,
  homeDirectory,
  hostname,
  ...
}:

{
  system.stateVersion = 6;
  system.primaryUser = username;

  nix = {
    enable = true;
    settings.experimental-features = "nix-command flakes";
  };

  launchd.daemons.nix-daemon.serviceConfig.RunAtLoad = true;

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        direnv = prev.direnv.overrideAttrs (_: {
          # direnv's zsh test can hang during local darwin-rebuild source builds.
          doCheck = false;
        });
      })
    ];
  };

  networking.hostName = hostname;
  networking.computerName = hostname;

  users.users.${username}.home = homeDirectory;

  environment.systemPackages = with pkgs; [
    biome
    fd
    bitwarden-desktop
    chatgpt
    gh
    git
    git-lfs
    gnupg
    jq
    nodejs
    openjdk
    pinentry_mac
    ripgrep
    uv
    vim
    vscode
    wget
    xcodes
    zsh
    cloudflared
  ];

  programs.zsh.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
        "/Applications/Cursor.app"
        "/Applications/Codex.app"
      ];
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    CustomUserPreferences = {
      "com.apple.AppleMultitouchMouse" = {
        MouseButtonMode = "TwoButton";
      };
      "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
        MouseButtonMode = "TwoButton";
      };
    };
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [
      "android-studio"
      "claude"
      "cursor"
      "docker-desktop"
      "ghostty"
      "notion"
      "unity-hub"
      "raycast"
      "codex"
      "karabiner-elements"
    ];
    masApps = {
      DevCleaner = 1388020431;
      Keynote = 409183694;
      Kindle = 302584613;
      Magnet = 441258766;
      Numbers = 409203825;
      Pages = 409201541;
      Slack = 803453959;
    };
  };
}
