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

  users.users.${username} = {
    home = homeDirectory;
    shell = "/bin/zsh";
  };

  environment.systemPackages = with pkgs; [
    biome
    bundler
    cocoapods
    dotnet-sdk_8
    fd
    bitwarden-desktop
    gh
    git
    git-lfs
    godot_4-mono
    (pkgs.runCommand "godot-mono-app" { } ''
      app="$out/Applications/Godot Mono.app"
      mkdir -p "$app/Contents/MacOS"

      cat > "$app/Contents/Info.plist" <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleDisplayName</key>
        <string>Godot Mono</string>
        <key>CFBundleExecutable</key>
        <string>godot-mono-launcher</string>
        <key>CFBundleIdentifier</key>
        <string>org.godotengine.GodotMono.Nix</string>
        <key>CFBundleName</key>
        <string>Godot Mono</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
      </plist>
      EOF

      cat > "$app/Contents/MacOS/godot-mono-launcher" <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.godot_4-mono}/bin/godot-mono "\$@"
      EOF
      chmod +x "$app/Contents/MacOS/godot-mono-launcher"
    '')
    gnupg
    jq
    nodejs
    openjdk
    pinentry_mac
    ripgrep
    ruby
    uv
    vim
    vscode
    wget
    zed-editor
    cloudflared
  ];

  system.activationScripts.postActivation.text = ''
    ln -sf ${pkgs.cocoapods}/bin/pod /usr/local/bin/pod
  '';

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
    onActivation.cleanup = "uninstall";
    casks = [
      "android-studio"
      "chatgpt"
      "claude"
      "cursor"
      "docker-desktop"
      "ghostty"
      "notion"
      "unity-hub"
      "raycast"
      "codex"
      "tradingview"
      "karabiner-elements"
      "lm-studio"
      "notion-calendar"
      "obsidian"
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
