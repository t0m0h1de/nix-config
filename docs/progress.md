# Progress Log

## Current Task
- Repository-wide refactoring (completed).

## Done
- Switched the two herdr fzf pickers in `modules/shell/herdr.nix` (`prefix+s` Spaces / `prefix+a` Agents) from `type="pane"` to `type="popup"` (herdr 0.7.4+). Real session-modal floating terminal that doesn't reflow the tab layout; added `width="70%" height="70%"`. Both pickers don't use `HERDR_PANE_ID`, so no bridge changes needed. `work` profile evaluates.
- Guarded the Nix daemon profile source in `dotfiles/zshrc`: マルチユーザ(daemon)の `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` を存在チェック付きで優先し、無ければ `~/.nix-profile/etc/profile.d/nix.sh` に `elif` フォールバック。無条件 source を避け、他OS/インストール形態でのシェル起動エラーを防止。
- Fixed Neovim deprecation warnings (v0.12): replaced `vim.diagnostic.goto_next/goto_prev` keymaps with `vim.diagnostic.jump({ count = ±1 })` in `nvim/keymaps.nix`.
- Patched `copilot-cmp` (archived upstream) via `overrideAttrs postPatch` in `nvim/completion.nix`: `self.client.is_stopped()` → `self.client:is_stopped()` (dot-call triggers the deprecation shim).
- Audited all installed plugins for deprecated APIs: `tbl_flatten`/`tbl_islist` hits are version-guarded compat fallbacks (never fire on 0.12). Remaining upstream dot-calls only fire on rarely-used commands: nvim-lspconfig `pyright.lua` (`:LspPyrightOrganizeImports`) and nvim-metals `tvp/init.lua` (Tree View). A future `nix flake update` may pick up upstream fixes.
- Refactored `flake.nix`: replaced 3 nearly-identical `homeConfigurations` with a `mkHome { system, isWork }` helper; drvPath unchanged.
- Split 689-line `modules/editors/nvim.nix` into `modules/editors/nvim/` (default/options/keymaps/plugins/completion/lsp/scala); verified generated Lua config and keymap count match pre-split.
- Deduplicated LSP `capabilities` definition (4 servers) into a shared `cmpCapabilities` in `nvim/lsp.nix`.
- Removed commented-out dead code (treesitter grammar list, vimade recipe).
- Removed unused `pkgs` module args (common.nix, git.nix, starship.nix) and unneeded quoted attr `pkgs."zsh-abbr"`.
- Verified all profiles evaluate (`linux` / `darwin` / `work`) and ran `nixpkgs-fmt` across the repo.
- Investigated missing `roots` command after successful `home-manager switch` on darwin.
- Confirmed `roots` is included in evaluated `homeConfigurations.darwin.config.home.packages` but not available in `~/.nix-profile/bin`.
- Fixed `roots` overlay build target by adding `subPackages = [ "." ];` in `overlays/default.nix` to ensure the main binary is installed.
- Extracted custom package overlays from `flake.nix` into `overlays/default.nix` for easier future overlay management.
- Updated `flake.nix` to import a single `customOverlay` from `./overlays` and apply it via `mkPkgs`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after overlay refactor.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after overlay refactor.
- Added `roots` package definition to `flake.nix` overlay using `buildGoModule` (version `0.4.1`) sourced from `k1LoW/roots` tag `v0.4.1`.
- Resolved and fixed `roots` source hash in `flake.nix` (`sha256-ACMRfWY/lhc3C/KVhuUyS1rgkSHGWPxZrmYt+pXupJI=`).
- Resolved and fixed `roots` Go modules vendor hash in `flake.nix` (`sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=`).
- Added `roots` to `home.packages` in `modules/core/packages.nix`.
- Verified `roots` package build with `nix build --impure --expr '(let flake = builtins.getFlake (toString ./.); in flake.homeConfigurations.darwin.pkgs.roots)'`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `roots`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `roots`.
- Added `inputs.nix-zenn-cli.url = "github:t0m0h1de/nix-zenn-cli"` to `flake.nix`.
- Added a shared `mkPkgs` function in `flake.nix` and applied an overlay that exposes `nix-zenn-cli.packages.${system}.default` as `pkgs.zenn-cli` for both Linux and Darwin Home Manager profiles.
- Added `zenn-cli` to `home.packages` in `modules/core/packages.nix`.
- Evaluated Home Manager with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after integrating `nix-zenn-cli`.
- Evaluated Home Manager with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after integrating `nix-zenn-cli`.
- Enabled `plugins.snacks.settings.indent.enabled = true` in `modules/editors/nvim.nix` to improve indent guides visualization.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after enabling Snacks indent.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after enabling Snacks indent.
- Added Neovim keymap `<leader>un` in `modules/editors/nvim.nix` to open `Snacks.notifier.show_history()`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `<leader>un`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `<leader>un`.
- Enabled `plugins.snacks` in `modules/editors/nvim.nix` with minimal settings (`bigfile`, `notifier`, `quickfile`, `statuscolumn`, `words`) to start phased adoption.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after enabling `snacks.nvim`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after enabling `snacks.nvim`.
- Added Neovim keymap `<leader>E` in `modules/editors/nvim.nix` to open all diagnostics with `:Telescope diagnostics` (in addition to `<leader>e` float-at-cursor).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `<leader>E` diagnostics keymap.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `<leader>E` diagnostics keymap.
- Added `jdk17` to `home.packages` in `modules/dev/langs.nix`.
- Added `home.sessionVariables.JAVA_HOME = "${pkgs.jdk17}/lib/openjdk"` in `modules/dev/langs.nix`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `jdk17` and `JAVA_HOME`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `jdk17` and `JAVA_HOME`.
- Set `metals_config.settings.metalsBinaryPath = "${pkgs.metals}/bin/metals"` in `modules/editors/nvim.nix` so `nvim-metals` uses the Nix-managed binary instead of cache-based install detection.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after setting `metalsBinaryPath`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after setting `metalsBinaryPath`.
- Added `coursier` to `home.packages` in `modules/dev/langs.nix` to satisfy `nvim-metals` prerequisite checks.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `coursier`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `coursier`.
- Removed temporary safe overrides for `nvim-metals` user commands from `modules/editors/nvim.nix` and returned to plain plugin commands.
- Relaxed Scala project marker detection in `modules/editors/nvim.nix` so `.scala-build` can be either a file or directory.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after removing command wrappers.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after removing command wrappers.
- Added explanatory Lua comments in `modules/editors/nvim.nix` for `nvim-metals` project-root detection and attach behavior.
- Added `sbt` to `home.packages` in `modules/dev/langs.nix`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after Lua comments and `sbt` package updates.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after Lua comments and `sbt` package updates.
- Restricted `nvim-metals` attach conditions in `modules/editors/nvim.nix` to `scala`/`sbt`/`java` buffers that resolve to a project root containing `build.sbt`, `.scala-build`, or `project/`.
- Added Scala project root detection helper in `modules/editors/nvim.nix` and pass detected `root_dir` to `require("metals").initialize_or_attach`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding conditional `nvim-metals` startup.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding conditional `nvim-metals` startup.
- Added `pkgs.vimPlugins.nvim-metals` to `programs.nixvim.extraPlugins` in `modules/editors/nvim.nix`.
- Added `pkgs.metals` to `programs.nixvim.extraPackages` in `modules/editors/nvim.nix`.
- Replaced custom Metals `workspace/executeCommand` wrappers with `nvim-metals` attach flow (`require("metals").bare_config()` + `initialize_or_attach`) on `scala` / `sbt` / `java` `FileType`.
- Removed `plugins.lsp.servers.metals` from `modules/editors/nvim.nix` to avoid duplicate Metals client startup.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after switching to `nvim-metals`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after switching to `nvim-metals`.
- Updated `plugins.vimade.settings.style` in `modules/editors/nvim.nix` to exclude `WinBar`/`WinBarNC` from fading via `vimade.style.exclude`.
- Kept `vimade` fade behavior for other highlights with `vimade.style.fade` (`value = 0.6`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after updating `vimade` style exclusion.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after updating `vimade` style exclusion.
- Added `opts.winbar = "%f %m"` to `modules/editors/nvim.nix` to show file path and modified flag in each window's winbar.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `winbar`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `winbar`.
- Removed `plugins.barbar` from `modules/editors/nvim.nix`.
- Removed `barbar` keymaps from `modules/editors/nvim.nix` (`BufferNext/Previous/Goto/Last/Close/Move*` mappings).
- Added Telescope keymaps in `modules/editors/nvim.nix`: `<leader>bb` (`:Telescope buffers sort_mru=true ignore_current_buffer=true`) and `<leader>fr` (`:Telescope oldfiles cwd_only=true`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after replacing `barbar` with Telescope keymaps.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after replacing `barbar` with Telescope keymaps.
- Updated `barbar` navigation keymaps in `modules/editors/nvim.nix`: `<leader>bn`/`<leader>bp` -> `<leader>n`/`<leader>p`.
- Added direct `barbar` buffer jump keymaps in `modules/editors/nvim.nix`: `<leader>1`..`<leader>9` (`:BufferGoto N`) and `<leader>0` (`:BufferLast`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after updating `barbar` keymaps.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after updating `barbar` keymaps.
- Added Neovim keymaps for `barbar` in `modules/editors/nvim.nix`: `<leader>bn` (`:BufferNext`), `<leader>bp` (`:BufferPrevious`), `<leader>bc` (`:BufferClose`), `<leader>b>` (`:BufferMoveNext`), `<leader>b<` (`:BufferMovePrevious`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `barbar` keymaps.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `barbar` keymaps.
- Added `plugins.vimade.enable = true` to `modules/editors/nvim.nix` to install/enable `vimade` via nixvim.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `vimade`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `vimade`.
- Added `plugins.oil.enable = true` to `modules/editors/nvim.nix` to install/enable `oil.nvim` via nixvim.
- Added Neovim keymap `<leader>fo` in `modules/editors/nvim.nix` to open `oil.nvim` in float mode at the current file's directory (`:Oil --float %:p:h`).
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `oil.nvim`.
- Extended the Scala `FileType` autocmd in `modules/editors/nvim.nix` to also apply `setlocal indentkeys-=<>>`, preventing auto reindent when typing `=>` (`>`).
- Added a Scala `FileType` autocmd in `modules/editors/nvim.nix` to apply `setlocal indentkeys-==case`, preventing auto reindent when typing `case`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after the Scala `indentkeys` autocmd change.
- Updated `dotfiles/zshrc` `cd-nav` directory listing to run under the resolved root directory, so fzf now displays relative paths (`./...`) instead of absolute paths.
- Kept `cd-nav` root argument behavior while resolving the selected relative entry back to an absolute path for `cd`.
- Re-verified shell syntax with `zsh -n dotfiles/zshrc` after the relative-path display update.
- Updated `dotfiles/zshrc` `cd-nav` behavior: it now accepts zero or one argument, validates the root directory, and always opens `fzf` for directory selection under the specified root (or `.` when omitted).
- Added `cd-nav` usage/error handling in `dotfiles/zshrc` for invalid argument count and non-existent directory.
- Verified shell syntax with `zsh -n dotfiles/zshrc` after the `cd-nav` changes.
- Updated `modules/core/ssh.nix` GitHub host options to set `AddKeysToAgent yes` on all OSes and `UseKeychain yes` only on macOS via `pkgs.stdenv.isDarwin`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding OS-conditional SSH options.
- Added Home Manager SSH config management via `modules/core/ssh.nix` (`programs.ssh`), including default `github.com` key settings and `Include ~/.ssh/config.d/*.conf` for local unmanaged overrides.
- Imported the new SSH module from `modules/core/default.nix`.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding SSH config management.
- Simplified README Copilot section by removing the initial `home-manager switch` / `nvim` startup step and keeping only Neovim-side auth/status operations.
- Added README instructions for Neovim GitHub Copilot onboarding (`:Copilot auth`, `:Copilot status`, signout/signin/info) and clarified that this repo uses `copilot-cmp` with `panel/suggestion` disabled.
- Added `copilot-cmp` integration in `modules/editors/nvim.nix` and registered `copilot` in `nvim-cmp` sources while keeping `copilot-lua` `panel/suggestion` disabled.
- Re-verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `copilot-cmp`.
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
- Updated flake input `nix-zenn-cli` via `nix flake update nix-zenn-cli` and refreshed `flake.lock` to commit `06c50632738a1ed8ce226e4ec4700f753bcc8d9e` (2026-05-18).
- Added `zed-editor` to `home.packages` in `modules/core/packages.nix`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding `zed-editor`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `zed-editor`.
- Fixed `isWork` missing error caused by home-manager update: added `extraSpecialArgs = { isWork = false; }` to `linux` and `darwin` profiles in `flake.nix`.
- Added `overmind`, `gettext`, `pre-commit` to `home.packages` in `modules/core/packages.nix`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding the 3 packages.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding the 3 packages.
- Added Takumi Guard PyPI environment variables (`PIP_INDEX_URL`, `UV_INDEX_URL`, `UV_EXCLUDE_NEWER`) to `programs.zsh.initContent` in `modules/shell/zsh.nix` after `~/.secrets` sourcing, so `TAKUMI_GUARD_API_KEY` is available at runtime.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding Takumi Guard env vars.

- Added `kube-tmux` (jonmosco/kube-tmux) to `overlays/default.nix` via `fetchFromGitHub` (hash: `sha256-l1wjg2ReWKCI7h/K11vvX2ykYTs/mVD+tfz/mQsjn/E=`).
- Updated `modules/shell/tmux.nix` to append `status-right` config that calls `${pkgs.kube-tmux}/bin/kube.tmux 250 cyan default` so the current k8s context/namespace is shown in the tmux status bar.
- Verified `kube-tmux` builds with `nix build --impure --expr '...'` and `result/bin/kube.tmux` exists.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` and linux after adding kube-tmux.
- Added `kubie` to `home.packages` in `modules/dev/k8s.nix` for per-shell Kubernetes context switching.
- Added `~/.kube/kubie.yaml` via `home.file` in `modules/dev/k8s.nix` with `behavior.selector: fzf` so `kubie ctx` uses fzf for fuzzy context selection.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding kubie fzf selector config.
- Added `abbr --force --quiet kube='kubectl'` to `dotfiles/zshrc` so typing `kube<Space>` expands to `kubectl` via zsh-abbr.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding `kube` abbreviation.

- Fixed `invalid environment variable` / `syntax error` in `dotfiles/tmux.conf`: replaced `${r:-#{pane_current_path}}` with `if [ -z "$r" ]; then r=...` (tmux 3.2+ treats `${VAR:-...}` as own variable expansion), and escaped all inner double-quotes as `\"` inside single-quoted `set-hook` arguments.
- Added `pkgs.tmuxPlugins.tmux-fzf` to `programs.tmux.plugins` in `modules/shell/tmux.nix` (default keybind: `prefix + F`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` and linux after adding tmux-fzf.
- Added `after-new-session` and `after-new-window` hooks in `dotfiles/tmux.conf` to set window name to `#{b:pane_current_path}` (basename only) on session/window creation.
- Updated `after-new-session` hook in `dotfiles/tmux.conf` to also rename session to `#{pane_current_path}` (full path) on session creation.
- Reworked window naming hooks in `dotfiles/tmux.conf`: window name now shows git repo basename on main/master, or `repo@branch-leaf` on feature branches (e.g. `project@improve-readability` from `feature/improve-readability`); falls back to directory basename outside git repos.
- Fixed broken session/window naming hooks in `dotfiles/tmux.conf`: replaced `rename-window "#(command)"` with `run-shell "... tmux rename-window -t #{window_id} ..."` because `rename-window`/`rename-session` do not evaluate `#()` format expressions — only `run-shell` passes `#{...}` expansions to the shell for execution.
- Added `watch` to `home.packages` in `modules/core/packages.nix`.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` and linux after adding watch.
- Added `gwq` (d-kuro/gwq v0.1.1) to `overlays/default.nix` via `buildGoModule` and to `home.packages` in `modules/core/packages.nix`.
- Added `~/.config/gwq/config.toml` via `xdg.configFile` in `modules/core/git.nix`: basedir=`~/src` (same as ghq root), naming template=`{{.Host}}/{{.Owner}}/{{.Repository}}+{{.Branch}}`.
- Updated `ghq-fzf` in `dotfiles/zshrc` to merge `gwq list` output with `ghq list`, dedup with `sort -u`, so Ctrl+g lists both repos and gwq worktrees.
- Removed hand-rolled `gwt-add` function from `dotfiles/zshrc` (replaced by `gwq add`).
- Fixed `window-picker` module-not-found error: moved `nvim-window-picker` from `plugins.nvim-window-picker` (broken — plugin not added to runtimepath) to `extraPlugins` and setup via `extraConfigLua`.
- Added `plugins.nvim-window-picker` to `modules/editors/nvim.nix` with `floating-big-letter` hint style and filter rules to exclude nvim-tree/terminal windows.
- Wired `nvim-window-picker` into `nvim-tree` via `actions.open_file.window_picker.picker.__raw` so file open uses the picker UI.
- Added `plugins.nvim-tree` to `modules/editors/nvim.nix` with git integration, icon highlight, and 30-column left sidebar.
- Added keymap `<leader>ft` in `modules/editors/nvim.nix` to toggle nvim-tree (`:NvimTreeToggle`).
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.darwin.activationPackage.drvPath` after adding nvim-tree.
- Verified Home Manager evaluation with `nix eval .#homeConfigurations.linux.activationPackage.drvPath` after adding nvim-tree.

- Diagnosed root cause of broken tmux session/window naming hooks: `run-shell "cmd1; cmd2"` does not propagate shell variables between semicolon-separated commands.
- Refactored `after-new-session` hook into `pkgs.writeShellScript "tmux-name-session"` in `modules/shell/tmux.nix`; nix store path embedded via Nix interpolation.
- Session name: `repo@branch` (git-untracked → directory basename; `.` → `_` for tmux separator safety).
- repo name is taken from `git worktree list | head -1` (main worktree) to avoid gwq worktree `+branch` suffix duplication.
- Window name: reverted to `automatic-rename on` (shows running command name like `zsh`, `nvim`).
- Removed `after-new-window` hook and `automatic-rename off` from `dotfiles/tmux.conf`.
- Verified: session `nix-config@main`, window `zsh` (automatic-rename).
- Identified that this macOS machine must use `.#work` profile (isWork=true → home.username=tomohide.sawada); `.#darwin` profile uses t0m0h1de and fails activation.

- Reverted `ghq-fzf` in `dotfiles/zshrc` to show only `ghq list` output on Ctrl+g (removed `gwq list` merge).

### 監査レポート対応 (docs/audit-2026-06-12.md) — 2026-06-25
- 項目1: `modules/dev/langs.nix` の `JAVA_HOME` を実在しない `${pkgs.jdk17}/lib/openjdk` から `pkgs.jdk17.home` に修正 (commit d03babd)。`work` プロファイルで `JAVA_HOME` が zulu jdk home に解決することを確認。
- 項目2: `modules/core/packages.nix` から重複JDK `zulu17` を削除し `jdk17`(langs.nix) に一本化 (commit 135969e)。
- 項目3: `user.email` の二重定義を `modules/core/git.nix` に集約し `dotfiles/gitconfig` から削除 (commit f775cc4)。監査時点の ibm.com/gmail 不一致は既に両方 gmail に統一済みだった。
- 項目4: `README.md` を実態に合わせ更新 (commit 97749f5)。実在しない `dotfiles/work.gitconfig` 記述を削除、`work` プロファイル追記、`darwin` の username 地雷を注記、Git設定セクションを `~/.gitconfig-extras` 機構に修正。
- 項目5: `nix build` 成果物の `result` シンボリックリンクを削除 (gitignore 済みのためコミット無し)。
- 項目7: `overlays/default.nix` の kube-tmux 参照を `rev = "master"` から commit `8b7e1d12...` に固定 (commit c8af11d)。固定rev で既存 hash のままビルド成功することを確認。
- 項目6(username ハードコード)・項目8(`cd-nav` の fd 依存) は監査でも許容範囲/情報扱いのため今回未対応。
- `nix eval .#homeConfigurations.work.activationPackage.drvPath` で全体が評価できることを確認。

### herdr 移行 (docs/herdr-migration-plan.md) — 2026-07-06
- 移行プラン `docs/herdr-migration-plan.md` を作成(Phase 0検証→1 config→2 workflow→3 tmux撤去)。
- Phase 1 完了: `modules/shell/herdr.nix` を新規作成し `xdg.configFile."herdr/config.toml"` で Nix 管理化。
  既存 `~/.config/herdr/config.toml`(オンボーディング生成)の nord テーマを取り込み。
  version_check 無効・resume_agents_on_restore・prefix+j/k をタブ移動に割当。`modules/shell/default.nix` に import 追加。
  生成 config.toml を tomllib で妥当性確認、work 評価成功 (commit 7be1fac)。
- Phase 2-a 完了: `dotfiles/zshrc` に `hws`(herdr workspace を repo@branch で作成)を追加。tmuxNameSession の命名規則を移植 (commit 2c89137)。
- Phase 2-b 完了: Claude 状態スタンプ hook 一式(tmux-state.sh + settings.json の該当 hook)を削除 (commit 78e1e02)。
  併せて claude.nix の settings.json マージを `del(.env,.language,.permissions,.hooks) * base` に修正。
  単純な再帰マージ `.[0]*.[1]` は base で削除したキーを live に反映できず、stale hook が残る問題を解消
  (mock target でマージ結果を検証: Claude管理キー温存・stale hook除去を確認)。
- Phase 2-c 完了: kube 表示の代替として starship の kubernetes モジュールを有効化(`dotfiles/starship.toml`)。
  format に `$kubernetes` を追加し context/namespace を常時表示。tmux status-right の kube-tmux から移行 (commit 5fca913)。
- vim-herdr-navigation 導入 (commit 7d93e36): C-hjkl で herdr ペイン ⇄ nvim split をシームレス移動
  (vim-tmux-navigator の herdr 版)。ソースは Nix 固定(fetchFromGitHub, rev 53e318c)、activation で
  `herdr plugin link` 登録、config.toml に ctrl+h/j/k/l 割当、nvim 側は extraConfigLua に editor/nvim.lua
  相当を移植(HERDR_PANE_ID なら herdr / TMUX なら TmuxNavigate の両対応)。herdr theme は `nord` のまま(変更不要)。
- **残り(意図的に保留)**: Phase 3(tmux 撤去)。herdr を数日運用してユーザーの合格判定を得てから、
  `modules/shell/tmux.nix`/`dotfiles/tmux.conf`/`overlays` の kube-tmux/nvim の tmux-navigator を削除する。
- 適用時の注意: `~/.config/herdr/config.toml` が実ファイルとして存在するため、初回 switch は
  `home-manager switch --flake .#work -b backup`(既存を .backup に退避)が必要。以後 config は read-only symlink。
  反映後 `herdr server reload-config` で稼働中サーバに適用し、`~/.config/herdr/herdr-server.log` に設定警告が出ていないか
  (特に `[keys]` の配列/`prefix+down` 受理)を確認すること。

### herdr: フロート Spaces ピッカー(fzf, 自前MRU) — 2026-07-08
- `modules/shell/herdr.nix` に fzf ピッカーを追加。`prefix+s` で一時ペイン(`[[keys.command]]` type="pane")に
  fzf を開き、workspace を絞り込み → enter で `herdr workspace focus`。空クエリ時は最終アタッチ順(MRU)で並ぶ。
- 実装: `writeShellScript` 3本を let に追加(tmux.nix の fzf ピッカーと同じ流儀)。
  - `herdr-workspace-list`: `herdr workspace list`(JSON)を jq で `id\t icon+label \t focused` 化 →
    MRU ファイル順(現存のみ)→ 未記録の現存を list 順で並べ、現在フォーカス中を除外して `<display>\t<id>` 出力。
  - `herdr-workspace-focus`: 選択 id を MRU 先頭へ積んで `herdr workspace focus`(become で fzf を置換)。
  - `herdr-workspace-picker`: 一覧を fzf に流し `--with-nth=1`(表示)/`{2}`(id)。
- MRU の理由: herdr の API は last-attached/last-focused 時刻を返さない(list の `focused` は bool、number は作成順)。
  そのため MRU は自前ファイル(`$XDG_CACHE_HOME/herdr/workspace-mru`)で管理。GC はピッカー起動のたびに
  現存 workspace で刈り込んで書き戻す方式(起動時クリアより上位互換: サーバ再起動をまたいでも履歴が残る)。
- キー再割当: `prefix+s`=自前fzfピッカー / ネイティブ `workspace_picker`=`prefix+shift+s`(保険) /
  `settings`=`prefix+shift+g`(prefix+shift+s を picker に譲るため退避。new_worktree 無効化で空いた枠)。
- 制約(ユーザーに共有済み): herdr は「起動時からサイドバー非表示」設定が無く(`toggle_sidebar`=prefix+b のトグルのみ)、
  真のフローティングウィンドウも無い。サイドバーは残す方針にし、ピッカーは type="pane" の一時ペインで近似。
- 検証: `nixpkgs-fmt`(整形なし)・`nix-instantiate --parse`・`nix eval .#homeConfigurations.work.activationPackage.drvPath`
  成功。生成 config.toml を tomllib で妥当性確認([[keys.command]] 5件=fzfピッカー1+vim-nav4、ストアパス埋め込み確認)。
- 未実施(ユーザー確認): switch → `herdr server reload-config` 後の実挙動(prefix+s で fzf が開く/enter で切替/
  空クエリMRU順/GC)は未検証。bash スクリプトの実行検証はセッションの権限制約で行えずレビューのみ。
- 追加修正: fzf 内で Ctrl+j/k の選択移動が効かない問題に対応。原因は vim-herdr-navigation が Ctrl+h/j/k/l を
  グローバルに奪い(navigate.sh)、Vim 以外の前面アプリ(fzf)には転送しないため。navigate.sh は
  `HERDR_NAV_PASSTHROUGH_RE`(小文字化した前面プロセス名への ERE)にマッチすれば `herdr pane send-keys` で
  前面へ転送する opt-in を持つ。当初 `home.sessionVariables` で env を渡したが効かず。原因は2点:
  (1) `herdr plugin list` のリンク先が未パッチの上流ソースを指したまま、(2) サーバへの env 継承が起動タイミング依存。
  → env に依存しないよう navigate.sh の既定を `${HERDR_NAV_PASSTHROUGH_RE:-fzf}` に**焼き込むパッチ**へ変更
  (`pkgs.runCommand` で source をコピー → `substituteInPlace --replace-fail`)。ビルドで置換成功と
  `passthrough_re="${HERDR_NAV_PASSTHROUGH_RE:-fzf}"` の反映を確認。
  activation は `plugin unlink → link` に変更(link だけだと古いストアパスが残りパッチ未反映になるため)。
  env(`home.sessionVariables.HERDR_NAV_PASSTHROUGH_RE = "fzf"`)は追加TUI用の上書きとして残置。
  注意: switch はサーバ稼働中に行うこと(activation の unlink/link が届く)。反映後 `herdr plugin list` が
  新ストアパス(vim-herdr-navigation)を指すことを確認 → 効かなければ `herdr server reload-config`。

### herdr: フロート Agent ピッカー(fzf, 注目度順) — 2026-07-08
- `prefix+a` で fzf フロート(type="pane")にエージェント一覧を出し、enter で `herdr agent focus <terminal_id>`。
  Spaces ピッカー(prefix+s)の Agent 版。並びは注目度順(blocked→working→unknown→idle)。現在フォーカス中は除外。
- 実装: `writeShellScript` 2本を let に追加。
  - `herdr-agent-list`: `herdr agent list` を jq(`def prio`/`def icon`/`sort_by`/`select(.focused|not)`)で整形。
    `herdr workspace list` の workspace_id→label も引き、`<icon> <label> · <agent> · <cwd basename>\t<terminal_id>` 出力。
  - `herdr-agent-picker`: fzf `--with-nth=1`(表示)/`{2}`(terminal_id)、`enter:become(herdr agent focus {2})`。
- 制約: 対象は `herdr agent list` が返す「検知中のエージェント」のみ(workspace list と違い全ペインではない)。
  サーバ再起動直後は検知されるまで件数が少ない(検証時は focused の1件のみ検知 → focused除外で空になる状況を確認)。
- 並びは MRU ではなく attention 順を採用(「対応が必要なエージェントへ飛ぶ」用途に適するため)。MRU 希望なら
  Spaces ピッカーの MRU 機構を流用可能。
- 検証: `nixpkgs-fmt`/`parse`/`eval` 成功、生成 config.toml を tomllib 確認([[keys.command]] 6件=prefix+s/a+ctrl hjkl)。
  jq 整形(prio/icon/sort_by/join)は実データで出力確認。bash 実行検証は権限制約でレビューのみ。
- キー: prefix+a は既存バインドと未衝突を確認。

### herdr 0.7.3 追随: 保留(unstable 反映待ち) — 2026-07-09
- 目的: nixpkgs の herdr が 0.7.1→0.7.3 になったので追随したい。
- 調査結果: nixpkgs-unstable の最新(2026-07-05 時点の rev)でも **herdr は 0.7.1 のまま**。
  0.7.3 は nixpkgs **master(commit cb6e5dce2f37c6a450a70b934d8e09488d2a03d7)には存在**(`nix eval` で 0.7.3 を確認)。
  → 0.7.3 は master には入っているが Hydra ビルド待ちで unstable チャンネルにまだ降りていない状態。
- 判断(ユーザー): master から pin せず **unstable への反映を待つ**。今回は変更なし(試行した `nix flake update nixpkgs`
  は 0.7.1 のままで目的未達だったため flake.lock を revert 済み)。
- 反映後の手順: `nix flake update nixpkgs` →
  `nix eval --raw .#homeConfigurations.work.pkgs.herdr.version` が 0.7.3 になったのを確認 → switch。

### nvim: Markdown プレビュー(glow.nvim + markview.nvim)追加 — 2026-07-09
- 目的: ターミナルの `glow` と同様の簡易 Markdown プレビューを Neovim でも行いたい。
- 両方導入(`modules/editors/nvim/plugins.nix`):
  - `plugins.glow.enable`: glow.nvim。`glow` バイナリ(packages.nix 既存)を呼びフローティングでレンダー。`:Glow`。
  - `plugins.markview.enable`: markview.nvim(v28.3.0)。バッファ内ライブ整形表示。md filetype で自動レンダー。
- キーマップ(`modules/editors/nvim/keymaps.nix`):
  - `<leader>mp` = `:Glow`(glow プレビュー)
  - `<leader>mt` = `:Markview toggle`(現在バッファの整形表示トグル)
- 確認: nixvim に `plugins.glow` / `plugins.markview` option が実在することを reference manpage で確認。`eval` 成功。
  markview のサブコマンドは commands.lua 実物を確認(`toggle`=現在バッファ / `Toggle`=全バッファ、`Start/Stop`=全体)。
  未検証: switch 後の実表示・キー動作。`:Glow` は glow.nvim 標準コマンド。

### nvim-tree: フォーカス追従 + git ステージング表示のリアルタイム化 — 2026-07-09
- 問題1: ファイルツリーの git ステージング状況がリアルタイム反映されない時がある。
- 問題2: ctrl-o 等で別バッファへ移動してもツリー上の現在ファイルのフォーカス表示が追従しない。
- 原因(実プラグイン確認):
  - 問題2: nvim-tree `update_focused_file.enable` の既定が **false**(config.lua:168)。
  - 問題1: `filesystem_watchers.enable` は既定 true でワークツリー変更は拾うが、`git add`(index のみ変更)は
    ツリーの fs watcher に届かない。gitsigns は `.git` を監視し staging/commit/外部 index 変更で
    `User GitSignsUpdate` を発火する(status.lua の autocmd_update)ことを確認。
- 対応(`modules/editors/nvim/plugins.nix`):
  - `settings.update_focused_file = { enable = true; update_root.enable = false; }`(追従するがルートは変えない)。
  - extraConfigLua に autocmd 追加: `User GitSignsUpdate` を 250ms デバウンスで拾い、ツリー表示中のみ
    `require("nvim-tree.api").tree.reload()`(API 実在を _meta で確認)。編集中の頻発を timer で抑制。
- 残る制約: gitsigns 未アタッチ(=nvim で開いていない)ファイルを外部で stage した場合はイベントが飛ばないため、
  そのファイル行は次のトリガ(別更新/手動 R)まで更新されない。開いているファイルの staging・commit・ブランチ変更は反映。
- 検証: `eval`/実 `nix build activationPackage` 成功。生成 init.lua に
  `update_focused_file = { enable = true, update_root = { enable = false } }` と GitSignsUpdate autocmd が入ることを確認。
  未検証: switch 後の実挙動。

### nvim: hunk.nvim(差分分割エディタ)導入 — 2026-07-10
- `plugins.hunk.enable`(nixvim, `modules/editors/nvim/plugins.nix`)。hunk.nvim v1.10.0(julienvincent/hunk.nvim)。
  `:DiffEditor <left> <right> [output]` で left/right ディレクトリ差分を file/hunk/line 単位に選択し部分 diff を作る。
  主に jujutsu(jj)/git の diff-editor・difftool として nvim を起動して使う想定(単体では :DiffEditor 待ち)。
- 必須依存 nui.nvim は nixvim の plugins.hunk が自動追加しないため `extraPlugins` に `nui-nvim` を明示追加。
  任意依存の web-devicons は plugins.web-devicons で導入済み。setup は既定(`require("hunk").setup({})`)。
- 検証: nixvim に `plugins.hunk`(settings 有)・`vimPlugins.hunk-nvim`/`nui-nvim` 実在を確認。`eval`/実ビルド成功、
  生成 init.lua に `require("hunk").setup({})` を確認。
- git difftool 連携(ユーザー選択: git)を `modules/core/git.nix` の `programs.git.settings` に追加:
  - `[difftool "hunk"] cmd = nvim -c "DiffEditor $LOCAL $REMOTE"`(dir-diff が渡す $LOCAL/$REMOTE の2ディレクトリを
    :DiffEditor に渡す。output 省略=right 側)、`[difftool] prompt = false`、alias `dh = difftool --dir-diff --tool=hunk`。
  - 使い方: `git dh [<commit>] [-- <path>...]`(例 `git dh HEAD`)。
  - 不具合修正: 初版 `git dh` で全ファイルが新規/差分無しに化けた。原因は dir-diff が working tree 側(right)を
    **symlink** で作り、hunk.nvim が symlink を差分対象にしない実装(`fs.scan_dir` が link 判定 → `diff.diff_file` が
    `left.symlink or right.symlink` で空 return)だったため。`difftool.symlinks=false`(config)は本環境で効かず、
    **`--no-symlinks` フラグ**で実ファイルコピーになることを検証(`ls -l` で right が regular file 化を確認)→ alias に固定。
  - 注意: dir-diff は accept した編集結果を working tree に書き戻し得る(hunk はステージング機構ではなく差分ビューア/エディタ)。
  - 検証: 生成 git config に `[difftool "hunk"] cmd = "nvim -c \"DiffEditor $LOCAL $REMOTE\""` と alias を確認(eval 成功)。
  - README には jj 連携のみ記載(git は非公式)。jj を使い始めたら `ui.diff-editor = ["nvim","-c","DiffEditor $left $right $output"]`。

### nvim: gitsigns preview が出ない件の診断 + HEAD 基準キー追加 — 2026-07-10
- 症状: `<leader>hp`(Gitsigns preview_hunk)が何も出ない。
- 診断(確証): 原因はプラグインでなく「変更が全部ステージ済み」。gitsigns は既定で working tree vs index を
  比較するため、full staged だと未ステージ hunk が 0 → preview 対象なし。実測: staged のみ→hunks=0、
  同ファイルに unstaged 変更を足す→hunks=1(ヘッドレス `gitsigns.get_hunks` で確認)。自動ステージ hook は無し
  (claude の hook は PreToolUse ガードのみ)= 手動 `git add` 運用による。
- 対応(`modules/editors/nvim/keymaps.nix`): 既定(index 基準)の `<leader>hp` は維持し、HEAD 基準を別キーに追加。
  - `<leader>hd` = `:Gitsigns diffthis HEAD`(そのファイルの HEAD との差分ビュー=ステージ済みも含む全変更)。
  - preview_hunk は base=index 固定でフロート、HEAD 基準の hunk フロートは gitsigns 仕様上クリーンに作れないため
    diffthis(split diff)を採用。
- 検証: `eval`/実ビルド成功、生成 init.lua に preview_hunk と diffthis HEAD の両 keymap を確認。

### CLI: modem-dev/hunk(ターミナル差分ビューア)を flake input で導入 — 2026-07-10
- ※ julienvincent/hunk.nvim(nvim プラグイン)とは別物。TypeScript/bun 製の CLI 差分ビューア(バイナリ `hunk`、
  npm 名 `hunkdiff`)。git/jj/sapling 対応、agent 生成 changeset のレビュー向け。
- 導入方法(ユーザー選択): Nix flake input(zenn-cli と同じ流儀)。
  - `flake.nix`: input `hunk = { url = "github:modem-dev/hunk"; inputs.nixpkgs.follows = "nixpkgs"; }` 追加、
    outputs 引数に `hunk`、`import ./overlays { inherit nix-zenn-cli hunk; }`。
  - `overlays/default.nix`: 引数 `{ nix-zenn-cli, hunk }`、`hunk = hunk.packages.${system}.default`。
  - `modules/core/packages.nix`: `home.packages` に `hunk` 追加。
- ビルド: bun2nix ビルド。`nix flake lock` で hunk/bun2nix 等を lock(`hunk/nixpkgs follows nixpkgs`)。
  実ビルド成功(`hunkdiff-0.17.0`)、`bin/hunk --version` → 0.17.0 を確認。全体 eval 成功。
- 命名衝突なし(hunk.nvim はプラグインで CLI 無し)。

### herdr: タブ移動に prefix+h/l を追加 — 2026-07-13
- 要望: prefix+h/l をタブ移動に追加(vim の左右=前/次)。
- `modules/shell/herdr.nix`: `next_tab` に `prefix+l`、`previous_tab` に `prefix+h` を追加。
  結果 next_tab=[n,j,l] / previous_tab=[p,k,h]。prefix+h/l は未バインドだったので衝突なし
  (ペインフォーカスは prefix+方向キー、ctrl+hjkl は vim-herdr-navigation のまま)。
- 検証: parse・生成 config.toml を tomllib で確認(next_tab/previous_tab の配列反映)。

### nixpkgs 更新 → herdr 0.7.3 + hunk の x86_64-darwin 対応 — 2026-07-13
- `nix flake update nixpkgs`(→ 2026-07-12 rev 3b32825)で herdr が 0.7.1 → **0.7.3** に(2026-07-09 保留分を解消)。
- 副作用: nixpkgs unstable が **26.11 で x86_64-darwin サポートを削除**。`hunk` 入力(bun2nix ビルドは flake-parts で
  全 system を評価する)が x86_64-darwin を評価しようとして eval エラー(work/linux/darwin 全滅)。
  ※ 当リポジトリ自体は x86_64-darwin を対象にしていない(profiles は x86_64-linux/aarch64-darwin)。エラー源は hunk 側。
- 対応(`flake.nix`): メイン nixpkgs は最新のまま、**hunk のビルド用 nixpkgs だけ**を x86_64-darwin をまだ含む
  rev(c4013e50, 2026-07-05 = 前回 hunk がビルドできた版)に固定。`nixpkgs-hunk` 入力を追加し
  `hunk.inputs.nixpkgs.follows = "nixpkgs-hunk"`(bun2nix は hunk の nixpkgs を follows するので連鎖して解決)。
  将来 upstream が systems から x86_64-darwin を外したら follows を "nixpkgs" に戻してよい。
- 検証: `nix flake lock` で `nixpkgs-hunk` 追加・`hunk/nixpkgs → nixpkgs-hunk` 確認。
  herdr=0.7.3、hunk=hunkdiff-0.17.0、work/linux/darwin 3profile とも activation eval 成功
  (残る "26.05...x86_64-darwin" は非推奨警告でエラーではない)。
- switch エラー: nixvim の doc(manpage)ビルドが `pandoc has been compiled without Lua support` で失敗。
  原因は nixpkgs だけ更新し nixvim/home-manager を古い rev のままにしたことで、新 nixpkgs の pandoc と不整合。
  対応: `nix flake update nixvim home-manager`(両者 2026-07-12 rev へ)。nixvim パッケージの実ビルド成功で解消を確認
  (`config.programs.nixvim.build.package` → nixvim.drv がビルド完了)。
- 未実施: switch 実行(nixpkgs bump で広範なリビルドあり)。

### dev: scala-cli 追加 — 2026-07-13
- `modules/dev/langs.nix` の home.packages に `scala-cli`(1.15.0)追加。単発 Scala スクリプト/worksheet(.sc)/
  scala-cli ビルドの実行用。sbt プロジェクトには必須でないが、Metals の worksheet/標準ファイル処理でも使われる。
- 補足: 「legacyPackages.<system>.scala-cli」の legacy は非推奨の意味ではなく、flake が nixpkgs 全体を公開する
  出力名(従来の pkgs 集合)というだけ。scala-cli 1.15.0 は現行版。
- 衝突確認: scala-cli の bin は `scala-cli` のみで、既存(sbt/coursier/jdk17/metals)と重複なし → home.packages collision 無し。
  キャッシュ済み(cache.nixos.org から substitute、ローカルビルド不要)。eval 成功。

### dev: md2pdf(Markdown→PDF)を overlay 経由で導入 — 2026-07-13
- nixpkgs の `md2pdf`(jmaupetit/md2pdf 3.1.1, Python/weasyprint 系)。`md2pdf -i in.md -o out.pdf`。
- 問題: 依存 weasyprint 69.0 が aarch64-darwin で描画テスト `tests/draw/test_text.py::test_unicode_range` に
  失敗しビルド不能(darwin はキャッシュ無しでソースビルド→checkPhase で落ちる)。
- 対応(`overlays/default.nix`): weasyprint の test だけ無効化した python セットで md2pdf を再ビルド。
  `md2pdf = prev.md2pdf.override { python3Packages = final.python3Packages.overrideScope (_: pp: { weasyprint = pp.weasyprint.overridePythonAttrs (_: { doCheck = false; }); }); };`
  `modules/core/packages.nix` の home.packages に `md2pdf` 追加。
- 検証: overlay 経由でビルド成功、実変換で有効な PDF 生成を確認(`/tmp/*.md` → PDF v1.7, 3867 bytes)。
  実行時に `Fontconfig error` が出て、**日本語(CJK)が豆腐**になる問題があった。
- 日本語対応(追加パッチ): weasyprint は fontconfig でフォント解決するが、既定では fontconfig 設定/CJK フォントが
  無いため日本語が出ない。`makeFontsConf { fontDirectories = [ noto-fonts-cjk-sans ]; }` で fontconfig を生成し、
  `symlinkJoin` + `wrapProgram --set FONTCONFIG_FILE` で md2pdf をラップ(overlay 内で weasyprint パッチと合成)。
  検証: 日本語 md → PDF 生成で Fontconfig エラー消失・サイズ 3.8KB→32.6KB(CJK グリフ埋め込み)を確認。
  (テキスト抽出は CJK サブセットの ToUnicode 欠如で空になりがちなので、エラー消失＋サイズ増で判定)。

### nvim: .sc(Scala worksheet/スクリプト)で Metals を standalone 起動 — 2026-07-14
- 要望: `xxx.sc` を開いたとき、適当なプロファイルで Scala LSP(Metals)が動くように。
- 現状確認: `.sc` は nvim が既に `scala` filetype として検出(filetype 追加不要)。不足は「プロジェクトマーカー
  (build.sbt/.scala-build/project)が無い単体 `.sc` では `find_scala_project_root` が nil → Metals 未起動」。
- 対応(`modules/editors/nvim/scala.nix`): FileType コールバックで、root が見つからず かつ bufname が `%.sc$` なら
  ファイルのディレクトリを root_dir にして `initialize_or_attach`(standalone)。`.scala/.sbt/.java` は従来通り
  プロジェクト外では起動しない。単体 Scala は Metals が scala-cli 経由で処理(scala-cli 導入済み)。
- 検証: eval・nixvim 実ビルド成功、生成 init.lua に `bufname:match("%.sc$") → root_dir = vim.fs.dirname(bufname)` を確認。
  実起動(Metals standalone の補完/診断)は switch 後に確認。初回は Metals/scala-cli の準備でやや時間がかかる。
  特定 Scala 版が必要な worksheet は先頭に `//> using scala "2.13.x"` 等を書けばよい(既定は Metals/scala-cli 標準版)。

### claude: settings.json の Write ルールを Edit へ移行 — 2026-07-16
- 症状: Claude 起動時に警告 3件。`Write(path)` 形式の permission ルールはファイル権限チェックで無視され、
  `Edit(path)` ルールのみが全ファイル編集ツール(Write 含む)に適用されるという Claude Code の仕様。
- 対応(Nix 管理元 `dotfiles/claude/settings.json`): allow の `Write(/tmp/**)` を削除(同義の `Edit(/tmp/**)` が既存)、
  deny の `Write(.env*)`→`Edit(.env*)`、`Write(**/secrets/**)`→`Edit(**/secrets/**)` に置換。
  ※ 反映元は `~/.claude/settings.json` 直編集ではなく `modules/core/claude.nix` の activation マージ経由。
- 反映: `home-manager switch` 後に Claude 再起動で警告が消える。

### core: nh(Nix CLI ヘルパー)を programs.nh で導入 — 2026-07-16
- nh 4.4.1(nixpkgs 収録、overlay/flake input 不要)。`nh home switch` の TUI+差分表示、`nh clean` の GC、`nh search`。
- 方式(ユーザー選択): `programs.nh` HM モジュール(`modules/core/nh.nix` 新規、`core/default.nix` に import)。
  home.packages に足すだけの方式では自動 GC が付けられない(systemd/launchd を手書きになる)ため、clean 有効化に伴いモジュール採用。
- 設定: `flake = "${config.home.homeDirectory}/src/github-private.com/t0m0h1de/nix-config"`(NH_FLAKE。ghq 配置前提の絶対パス)、
  `clean = { enable = true; dates = "weekly"; extraArgs = "--keep 5 --keep-since 7d"; }`。
- モジュール実装確認(`home-manager/modules/programs/nh.nix`): clean は Linux=systemd user timer / macOS=launchd agent を自動選択。
  → メインの mac(work/aarch64-darwin)でも launchd で自動 GC が動く。
- 検証: `nixpkgs-fmt`(整形なし)、work/linux/darwin 3profile とも `nix eval activationPackage.drvPath` 成功。
  生成物確認: work の `NH_FLAKE` が repo 絶対パス、work launchd `nh-clean` の ProgramArguments、
  linux systemd `nh-clean` ExecStart がいずれも `nh clean user --keep 5 --keep-since 7d` を含むことを確認。
  新規 `nh.nix` は `git add -N` しないと flake から未追跡で見えず eval 失敗する点に注意(intent-to-add 済み)。
- 未実施: switch 実行後の `nh --version` / `nh home switch -c work` の実挙動確認。
- README 反映: home-manager コマンドの操作は残しつつ、各所に nh の代替を併記。
  「設定の変更」に `nh home switch -c <profile>`(NH_FLAKE 設定済みで --flake 省略可、初回のみ home-manager 必要)、
  「パッケージの更新」に同置換メモ、新規「世代の掃除(GC)」節(`nh clean all` + 自動 GC の説明)、
  「パッケージを探す」に `nh search` を追記。

## Next
- Run `home-manager switch --flake .#<profile>` + `herdr server reload-config`, then verify `prefix+s` / `prefix+a` open a floating popup (not a split pane) and that `enter:become(... focus ...)` still switches focus correctly from inside the popup.
- Run `home-manager switch --flake .#darwin` and verify `~/.nix-profile/bin/roots` exists.
- Run `roots --help` (or `roots --version`) after switch.
- Run `home-manager switch --flake .#<profile>` and verify `roots --version` (or `roots --help`).
- Run `home-manager switch --flake .#<profile>` and verify `zenn --version`.
- Run `home-manager switch --flake .#<profile>` and verify `java -version` shows JDK 17.
- Run `home-manager switch --flake .#<profile>` and verify `echo $JAVA_HOME` points to `${pkgs.jdk17}/lib/openjdk`.
- Run `home-manager switch --flake .#<profile>` and verify `nvim-metals` welcome/install warnings are gone when opening Scala files.
- Run `home-manager switch --flake .#<profile>` and verify `cs --help` works.
- Run `:MetalsInstall` once if `nvim-metals` still reports missing Metals after Coursier is available.
- Run `home-manager switch --flake .#<profile>` and verify plain `nvim-metals` workflow: open Scala project file, wait for Metals attach, then run `:MetalsImportBuild`.
- Run `home-manager switch --flake .#<profile>` and verify `sbt` is available in shell (`sbt --version`).
- Run `home-manager switch --flake .#<profile>` and verify `nvim-metals` attaches for `scala`/`sbt`/`java` only when `build.sbt`, `.scala-build`, or `project/` exists in the project root.
- Run `home-manager switch --flake .#<profile>` and verify `nvim-metals` commands (`:MetalsImportBuild`, `:MetalsDoctor`) from a Scala workspace.
- Run `home-manager switch --flake .#<profile>` and verify `<leader>fo` opens `oil.nvim` for the current file directory.
- Run `home-manager switch --flake .#<profile>` and verify Scala editing no longer reindents on `=>` input.
- Run `home-manager switch --flake .#<profile>` and verify Scala editing no longer reindents on `case` input.
- Run `home-manager switch --flake .#<profile>` and verify `cd-nav` shows root-relative paths for both `cd-nav` and `cd-nav <path>`.
- Run `home-manager switch --flake .#<profile>` and verify zsh plugin behavior without Sheldon.
- Verify zsh directory navigation behavior after switch (`Ctrl + g` for ghq repos, `c` for normal directory navigation).
- Verify `cd-nav <path>` interactive selection starts from the provided root.

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
