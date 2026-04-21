# Progress Log

## Current Task
- Remove fzf filter/nav modal keybind customization and return to defaults.

## Done
- Removed custom `FZF_*_OPTS` modal keybind/prompt settings from `modules/shell/fzf.nix` and reverted to default fzf behavior.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after removing fzf modal settings.
- Added `desc` labels to Neovim `<leader>H/J/K/L` Lua keymaps in `modules/editors/nvim.nix` so which-key can display resize action descriptions.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding keymap descriptions for which-key.
- Reworked Neovim pane resize mappings in `modules/editors/nvim.nix` to be current-pane-aware via Lua (`<leader>H/J/K/L` now flips `+/-` by neighbor existence in each direction).
- Added count-aware resize behavior for the Neovim pane mappings (`vim.v.count1`), so repeated resizing can be done with prefixes like `5<leader>L`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after implementing current-pane-aware/count-aware Neovim resize mappings.
- Updated Neovim split resize keymaps in `modules/editors/nvim.nix` from `<M-h/j/k/l>` to `<leader>H/J/K/L` to match tmux-style uppercase resize keys.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after switching the Neovim resize keymaps to `<leader>H/J/K/L`.
- Added Neovim split resize keymaps in `modules/editors/nvim.nix` so `<M-h/j/k/l>` resizes panes tmux-style (`vertical resize ±3`, `resize ±3`).
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding the Neovim split resize keymaps.
- (圧縮) 以前の完了履歴 96 件を要約: Home Manager / Neovim / zsh・fzf 設定の段階的移行、警告解消、評価・ビルド再検証を実施。
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after session variable export changes.
- Switched fzf keybind configuration to environment-variable-only management (`FZF_*_OPTS`) by removing `programs.fzf.defaultOptions` and widget option overrides from `modules/shell/fzf.nix`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after moving fzf keybinds to env-vars only.
- Identified root cause: `fzf 0.70.0` rejects `ctrl-[` in `--bind` (`unsupported key: ctrl-[`), which invalidated the bind expression and prevented `esc` override from taking effect.
- Removed `ctrl-[` from the fzf bind expression and kept `esc:ignore+rebind(j,k)+change-prompt(Nav>)` only.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after fixing unsupported fzf key token.
- Switched `FZF_DEFAULT_OPTS` bind/prompt expressions to quoted payload style (e.g. `--bind='esc:...'`) in `modules/shell/fzf.nix`, matching the known-good runtime export format observed in shell.
- Re-verified rendered `home.sessionVariables.FZF_DEFAULT_OPTS` and Home Manager evaluation after the quoted fzf options update.
- Fixed fzf modal keybind behavior in `modules/shell/fzf.nix`: `esc` now rebinds `i/j/k`, and both `start` and `i` transitions unbind `i` so `i` is typeable in Filter mode.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after the fzf `i` key handling fix.
## Next
- Run `home-manager switch --flake .#<profile>` and verify zsh plugin behavior without Sheldon.
- Verify zsh directory navigation behavior after switch (`Ctrl + g` for ghq repos, `c` for normal directory navigation).

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
