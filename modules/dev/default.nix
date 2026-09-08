{ ... }:
{
  imports = [
    ./docker.nix
    ./gcloud.nix
    ./k8s.nix
    ./langs.nix
    ./opentofu.nix
  ];
}
