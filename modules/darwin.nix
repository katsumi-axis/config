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
    git
    ripgrep
    fd
    jq
    vim
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
    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
