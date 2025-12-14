{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    argocd
    openshift
    tektoncd-cli
  ];
}
