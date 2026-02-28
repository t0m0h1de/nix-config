{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      ps."ansible-core"
      kubernetes
      openshift
      pyyaml
    ]))
    kubectl
    kubernetes-helm
    argocd
    openshift
    tektoncd-cli
  ];
}
