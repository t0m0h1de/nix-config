{ ... }:
let
  # Use quoted --bind payloads so fzf shell-integration option parsing
  # behaves consistently across widgets.
  modalEscBindOpt = "--bind='esc:ignore+rebind(i,j,k)+change-prompt(Nav> )'";
  fzfDefaultOpts = [
    "--prompt='Filter> '"
    "--bind='j:down'"
    "--bind='k:up'"
    "--bind='start:unbind(i,j,k)+change-prompt(Filter> )'"
    modalEscBindOpt
    "--bind='i:unbind(i,j,k)+change-prompt(Filter> )'"
  ];
in
{
  home.sessionVariables = {
    FZF_DEFAULT_OPTS = builtins.concatStringsSep " " fzfDefaultOpts;
    FZF_CTRL_R_OPTS = modalEscBindOpt;
    FZF_CTRL_T_OPTS = modalEscBindOpt;
    FZF_ALT_C_OPTS = modalEscBindOpt;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
