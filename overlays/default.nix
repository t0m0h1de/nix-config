{ nix-zenn-cli, hunk }:
final: prev:
{
  zenn-cli = nix-zenn-cli.packages.${final.stdenv.hostPlatform.system}.default;

  # modem-dev/hunk のターミナル差分ビューア CLI(独自 flake の default パッケージ、バイナリ hunk)。
  hunk = hunk.packages.${final.stdenv.hostPlatform.system}.default;

  # ここから下の自前パッケージは .github/workflows/update.yml が定期的に bump PR を作る。
  # nix-update で更新するもの(roots / kube-tmux / vim-herdr-navigation)は version・rev・hash を
  # このファイルに直書きし、専用スクリプトで更新するもの(pup / terminal-browser)は
  # overlays/sources/*.json に切り出している(scripts/update/ 参照)。

  kube-tmux = final.stdenv.mkDerivation {
    pname = "kube-tmux";
    version = "0-unstable-2026-05-25";
    # 再現性のため master ではなくコミットを固定する(nix-update --version=branch で更新)。
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

  # vim-herdr-navigation: Ctrl+h/j/k/l で herdr ペインと Vim/Neovim split をシームレスに移動
  # する(vim-tmux-navigator の herdr 版)。herdr プラグインのソース一式で、modules/shell/herdr.nix が
  # activation で `herdr plugin link` する。
  #
  # navigate.sh の passthrough 既定を fzf に焼き込むパッチを当てている。
  # 上流は Ctrl+h/j/k/l を Vim/Neovim にしか転送せず、fzf 等の TUI 前面では herdr のペイン移動に
  # 消費されてしまう(→ fzf の選択移動 Ctrl+j/k が効かない)。env HERDR_NAV_PASSTHROUGH_RE で
  # opt-in できるが、herdr サーバへの env 継承は起動タイミング依存で不確実だったため、サーバが毎回
  # 実行する navigate.sh 自体の既定を fzf にする(env が設定されていればそちらが優先されるまま)。
  vim-herdr-navigation = final.stdenvNoCC.mkDerivation {
    pname = "vim-herdr-navigation";
    version = "0-unstable-2026-06-28";
    src = final.fetchFromGitHub {
      owner = "paulbkim-dev";
      repo = "vim-herdr-navigation";
      rev = "53e318c772c4d3b7fbd904ac43bcf3e5b5d8b244";
      hash = "sha256-vUUt46jiK6ZsPH8D13/+IIlqT3KbFliPJkNplsVqiQo=";
    };
    postPatch = ''
      substituteInPlace navigate.sh \
        --replace-fail 'passthrough_re="''${HERDR_NAV_PASSTHROUGH_RE:-}"' \
                       'passthrough_re="''${HERDR_NAV_PASSTHROUGH_RE:-fzf}"'
    '';
    dontBuild = true;
    installPhase = ''
      cp -r . $out
    '';
    # 上流のスクリプトをそのまま置く(shebang の書き換え等をしない)。
    dontFixup = true;
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
  # nixpkgs の `pup`(HTML パーサ)とは別物で、それを上書きしている。
  # darwin バイナリは system framework のみ依存で単体実行可。linux は autoPatchelfHook で張替え。
  # version / hash は overlays/sources/pup.json(scripts/update/pup.sh で更新)。
  pup =
    let
      source = prev.lib.importJSON ./sources/pup.json;
      inherit (source) version;
      sel = source.assets.${final.stdenv.hostPlatform.system}
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
        platforms = builtins.attrNames source.assets;
      };
    };

  # zenbu-labs/terminal-browser: ターミナル内で動く実ブラウザ(kitty graphics protocol を使って
  # Chromium のオフスクリーン描画をペインに表示する)。nixpkgs 未収録。
  # 配布形態が特殊: GitHub Releases にはタグだけで成果物が無く、実体は公式インストーラ
  # (`curl -fsSL https://terminal-browser.sh/install`)が参照する独自ドメインの tarball のみ。
  # 中身は Electron/Chromium 同梱(展開後 約300MB)なので、ソースからは組まずプリビルドを
  # そのまま配置する(pup と同じ方針)。上流は linux / x64 darwin 版も配布し始めたが、ここでは
  # 動作確認済みの Apple Silicon macOS 版だけを扱う。
  #
  # version / hash は overlays/sources/terminal-browser.json。scripts/update/terminal-browser.sh が
  # インストーラ先頭の VERSION と PLATFORMS 表(darwin-arm64 行の SHA256)から更新する。
  terminal-browser =
    let
      source = prev.lib.importJSON ./sources/terminal-browser.json;
      inherit (source) version;
    in
    final.stdenvNoCC.mkDerivation {
      pname = "terminal-browser";
      inherit version;

      src = final.fetchurl {
        url = "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-darwin-arm64.tar.gz";
        inherit (source) hash;
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
        platforms = [ "aarch64-darwin" ];
      };
    };

  # coder CLI。nixpkgs 版は postInstall で `coder` を terraform を PATH に足すラッパーにしているが、
  # terraform が要るのは `coder server`(ワークスペースのプロビジョニング)だけで、ここで使う
  # クライアント用途(`coder config-ssh` / `coder ssh` 等)には不要。terraform は unfree のため
  # cache.nixos.org に無く、依存に入っているだけで毎回ソースビルド(CI で約6分)になるので、
  # ラッパーを外して依存から落とす。
  coder = prev.coder.overrideAttrs (_: { postInstall = ""; });

  # md2pdf (jmaupetit/md2pdf, Markdown→PDF)。weasyprint は fontconfig でフォント解決するが、
  # 既定では fontconfig 設定/CJK フォントが無く日本語が豆腐になる。Noto Sans CJK を含む
  # fontconfig を生成し FONTCONFIG_FILE で渡して日本語対応する。
  # (以前は weasyprint のテスト失敗回避の override も当てていたが、nixpkgs 側で直りキャッシュに
  #  載ったため外した。)
  md2pdf =
    let
      fontsConf = final.makeFontsConf {
        fontDirectories = [ final.noto-fonts-cjk-sans ];
      };
    in
    final.symlinkJoin {
      inherit (prev.md2pdf) name;
      paths = [ prev.md2pdf ];
      nativeBuildInputs = [ final.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/md2pdf --set FONTCONFIG_FILE ${fontsConf}
      '';
    };
}
