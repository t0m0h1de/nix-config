# Progress Log

## Current Task
- Avoid duplicate `zsh-abbr` registration in nested zsh/tmux shells.

## Done
- (圧縮) 以前の完了履歴 94 件を要約: Home Manager / Neovim / zsh・fzf 設定の段階的移行、警告解消、評価・ビルド再検証を実施。
- Exported `FZF_DEFAULT_OPTS` / `FZF_CTRL_R_OPTS` / `FZF_CTRL_T_OPTS` / `FZF_ALT_C_OPTS` via `home.sessionVariables` in `modules/shell/fzf.nix` so fzf widget behavior is guaranteed to be present in the shell environment.
- Normalized fzf prompt strings to no-trailing-space form (`Filter>`, `Nav>`) and reused a single bind string constant for consistency.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after session variable export changes.
- Switched fzf keybind configuration to environment-variable-only management (`FZF_*_OPTS`) by removing `programs.fzf.defaultOptions` and widget option overrides from `modules/shell/fzf.nix`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after moving fzf keybinds to env-vars only.
- Identified root cause: `fzf 0.70.0` rejects `ctrl-[` in `--bind` (`unsupported key: ctrl-[`), which invalidated the bind expression and prevented `esc` override from taking effect.
- Removed `ctrl-[` from the fzf bind expression and kept `esc:ignore+rebind(j,k)+change-prompt(Nav>)` only.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after fixing unsupported fzf key token.
- Switched `FZF_DEFAULT_OPTS` bind/prompt expressions to quoted payload style (e.g. `--bind='esc:...'`) in `modules/shell/fzf.nix`, matching the known-good runtime export format observed in shell.
- Re-verified rendered `home.sessionVariables.FZF_DEFAULT_OPTS` and Home Manager evaluation after the quoted fzf options update.
## Next
- Run `home-manager switch --flake .#<profile>` and verify zsh plugin behavior without Sheldon.
- Verify zsh directory navigation behavior after switch (`Ctrl + g` for ghq repos, `c` for normal directory navigation).

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
