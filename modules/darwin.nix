{
  config,
  pkgs,
  username,
  homeDirectory,
  hostname,
  nixpkgs-bitwarden,
  ...
}:

let
  bitwardenPkgs = import nixpkgs-bitwarden {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  androidSdk =
    (pkgs.androidenv.composeAndroidPackages {
      platformVersions = [
        "36"
      ];
      buildToolsVersions = [
        "36.0.0"
      ];
      platformToolsVersion = "35.0.2";
      abiVersions = [ "arm64-v8a" ];
      includeCmake = false;
      includeEmulator = true;
      includeNDK = true;
      ndkVersions = [ "27.1.12297006" ];
      includeSystemImages = true;
      systemImageTypes = [ "google_apis_playstore" ];
    }).androidsdk;
  androidSdkRoot = "${androidSdk}/libexec/android-sdk";
  androidSdkDefaultRoot = "${homeDirectory}/Library/Android/sdk";
  androidSdkTools = pkgs.symlinkJoin {
    name = "android-sdk-tools";
    paths = [ androidSdk ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for tool in emulator avdmanager sdkmanager; do
        if [ -x "$out/bin/$tool" ]; then
          wrapProgram "$out/bin/$tool" \
            --set ANDROID_HOME ${androidSdkRoot} \
            --set ANDROID_SDK_ROOT ${androidSdkRoot}
        fi
      done
    '';
  };
in
{
  system.stateVersion = 6;
  system.primaryUser = username;

  nix = {
    enable = true;
    settings.experimental-features = "nix-command flakes";
  };

  launchd.daemons.nix-daemon.serviceConfig.RunAtLoad = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
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
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    androidSdkTools
    android-tools
    biome
    bundler
    cocoapods
    dotnet-sdk_8
    fd
    bitwardenPkgs.bitwarden-desktop
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
    pinentry_mac
    ripgrep
    cargo
    ruby
    rustc
    rustup
    uv
    vim
    vscode
    wget
    zed-editor
    cloudflared
  ];

  environment.variables = {
    ANDROID_HOME = androidSdkDefaultRoot;
    ANDROID_SDK_ROOT = androidSdkDefaultRoot;
  };

  launchd.user.envVariables.PATH = [
    "${homeDirectory}/.cargo/bin"
    config.environment.systemPath
  ];

  environment.systemPath = [
    "${androidSdkDefaultRoot}/cmdline-tools/latest/bin"
    "${androidSdkDefaultRoot}/emulator"
    "${androidSdkDefaultRoot}/platform-tools"
    "${androidSdkDefaultRoot}/tools/bin"
  ];

  system.activationScripts.preActivation.text = ''
    if [ -x /opt/homebrew/bin/brew ]; then
      sudo --user=${username} --set-home /opt/homebrew/bin/brew trust --tap runpod/runpodctl
    fi
  '';

  system.activationScripts.postActivation.text = ''
    ln -sf ${pkgs.cocoapods}/bin/pod /usr/local/bin/pod

    rustup="${pkgs.rustup}/bin/rustup"
    if [ -x "$rustup" ]; then
      if ! sudo -u ${username} env HOME="${homeDirectory}" "$rustup" toolchain list | grep -q '^stable'; then
        sudo -u ${username} env HOME="${homeDirectory}" "$rustup" toolchain install stable --no-self-update
      fi
      sudo -u ${username} env HOME="${homeDirectory}" "$rustup" default stable
      if ! sudo -u ${username} env HOME="${homeDirectory}" "$rustup" target list --installed | grep -q '^wasm32-wasip1$'; then
        sudo -u ${username} env HOME="${homeDirectory}" "$rustup" target add wasm32-wasip1
      fi
    fi

    android_sdk_default="${homeDirectory}/Library/Android/sdk"
    mkdir -p "${homeDirectory}/Library/Android"
    if [ -L "$android_sdk_default" ] || [ ! -e "$android_sdk_default" ]; then
      ln -sfn ${androidSdkRoot} "$android_sdk_default"
    fi
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };

  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "/System/Applications/Launchpad.app"
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
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
    onActivation.extraFlags = [ "--force-cleanup" ];
    taps = [
      "runpod/runpodctl"
    ];
    brews = [
      "runpodctl"
      "visidata"
    ];
    casks = [
      "android-studio"
      "blender"
      "chatgpt"
      "claude"
      "cursor"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "notion"
      "unity-hub"
      "raycast"
      "codex"
      "codex-app"
      "tradingview"
      "karabiner-elements"
      "lm-studio"
      "notion-calendar"
      "obsidian"
      "tailscale-app"
      "xcodes-app"
    ];
    masApps = {
      Amphetamine = 937984704;
      DevCleaner = 1388020431;
      Kindle = 302584613;
      Magnet = 441258766;
      Slack = 803453959;
    };
  };
}
