{
  config,
  pkgs,
  username,
  homeDirectory,
  hostname,
  ...
}:

let
  # Use the bundled security fixes until nixpkgs ships Node.js 24.22.1 or newer.
  # https://nodejs.org/en/blog/vulnerability/october-2026-security-releases
  nodejsSecurityRelease =
    if pkgs.lib.versionAtLeast pkgs.nodejs_24.version "24.22.1" then
      pkgs.nodejs_24
    else
      pkgs.stdenvNoCC.mkDerivation rec {
        pname = "nodejs";
        version = "24.22.1";

        src = pkgs.fetchurl {
          url = "https://nodejs.org/dist/v${version}/node-v${version}-darwin-arm64.tar.gz";
          hash = "sha256-icaCWT12zUQjP6U7FWMmTn3py7GJytFpE1xbT637wKc=";
        };

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -R . "$out/"
          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          export PATH="$out/bin:$PATH"
          test "$(node --version)" = "v${version}"
          npm --version
          corepack --version
          runHook postInstallCheck
        '';

        meta = {
          inherit (pkgs.nodejs_24.meta) description homepage license;
          platforms = [ "aarch64-darwin" ];
        };
      };
  androidSdk =
    (pkgs.androidenv.composeAndroidPackages {
      platformVersions = [
        "36"
      ];
      buildToolsVersions = [
        "36.0.0"
      ];
      platformToolsVersion = "37.0.1";
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
    package = pkgs.nixVersions.latest;
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
        # https://github.com/google/brotli/releases/tag/v1.2.1
        brotli =
          if prev.lib.versionAtLeast prev.brotli.version "1.2.1" then
            prev.brotli
          else
            prev.brotli.overrideAttrs (
              finalAttrs: _: {
                version = "1.2.1";
                src = prev.fetchFromGitHub {
                  owner = "google";
                  repo = "brotli";
                  tag = "v${finalAttrs.version}";
                  hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
                };
              }
            );

        # https://c-ares.org/changelog.html#1_34_9
        c-ares =
          if prev.lib.versionAtLeast prev.c-ares.version "1.34.9" then
            prev.c-ares
          else
            prev.c-ares.overrideAttrs (
              finalAttrs: _: {
                version = "1.34.9";
                src = prev.fetchurl {
                  url = "https://github.com/c-ares/c-ares/releases/download/v${finalAttrs.version}/c-ares-${finalAttrs.version}.tar.gz";
                  hash = "sha256-k2S3ChLrWaBoMPtIjZNX+QEA3/DZiyPqNZOhg9Q+by8=";
                };
              }
            );
      })
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
    nodejsSecurityRelease
    # Prefer .NET 10 LTS while retaining the patched .NET 8 SDK for existing projects.
    (pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnetCorePackages.sdk_10_0-bin
      pkgs.dotnetCorePackages.sdk_8_0-bin
    ])
    androidSdkTools
    android-tools
    biome
    bundler
    cocoapods
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
      sudo --user=${username} --set-home /opt/homebrew/bin/brew trust --tap getsentry/tools
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
        "/System/Applications/Apps.app"
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
        "/Applications/ChatGPT.app"
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
      "getsentry/tools"
      "runpod/runpodctl"
    ];
    brews = [
      "duckdb"
      "getsentry/tools/sentry"
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
      "mongodb-compass"
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
