{
  description = "Personal macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Keep Bitwarden on a known-good Darwin build until nixpkgs-unstable fixes its clang/libc++ mismatch.
    nixpkgs-bitwarden.url = "github:NixOS/nixpkgs/01fbdeef22b76df85ea168fbfe1bfd9e63681b30";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-bitwarden,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      hosts = {
        macbook-pro-m4 = {
          username = "axis";
          homeDirectory = "/Users/axis";
        };
      };
      mkDarwinConfiguration =
        hostname:
        { username, homeDirectory }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              username
              homeDirectory
              hostname
              nixpkgs-bitwarden
              ;
          };
          modules = [
            ./modules/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-home-manager";
              home-manager.users.${username} = import ./home.nix;
            }
          ];
        };
    in
    {
      darwinConfigurations = nixpkgs.lib.mapAttrs mkDarwinConfiguration hosts;

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
