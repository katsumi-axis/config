{ pkgs, ... }:

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
in
{
  nixpkgs.overlays = [
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
  ];

  environment.systemPackages = [
    nodejsSecurityRelease
    # Prefer .NET 10 LTS while retaining the patched .NET 8 SDK for existing projects.
    (pkgs.dotnetCorePackages.combinePackages [
      pkgs.dotnetCorePackages.sdk_10_0-bin
      pkgs.dotnetCorePackages.sdk_8_0-bin
    ])
  ];
}
