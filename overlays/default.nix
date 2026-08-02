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

  # zenbu-labs/terminal-browser: ターミナル内で動く実ブラウザ(kitty graphics protocol を使って
  # Chromium のオフスクリーン描画をペインに表示する)。nixpkgs 未収録。
  # 配布形態が特殊: GitHub Releases にはタグだけで成果物が無く、実体は公式インストーラ
  # (`curl -fsSL https://terminal-browser.sh/install`)が参照する独自ドメインの tarball のみ。
  # 中身は Electron/Chromium 同梱(展開後 約300MB)の Apple Silicon macOS 専用ビルドなので、
  # ソースからは組まずプリビルドをそのまま配置する(pup と同じ方針)。
  #
  # 更新手順: 上記インストーラを開くと先頭に DOWNLOAD_URL / VERSION / SHA256 が定数で書かれている。
  # その VERSION と SHA256 を下記に反映する(SHA256 は素の16進なので
  # `nix hash convert --hash-algo sha256 --to sri <SHA256>` で SRI へ変換して hash に入れる)。
  terminal-browser =
    let
      version = "0.3.3";
    in
    final.stdenvNoCC.mkDerivation {
      pname = "terminal-browser";
      inherit version;

      src = final.fetchurl {
        url = "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-darwin-arm64.tar.gz";
        hash = "sha256-gAQjGCeiscquAyL5mEgllp1xbtVTwtfM3HhNPPhH/Qk=";
      };

      sourceRoot = "terminal-browser";

      # 配布物の bin/terminal-browser は `dirname $0/..` で自分の配置先(ROOT)を求め、そこから
      # electron/ と cli/ を参照する。これをそのまま $out/bin に置くと home.packages 経由の
      # symlink(~/.nix-profile/bin/terminal-browser)から起動された時に ROOT が ~/.nix-profile と
      # 誤解決されて壊れる。そこで一式は libexec に置き、$out/bin には実体を絶対パスで exec する
      # だけの薄いラッパーを置く。
      # ※ makeWrapper は使えない: 生成されるラッパーが argv0 を保つ `exec -a "$0"` を使うため、
      #   上流スクリプトの `dirname $0` が結局 $out/bin を指してしまう。
      installPhase = ''
        runHook preInstall

        mkdir -p $out/libexec
        cp -R . $out/libexec/terminal-browser

        mkdir -p $out/bin
        cat > $out/bin/terminal-browser <<EOF
        #!/bin/sh
        exec "$out/libexec/terminal-browser/bin/terminal-browser" "\$@"
        EOF
        chmod +x $out/bin/terminal-browser

        runHook postInstall
      '';

      # 同梱の Electron は Apple の署名付きバイナリ。既定の fixupPhase(strip 等)を通すと署名が
      # 壊れ、Apple Silicon では起動できなくなるため無効化する。Nix 由来の依存も持たない。
      dontFixup = true;

      meta = with prev.lib; {
        description = "A browser that runs directly inside your existing terminal";
        homepage = "https://terminal-browser.com";
        license = licenses.mit;
        mainProgram = "terminal-browser";
        # 上流が Apple Silicon macOS 版しか配布していない(インストーラも他環境では即 exit する)。
        platforms = [ "aarch64-darwin" ];
      };
    };

  # md2pdf (jmaupetit/md2pdf, Markdown→PDF)。2点パッチ:
  #  1) 依存 weasyprint が aarch64-darwin で描画テスト(tests/draw/test_text.py::test_unicode_range)に
  #     失敗しビルド不能なため、weasyprint の test を無効化して通す。
  #  2) weasyprint は fontconfig でフォント解決するが、既定では fontconfig 設定/CJK フォントが無く
  #     日本語が豆腐になる。Noto Sans CJK を含む fontconfig を生成し FONTCONFIG_FILE で渡して日本語対応。
  md2pdf =
    let
      patched = prev.md2pdf.override {
        python3Packages = final.python3Packages.overrideScope (_: pyprev: {
          weasyprint = pyprev.weasyprint.overridePythonAttrs (_: { doCheck = false; });
        });
      };
      fontsConf = final.makeFontsConf {
        fontDirectories = [ final.noto-fonts-cjk-sans ];
      };
    in
    final.symlinkJoin {
      inherit (patched) name;
      paths = [ patched ];
      nativeBuildInputs = [ final.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/md2pdf --set FONTCONFIG_FILE ${fontsConf}
      '';
    };
}
