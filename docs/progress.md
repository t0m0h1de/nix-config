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
- Added `telescope` and enabled the `file-browser` extension in nixvim.
- Added `<leader>ff`, `<leader>fg`, `<leader>fb` keymaps for file find/live grep/file browser.
- Re-verified the `linux` Home Manager profile builds with `nix build .#homeConfigurations.linux.activationPackage --no-link`.
- Explicitly enabled `plugins.web-devicons` in nixvim to resolve telescope auto-enable deprecation warning.
- Added minimal Python LSP setup in nixvim by enabling `plugins.lsp.servers.pyright`.
- Added `ripgrep` and `fd` to `home.packages` so Telescope search features work out of the box.
- Enabled `nvim-cmp` in nixvim with basic selection/confirm keybindings (`<C-n>`, `<C-p>`, `<C-Space>`, `<CR>`).
- Added basic LSP keymaps (`gd`, `gr`) via `LspAttach` autocmd.
- Explicitly enabled cmp sources (`cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`) to make completion candidates appear reliably.
- Added explicit `plugins.cmp.settings.sources` and wired `pyright` capabilities through `cmp_nvim_lsp.default_capabilities()`.

## Next
- Verify Python LSP behavior (diagnostics/jump/completion) in a real project after activation.

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
- There is an unrelated existing evaluation warning about `programs.zsh.initExtra` being deprecated in favor of `programs.zsh.initContent`.
