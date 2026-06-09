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
    kubie
    kubernetes-helm
    argocd
    openshift
    tektoncd-cli
  ];
}
