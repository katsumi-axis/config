# Repository Guidelines

## Project Structure & Module Organization

This repository manages a personal macOS configuration with Nix flakes, `nix-darwin`, and Home Manager.

- `flake.nix` is the entry point. It defines inputs, host metadata, the formatter, and `darwinConfigurations`.
- `flake.lock` pins upstream inputs. Update it intentionally and review the diff.
- `modules/darwin.nix` contains system-level macOS, Nix, Homebrew, app, and package configuration.
- `home.nix` contains user-level Home Manager settings, shell aliases, Git defaults, packages, and Zsh configuration.
- `README.md` documents bootstrap and apply steps.

Add system modules under `modules/` when a setting group grows large.

## Build, Test, and Development Commands

- `nix fmt` formats all Nix files using the flake formatter (`nixfmt`).
- `nix flake metadata --no-write-lock-file` checks that the flake can be read without mutating `flake.lock`.
- `nix flake check` evaluates flake outputs and catches structural issues before applying changes.
- `sudo darwin-rebuild build --flake .#macbook-pro-m4` builds the macOS system without switching to it.
- `sudo darwin-rebuild switch --flake .#macbook-pro-m4` applies the configuration to the local machine.

Use `switch` only after reviewing the build result and Home Manager collision warnings.

## Coding Style & Naming Conventions

Use `nixfmt` output as the source of truth. Keep Nix indentation at two spaces, prefer one list item per line for packages/apps, and preserve existing option names. Use lowercase or kebab-case names for host and module identifiers, for example `macbook-pro-m4`.

Keep host-specific facts in `flake.nix`; keep reusable macOS behavior in `modules/`; keep user shell and program preferences in `home.nix`.

## Testing Guidelines

There is no standalone test suite. Validation is Nix-based: run `nix fmt`, `nix flake check`, and preferably `sudo darwin-rebuild build --flake .#macbook-pro-m4` before applying. For package, cask, or App Store changes, confirm exact identifiers before committing.

## Commit & Pull Request Guidelines

Recent commits use concise Conventional Commit-style subjects such as `feat: ...`, `fix: ...`, and `refactor: ...`; a short area prefix like `darwin: ...` is also used. Keep subjects imperative and specific.

Pull requests should summarize the intended configuration change, mention whether `flake.lock` changed, list validation commands run, and include screenshots only for visible macOS UI changes.

## Agent-Specific Instructions

Do not revert unrelated local edits. This repository may contain machine-specific or in-progress configuration changes. Keep edits narrow, review diffs carefully, and avoid applying `darwin-rebuild switch` unless explicitly requested.
