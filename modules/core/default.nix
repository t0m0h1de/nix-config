{ ... }:
{
  imports = [
    ./common.nix
    ./ca-certs.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./claude.nix
    ./antigravity.nix
    ./codex.nix
    ./nh.nix
  ];
}
