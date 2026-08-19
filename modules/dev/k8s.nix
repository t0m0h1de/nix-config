{ pkgs, ... }:
{
  home.file.".kube/kubie.yaml".text = ''
    behavior:
      selector: fzf
  '';

  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      ps."ansible-core"
      kubernetes
      openshift
      pyyaml
    ]))
    kubectl
    kustomize # 以前は gcloud SDK 同梱版が PATH に居た(modules/dev/gcloud.nix の移行で単体化)
    kubie
    kubernetes-helm
    argocd
    openshift
    tektoncd-cli
  ];
}
