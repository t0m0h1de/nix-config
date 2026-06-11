{ nix-zenn-cli }:
final: prev:
{
  zenn-cli = nix-zenn-cli.packages.${final.system}.default;

  kube-tmux = final.stdenv.mkDerivation {
    pname = "kube-tmux";
    version = "unstable";
    src = final.fetchFromGitHub {
      owner = "jonmosco";
      repo = "kube-tmux";
      rev = "master";
      hash = "sha256-l1wjg2ReWKCI7h/K11vvX2ykYTs/mVD+tfz/mQsjn/E=";
    };
    installPhase = ''
      install -Dm755 kube.tmux $out/bin/kube.tmux
    '';
  };

  gwq = final.buildGoModule rec {
    pname = "gwq";
    version = "0.1.1";
    subPackages = [ "cmd/gwq" ];

    src = final.fetchFromGitHub {
      owner = "d-kuro";
      repo = "gwq";
      rev = "v${version}";
      hash = "sha256-MfCYFbODWnfPxx+6sLlcMT6tqghgILHB13+ccYqVjBA=";
    };

    vendorHash = "sha256-4K01Xf1EXl/NVX1loQ76l1bW8QglBAQdvlZSo7J4NPI=";

    meta = with prev.lib; {
      description = "Git worktree manager inspired by ghq";
      homepage = "https://github.com/d-kuro/gwq";
      license = licenses.mit;
      mainProgram = "gwq";
    };
  };

  roots = final.buildGoModule rec {
    pname = "roots";
    version = "0.4.1";
    subPackages = [ "." ];

    src = final.fetchFromGitHub {
      owner = "k1LoW";
      repo = "roots";
      rev = "v${version}";
      hash = "sha256-ACMRfWY/lhc3C/KVhuUyS1rgkSHGWPxZrmYt+pXupJI=";
    };

    vendorHash = "sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=";

    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
    ];

    meta = with prev.lib; {
      description = "Git worktree utility for handling root repositories";
      homepage = "https://github.com/k1LoW/roots";
      license = licenses.mit;
      mainProgram = "roots";
    };
  };
}
