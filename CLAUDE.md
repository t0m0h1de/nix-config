# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Apply configuration (first time)
nix run home-manager/master -- switch --flake .#linux    # Linux/WSL
nix run home-manager/master -- switch --flake .#darwin   # macOS

# Apply configuration (after home-manager is installed)
home-manager switch --flake .#linux
home-manager switch --flake .#darwin

# Update flake inputs
nix flake update

# Format Nix files
nixpkgs-fmt <file.nix>

# Check flake outputs
nix flake check
```

## Architecture

This is a [Home Manager](https://github.com/nix-community/home-manager) flake-based dotfiles repo supporting two profiles:
- `linux` — x86_64-linux (Linux/WSL)
- `darwin` — aarch64-darwin (macOS)

Both profiles use the same `home.nix` root; platform differences are handled inline with `pkgs.stdenv.isDarwin` / `pkgs.stdenv.isLinux` conditionals.

### Module Structure

`home.nix` imports four top-level modules, each with a `default.nix` aggregator:

| Module | Path | Responsibility |
|--------|------|----------------|
| core | `modules/core/` | Common packages, git config, PATH/EDITOR setup |
| dev | `modules/dev/` | Kubernetes tools, languages (Node/Rust), OpenTofu |
| shell | `modules/shell/` | Zsh, Starship, Tmux, Sheldon, direnv |
| editors | `modules/editors/` | Vim, Neovim (with lazy.nvim) |

### Dotfile Handling Pattern

- **Inline content**: `builtins.readFile` used for single-file configs (e.g., tmux.conf, vimrc, zshrc)
- **Directory symlinks**: `xdg.configFile` with `source = ./dotfiles/<dir>` for multi-file configs (e.g., Neovim's `dotfiles/nvim/`)
- **Direct file placement**: `home.file` for home directory files

### CLI Management Strategy

- **Nix-managed**: Standard tools, LSP servers, formatters, linters
- **Vendor-managed** (installed via public installers in zshrc): Self-updating CLIs like `claude`, `bob` (neovim version manager), `cline`
- **npm-managed**: Global npm packages configured via `.npmrc` with custom prefix

### Secrets

`~/.secrets` is sourced from `.zshrc` at shell startup for tokens/environment variables — never committed.
