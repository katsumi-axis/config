# macOS config

## Files

- `flake.nix`: nix-darwinとHome Managerの入口
- `modules/darwin.nix`: macOS全体の設定
- `home.nix`: ユーザー設定

## Apply

```sh
nix --extra-experimental-features 'nix-command flakes' run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake .#axiss-MacBook-Pro-6
```

```sh
darwin-rebuild switch --flake .#axiss-MacBook-Pro-6
```
