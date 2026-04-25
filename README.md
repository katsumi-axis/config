# macOS config

## Files

- `flake.nix`: nix-darwinとHome Managerの入口
- `modules/darwin.nix`: macOS全体の設定
- `home.nix`: ユーザー設定

## Initial setup on a new Mac

1. macOSの初期設定を済ませる
   - ユーザー名は `axis`
   - ホスト名は `macbook-pro-m4`
   - App Storeにログインしておく

2. Xcode Command Line Toolsを入れる

```sh
xcode-select --install
```

3. Nixを入れる

```sh
curl -L https://nixos.org/nix/install | sh
```

インストール後、ターミナルを開き直す。

4. Homebrewを入れる

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

5. このリポジトリを取得する

```sh
mkdir -p ~/Documents
cd ~/Documents
git clone <repository-url> config
cd config
```

6. 初回だけ `nix-darwin` 経由で適用する

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake .#macbook-pro-m4
```

7. シェルを開き直して確認する

```sh
darwin-rebuild --version
```

Home Managerが既存ファイルとの衝突を検出した場合は、対象ファイルを退避してからもう一度適用する。退避ファイルには `.before-home-manager` が付く。

## Apply

初回セットアップ後は、変更を取り込んでから以下を実行する。

```sh
cd ~/Documents/config
git pull
```

```sh
sudo darwin-rebuild switch --flake .#macbook-pro-m4
```
