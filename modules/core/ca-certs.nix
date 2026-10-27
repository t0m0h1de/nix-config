{ pkgs, lib, ... }:
let
  inherit (pkgs) cacert;

  # cacert の ca-bundle.crt は、サーバー認証で信頼する証明書の通常の PEM ブロックに加えて、全証明書を
  # 用途ごとの信頼/拒否付きの "BEGIN TRUSTED CERTIFICATE" ブロックでも持つ。OpenSSL はこの拒否を守るが、
  # macOS 標準の LibreSSL(/usr/bin/python3 の pip など)は無視して信頼してしまい、侵害された中間 CA の
  # 上位ルート(サーバー認証で拒否されている Comodo AAA Services root)経由のチェーンを通していた。
  # 通常の PEM ブロックだけを抜き出し、どの TLS 実装からもサーバー認証で信頼するものしか見えないようにする。
  # 公表サイトの NixOS 向け手順で外すルート 2 つ(Comodo AAA Services root、emSign ECC Root CA - G3)も
  # これで含まれない(後者は 3.131.1 で収録から消えている)。
  #
  # ディレクトリにしているのは SSL_CERT_DIR にも使うため(下の SSL_CERT_DIR を参照)。
  caCerts = pkgs.runCommand "ca-certs-server-auth-${cacert.version}" { } ''
    mkdir $out
    awk '/^-----BEGIN CERTIFICATE-----$/ { p = 1 } p { print } /^-----END CERTIFICATE-----$/ { p = 0 }' \
      ${cacert}/etc/ssl/certs/ca-bundle.crt > $out/ca-bundle.crt
  '';
  caBundle = "${caCerts}/ca-bundle.crt";

  # Java 用の truststore。JDK は lib/security/cacerts を同梱していて OS や caBundle を見ないので、
  # caBundle から PKCS12 を作って差し替える。
  # パスワードは keytool の既定の changeit(公開の値で、秘匿情報ではない)。
  #
  # OpenJDK の 2026-10-24 のアドバイザリ(CVE-2026-114820、https://openjdk.org/emudhra)は、修正版の JDK が
  # 出るまで、次の 4 つのルートを Java の信頼ストアから外すよう案内している。NSS 3.131.1 でも G1 は残るので、
  # caBundle とは別に、Java 用からだけ外す(OS や他のツールは Mozilla の判断どおり G1 を信頼したまま)。
  # 判定用の CheckCerts.java(https://cr.openjdk.org/~mr/CheckCerts.java)が見るルートと同じ。
  javaExcludedRoots = [
    "emSign ECC Root CA - G3"
    "AAA Certificate Services"
    "emSign Root CA - G1"
    "emSign Root CA - G2"
  ];
  javaTrustStore = pkgs.runCommand "java-truststore-${cacert.version}"
    {
      nativeBuildInputs = [ pkgs.jdk17 pkgs.openssl ];
    } ''
    mkdir certs
    awk '/-----BEGIN CERTIFICATE-----/ { n++; p = 1 } p { print > ("certs/" n ".pem") } /-----END CERTIFICATE-----/ { p = 0 }' ${caBundle}
    for f in certs/*.pem; do
      subject=$(openssl x509 -noout -subject -nameopt RFC2253 -in $f)
      case "$subject" in
        ${lib.concatMapStringsSep " | " (cn: "*${lib.escapeShellArg "CN=${cn},"}*") javaExcludedRoots})
          echo "skip: $subject"
          continue
          ;;
      esac
      keytool -importcert -noprompt -storetype PKCS12 -keystore $out \
        -storepass changeit -alias "$(basename $f .pem)" -file $f > /dev/null
    done

    # 外したはずのルートが残っていたらビルドを落とす(CN の書き方が変わって素通りするのを防ぐ)
    keytool -list -v -storetype PKCS12 -keystore $out -storepass changeit > list.txt
    for cn in ${lib.escapeShellArgs javaExcludedRoots}; do
      if grep -q "CN=$cn," list.txt; then
        echo "truststore に $cn が残っている" >&2
        exit 1
      fi
    done
  '';
in
{
  # 独自の CA ストアを持つ Nix 以外の/古いランタイムも含め、CA の参照先を Home Manager の cacert に揃える。
  # きっかけは eMudhra 中間 CA 秘密鍵漏洩(2026-10-20 公表)で、修正前の CA ストアを使うものが
  # 侵害された中間 CA を信頼し続けていた(検証ホスト https://dv-g3b-emudhra.we-have-a-problem.com/)。
  # Linux もディストリの /etc/ssl/certs ではなくこちらに揃える。ディストリの更新を待たずに済む代わりに、
  # update-ca-certificates で足した独自 CA は見なくなるので、要るなら cacert.override の extraCertificateFiles に足す。
  home.sessionVariables = {
    # Nix の curl / git / openssl / python(certifi)が使う。未設定だと nix-daemon.sh が、macOS では
    # Nix インストール時の default プロファイルの nss-cacert(Home Manager で更新されず古くなる)を、
    # Linux ではディストリの /etc/ssl/certs/ca-certificates.crt を指す。
    # ~/.zshenv は /etc/zshrc より先に読まれ、nix-daemon.sh は設定済みの値を尊重するので、ここで指定すれば効く。
    NIX_SSL_CERT_FILE = caBundle;
    # Nix 以外の OpenSSL(mise の公式ビルドの node など)の既定の CA ファイル。下の --use-openssl-ca で必須。
    # Linux の Go 製ツールもこれを読む(macOS の Go は OS の検証機構を使うので、OS 側の対処で足りている)。
    SSL_CERT_FILE = caBundle;
    # SSL_CERT_FILE を指定しても、Linux の Go は /etc/ssl/certs と /etc/pki/tls/certs の中のファイルを全部、
    # OpenSSL は既定の CA ディレクトリを読み、ディストリが置いた個別の(修正前の)ルートを信頼してしまう。
    # caBundle だけがあるディレクトリに差し替える(OpenSSL はハッシュ名でないファイルを読まないので実質空)。
    SSL_CERT_DIR = "${caCerts}";

    # node は既定で自身に同梱した CA ストアを使い、修正前の版(yarn・pnpm・LSP などが使う nixpkgs の node、
    # mise の node)は侵害された中間 CA を信頼する。OpenSSL の CA(= 上の SSL_CERT_FILE)を使わせる。
    # SSL_CERT_FILE が無いと公式ビルドの node は CA が空になり、どこにも繋がらなくなる。
    NODE_OPTIONS = "--use-openssl-ca";

    # 全 JVM(sbt・metals・coursier・jbang など)に上の truststore を使わせる。
    # JVM の起動時に stderr へ "Picked up JAVA_TOOL_OPTIONS: ..." が出るのは仕様。
    JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=${javaTrustStore} -Djavax.net.ssl.trustStoreType=PKCS12 -Djavax.net.ssl.trustStorePassword=changeit";

    # gcloud / bq は certifi を同梱していて NIX_SSL_CERT_FILE を見ない。
    CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE = caBundle;

    # pip と requests は pip で入れた certifi(venv や macOS 標準の pip3 に同梱)を読み、SSL_CERT_FILE を見ない。
    PIP_CERT = caBundle;
    REQUESTS_CA_BUNDLE = caBundle;
    # grpcio(dbt-bigquery の BigQuery Storage Read API など)は同梱の roots.pem を読み、上のどれも見ない。
    GRPC_DEFAULT_SSL_ROOTS_FILE_PATH = caBundle;

    # macOS 標準の /usr/bin/git は SSL_CERT_FILE を見ない。Nix の git もこれに従う。
    GIT_SSL_CAINFO = caBundle;
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    # macOS 標準の LibreSSL(/usr/bin の curl・git・python3 など)は、CA ファイルでの検証に失敗すると
    # キーチェーンで検証し直し(TEA)、そちらが侵害された中間 CA を通してしまう。無効にして SSL_CERT_FILE だけで
    # 検証させる。シェルから起動したものにしか効かないので、/etc/ssl/cert.pem 自体の対処(要 sudo)は別に要る。
    OPENSSL_X509_TEA_DISABLE = "1";
  };
}
