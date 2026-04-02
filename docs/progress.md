# Progress Log

## Current Task
- Replace the custom Lua-based Neovim setup with a minimal nixvim-based configuration.

## Done
- Read the current Home Manager and Neovim setup.
- Switched the flake to import `nixvim` from the `nixos-25.05` branch.
- Replaced the `dotfiles/nvim` symlink approach with a minimal `programs.nixvim` configuration.
- Removed the old Lua files under `dotfiles/nvim`.
- Aligned the default editor settings to use `nvim`.
- Verified the `linux` Home Manager profile builds with `nix build .#homeConfigurations.linux.activationPackage --no-link`.
- Added inline comments to the minimal nixvim options and keymaps for readability.
- Added the `tokyonight` colorscheme and a minimal `treesitter` setup in nixvim.
- Added a minimal `lualine` setup and aligned its theme with `tokyonight`.
- Added a minimal `which-key` setup for key-hint popups.
- Added `tmux-navigator` in nixvim for seamless pane navigation with tmux.
- Enabled OSC 52 clipboard support in tmux (`set-clipboard` + `terminal-features`).
- Added Neovim OSC 52 clipboard fallback logic for SSH/WSL/no-local-provider environments.

## Next
- Verify Home Manager configuration still evaluates cleanly after tmux updates.

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
- There is an unrelated existing evaluation warning about `programs.zsh.initExtra` being deprecated in favor of `programs.zsh.initContent`.
