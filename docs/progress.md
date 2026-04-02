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

## Next
- Add back only the Neovim features that are actually missed, one by one, through `nixvim`.

## Notes
- The new setup intentionally starts from a near-blank Neovim so it is easier to rebuild gradually.
- There is an unrelated existing evaluation warning about `programs.zsh.initExtra` being deprecated in favor of `programs.zsh.initContent`.
