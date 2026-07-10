{ nix-zenn-cli, hunk }:
final: prev:
{
  zenn-cli = nix-zenn-cli.packages.${final.stdenv.hostPlatform.system}.default;

  # modem-dev/hunk のターミナル差分ビューア CLI(独自 flake の default パッケージ、バイナリ hunk)。
  hunk = hunk.packages.${final.stdenv.hostPlatform.system}.default;

  terragrunt = final.buildGoModule rec {
    pname = "terragrunt";
    version = "0.99.5";

    # テスト用サブパッケージのビルドを避け、メインバイナリのみをビルドする。
    subPackages = [ "." ];

    src = final.fetchFromGitHub {
      owner = "gruntwork-io";
      repo = "terragrunt";
      rev = "v${version}";
      hash = "sha256-VlJRuW8TAlwszp2GzVC/7FY1jhq/7NHi/i5xPnw1nec=";
    };

    vendorHash = "sha256-wOCiZ4/fiKmdXcKS+AXLld1oMZzjbHBZWfxoFgJ5/to=";

    # テストはネットワーク/クラウド資格情報を要求するためスキップする。
    doCheck = false;

    ldflags = [
      "-s"
      "-w"
      "-X github.com/gruntwork-io/go-commons/version.Version=v${version}"
    ];

    meta = with prev.lib; {
      description = "Thin wrapper for Terraform/OpenTofu for keeping configurations DRY";
      homepage = "https://github.com/gruntwork-io/terragrunt";
      license = licenses.mit;
      mainProgram = "terragrunt";
    };
  };

  kube-tmux = final.stdenv.mkDerivation {
    pname = "kube-tmux";
    version = "unstable";
    # 再現性のため master ではなくコミットを固定する。
    src = final.fetchFromGitHub {
      owner = "jonmosco";
      repo = "kube-tmux";
      rev = "8b7e1d127c16b6dc87ff5743f4d775b245198b69";
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

  # Datadog CLI (pup)。Rust製・nixpkgs 未収録のため、リリースのプリビルドバイナリを
  # system 別に取得して配置する(大きな Rust CLI なのでソースビルドを避ける)。
  # darwin バイナリは system framework のみ依存で単体実行可。linux は autoPatchelfHook で張替え。
  pup =
    let
      version = "1.6.2";
      selection = {
        aarch64-darwin = { suffix = "Darwin_arm64"; hash = "sha256-er8nzA57pJbr667eWDdmWUC2nThWBor4lntnkGh/pvY="; };
        x86_64-darwin = { suffix = "Darwin_x86_64"; hash = "sha256-dME8Xqby+BWVn3Go5WHEUTpuYOINvcCNMdCe0ILstEI="; };
        x86_64-linux = { suffix = "Linux_x86_64"; hash = "sha256-7lAsWzx7PVZywOraiP25Y4+LgISfuP+6ai3p250pVy8="; };
        aarch64-linux = { suffix = "Linux_arm64"; hash = "sha256-ADRtVg+3Eb0f3aU01bIQDe2Bae/1nnFsI1FVv3AcdvI="; };
      };
      sel = selection.${final.stdenv.hostPlatform.system}
        or (throw "pup: unsupported system ${final.stdenv.hostPlatform.system}");
    in
    final.stdenvNoCC.mkDerivation {
      pname = "pup";
      inherit version;

      src = final.fetchurl {
        url = "https://github.com/DataDog/pup/releases/download/v${version}/pup_${version}_${sel.suffix}.tar.gz";
        inherit (sel) hash;
      };

      sourceRoot = ".";

      nativeBuildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];
      buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.stdenv.cc.cc.lib ];

      installPhase = ''
        runHook preInstall
        install -Dm755 pup $out/bin/pup
        runHook postInstall
      '';

      meta = with prev.lib; {
        description = "Datadog CLI companion with 200+ commands across Datadog products";
        homepage = "https://github.com/DataDog/pup";
        license = licenses.asl20;
        mainProgram = "pup";
        platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      };
    };
}
