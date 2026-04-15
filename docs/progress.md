# Progress Log

## Current Task
- Simplify AI CLI zsh config to `npx`-only aliases.

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
- Enabled `gitsigns` and `diffview` in nixvim.
- Added lean Git keymaps: `]h`, `[h`, `<leader>hp`, `<leader>do`, `<leader>dc`.
- Migrated Home Manager Git options in `modules/core/git.nix` from deprecated `userName`/`userEmail`/`extraConfig` to `programs.git.settings`.
- Re-verified `linux` Home Manager profile evaluation with `nix build .#homeConfigurations.linux.activationPackage --no-link`; Git rename warnings are gone (only existing zsh deprecation warning remains).
- Replaced deprecated `programs.zsh.initExtra` with `programs.zsh.initContent` in `modules/shell/zsh.nix`.
- Re-verified `linux` Home Manager profile evaluation with `nix build .#homeConfigurations.linux.activationPackage --no-link`; zsh deprecation warning is resolved.
- Added Neovim LSP servers for `html`, `ts_ls` (TypeScript/JavaScript/React), and `metals` (Scala), with `cmp_nvim_lsp` capabilities.
- Re-verified `linux` Home Manager profile evaluation with `nix build .#homeConfigurations.linux.activationPackage --no-link` after adding Web/Scala LSPs.
- Added Neovim `cssls` (CSS Language Server) with `cmp_nvim_lsp` capabilities.
- Re-verified `linux` Home Manager profile evaluation with `nix build .#homeConfigurations.linux.activationPackage --no-link` after adding CSS LSP.
- Added `bubblewrap` to Linux-only Home Manager packages in `modules/core/packages.nix` so Codex can find system `bwrap` on PATH.
- Added tmux pane resize keybindings with `prefix + H/J/K/L` (`resize-pane` with repeat enabled) in `dotfiles/tmux.conf`.
- Updated Telescope `file-browser` settings in nixvim to show hidden files and gitignored files (`hidden.file_browser/folder_browser = true`, `no_ignore = true`, `respect_gitignore = false`).
- Re-verified `linux` Home Manager profile evaluation with `nix build .#homeConfigurations.linux.activationPackage --no-link` after Telescope file-browser option changes.
- Enabled Home Manager `programs.fzf.enableZshIntegration` so zsh gets the standard `Ctrl + r` `fzf` history widget.
- Fixed `Ctrl + r` fzf history search not working: moved `ZVM_VI_INSERT_ESCAPE_BINDKEY` and `zvm_after_init` hook to `zsh.nix` before Sheldon init, so fzf keybindings are re-applied after `zsh-vi-mode` resets them.
- Added `npx`-based zsh aliases for `codex`, `gemini-cli`, `copilot`, and `jules`.
- Removed Bob/Claude auto-install logic and local binary priority handling from zsh config.
- Changed `claude` to always use the `npx @anthropic-ai/claude-code` alias.
- Left `bob` unsupported in zsh config because it is deprecated.
- Updated README AI CLI documentation to match the new `npx`-only alias approach.
- Added Neovim `nvim-autopairs` with Tree-sitter awareness so typing brackets and quotes inserts the closing pair automatically.
- Disabled the plugin's default `<CR>` mapping so it does not interfere with the existing `nvim-cmp` confirm keybinding.
- Expanded README with concrete day-to-day Nix operations (`nix search`, `nix eval`, `nix path-info`, `nix shell`, `nix flake show`).
- Enabled `plugins.copilot-lua` in nixvim and disabled its `panel/suggestion` UI to avoid overlap with the current `nvim-cmp` flow.
- Updated nvim-cmp keybindings to use `<Tab>/<S-Tab>` for completion navigation and changed `completeopt` to `menu,menuone` so selected candidates are inserted while cycling.
- Enabled `autoindent` in nixvim opts so newline keeps the previous line indentation baseline.
- Disabled treesitter indent for Scala (`indent.disable = [ "scala" ]`) so Scala buffers fall back to Vim's auto/smart indent behavior.
- Added a Scala `FileType` autocmd to force `indentexpr = ""` and re-enable `autoindent/smartindent`, because treesitter indentexpr was still being set in Scala buffers.

## Next
- Run `home-manager switch --flake .#<profile>` and verify the `npx`-based AI CLI aliases resolve as expected in zsh.

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
