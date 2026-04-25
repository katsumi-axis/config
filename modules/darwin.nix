{ pkgs, username, homeDirectory, hostname, ... }:

{
  system.stateVersion = 6;
  system.primaryUser = username;

  nix = {
    enable = true;
    settings.experimental-features = "nix-command flakes";
  };

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;
  networking.computerName = hostname;

  users.users.${username}.home = homeDirectory;

  environment.systemPackages = with pkgs; [
    biome
    fd
    gh
    git
    git-lfs
    gnupg
    jq
    nodejs
    openjdk
    pinentry_mac
    pnpm
    ripgrep
    uv
    vim
    wget
    zsh
    cloudflared
  ];

  programs.zsh.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [
      "android-studio"
      "bitwarden"
      "chatgpt"
      "claude"
      "cursor"
      "docker-desktop"
      "ghostty"
      "karabiner-elements"
      "notion"
      "raycast"
      "unity-hub"
      "visual-studio-code"
      "xcodes-app"
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
