{ pkgs, ... }:
let
  # herdr-gc: herdr のペインを一覧から選んで、まとめて閉じる(手で動かす)。
  # 作業していたディレクトリが消えたペイン(✗)・シェルだけのペインを上に並べ、fzf で選ぶ(Tab で複数、Enter で決める)。
  # 右に、そのペインの今の画面を出す。このコマンドを打ったペインは候補に出さない。
  # herdr は Nix で入れていない(PATH にあるものを使う)。
  herdrGc = pkgs.writeShellApplication {
    name = "herdr-gc";
    runtimeInputs = with pkgs; [ coreutils jq fzf ];
    text = ''
      usage() {
        cat <<'EOF'
      使い方: herdr-gc
        herdr のペインを一覧から選んで、まとめて閉じる。
        並び: 作業していたディレクトリが消えたペイン(✗)、シェルだけのペイン、ほか の順。
        Tab で選び(複数)、Enter で決める。閉じる前にもう一度確かめる。
      EOF
      }
      case "''${1:-}" in
        -h | --help) usage; exit 0 ;;
        "") ;;
        *) usage >&2; exit 2 ;;
      esac
      command -v herdr >/dev/null || { echo "herdr が無い" >&2; exit 1; }

      self="''${HERDR_PANE_ID:-}"
      panes="$(herdr pane list)"
      tabs="$(herdr tab list)"
      workspaces="$(herdr workspace list)"

      # 1 行に 1 ペイン: 並びの重み \t ペイン \t ワークスペース \t タブ \t 中身 \t 状態 \t 場所
      rows="$(mktemp)"
      trap 'rm -f "$rows"' EXIT
      jq -r --argjson tabs "$tabs" --argjson ws "$workspaces" '
        ($tabs.result.tabs | map({(.tab_id): .label}) | add) as $t
        | ($ws.result.workspaces | map({(.workspace_id): .label}) | add) as $w
        | .result.panes[]
        | [.pane_id, ($w[.workspace_id] // .workspace_id), ($t[.tab_id] // .tab_id), (.agent // "-"),
           (.agent_status // "-"), (.cwd // "-"), (.terminal_title_stripped // "-")]
        | map(if . == "" then "-" else . end)
        | @tsv' <<<"$panes" |
        # 空の欄は「-」にしておく(read は続いたタブを 1 つに詰めるので、空の欄があると列がずれる)
        while IFS=$'\t' read -r id ws tab agent status cwd title; do
          [ "$id" = "$self" ] && continue
          [ "$cwd" = - ] && cwd=""
          what="$agent"
          if [ "$what" = - ]; then
            # Claude Code などが動いていなければ、前に出ているプロセスの名前(シェルならシェルだけ)
            # 一覧を取ってから消えたペインなどで失敗しても、止めない
            what="$({ herdr pane process-info --pane "$id" 2>/dev/null || echo '{}'; } | jq -r '.result.process_info.foreground_processes[0].name // "?"')"
          fi
          weight=3
          mark=" "
          if [ -n "$cwd" ] && [ ! -d "$cwd" ]; then
            weight=1
            mark="✗"
          elif [[ "$what" =~ ^-?(zsh|bash|fish|sh)$ ]]; then
            weight=2
            what="シェル"
          fi
          # 幅で切らない(日本語を途中で切ると壊れる)。表示の幅は fzf に任せる
          printf '%s\t%s\t%s\t%s\t%s\t%s\t%s %s\t%s\n' \
            "$weight" "$id" "$ws" "$tab" "$what" "$status" "$mark" "''${cwd/#$HOME/\~}" "$title"
        done | LC_ALL=C sort -t $'\t' -k1,1n -k3,3 >"$rows"

      [ -s "$rows" ] || { echo "閉じられるペインは無い"; exit 0; }

      picked="$(fzf --multi --delimiter=$'\t' --with-nth=3.. --tabstop=2 \
        --header=$'Tab で選ぶ(複数) / Enter で決める / Esc でやめる。✗ = 作業していたディレクトリが消えた' \
        --preview 'herdr pane read {2} --lines 60' --preview-window=right,50%,wrap <"$rows" || true)"
      [ -n "$picked" ] || { echo "何も閉じなかった"; exit 0; }

      echo "次の $(wc -l <<<"$picked" | tr -d ' ') 個のペインを閉じる:"
      cut -f3- <<<"$picked" | sed 's/^/  /'
      printf '閉じますか? [y/N] '
      read -r ans
      [ "$ans" = y ] || [ "$ans" = Y ] || { echo "何も閉じなかった"; exit 0; }

      closed=0
      while IFS=$'\t' read -r _ id _; do
        if herdr pane close "$id" >/dev/null; then
          closed=$((closed + 1))
        else
          echo "  !!! 閉じられなかった: $id" >&2
        fi
      done <<<"$picked"
      echo "$closed 個を閉じた"
    '';
  };
in
{
  home.packages = [ herdrGc ];
}
