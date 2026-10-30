{ lib, ... }:
{
  # 手元のスキルを、Claude Code・Codex・agy(Antigravity CLI)の 3 つで使えるようにする。
  #
  # スキル(<name>/SKILL.md)の中身は本リポジトリに置かない(会社のリポジトリ名などが入るため)。
  # ~/.config/agent-skills/<name>/ に置くか、非公開のリポジトリにある本体へのリンクを置く。
  # activation で、各ツールのスキルの置き場所に <name> へのリンクを張る:
  #   ~/.claude/skills/<name>   ~/.codex/skills/<name>   ~/.gemini/config/skills/<name>(agy)
  #
  # 既に同じ名前の実ディレクトリ(ツールで直接作ったスキル)がある場合は触らない。
  # ~/.config/agent-skills から消したスキルは、張ったリンクだけを外す(リンク先がここを指すものに限る)。
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="''${XDG_CONFIG_HOME:-$HOME/.config}/agent-skills"
    for dest in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.gemini/config/skills"; do
      if [ -d "$src" ]; then
        run mkdir -p "$dest"
        for skill in "$src"/*/; do
          [ -f "$skill/SKILL.md" ] || continue
          name="$(basename "$skill")"
          link="$dest/$name"
          if [ -e "$link" ] && [ ! -L "$link" ]; then
            echo "agent-skills: $link は実ディレクトリなので触らない" >&2
            continue
          fi
          run ln -sfn "$src/$name" "$link"
        done
      fi
      # 消したスキルのリンクを外す
      if [ -d "$dest" ]; then
        for link in "$dest"/*; do
          [ -L "$link" ] || continue
          case "$(readlink "$link")" in
            "$src"/*) [ -e "$link" ] || run rm -f "$link" ;;
          esac
        done
      fi
    done
  '';
}
