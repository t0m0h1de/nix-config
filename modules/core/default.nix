{ ... }:
{
  imports = [
    ./common.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./claude.nix
    ./antigravity.nix
    ./codex.nix
    ./nh.nix
  ];
}
