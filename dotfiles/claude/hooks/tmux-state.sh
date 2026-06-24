#!/usr/bin/env bash
# Claude Code の状態を tmux セッションのユーザーオプションに記録する。
#
# Claude の hook から呼ばれ、$TMUX_PANE から自分のセッションを特定して
# @claude_state(working/waiting/idle) と @claude_state_at(epoch秒) を set する。
# tmux のセッション一覧(prefix+s / tmux-fzf)でこの値をバッジ表示する。
#
# 引数: working | waiting | idle | clear
#   clear はオプションを unset してバッジを消す(セッション終了時など)。
#
# cf. https://github.com/craftzdog/tmux-claude-session-manager (scripts/state.sh)

state="${1:-idle}"

# tmux 外(=TMUX_PANE 無し)では何もしない
if [ -z "${TMUX_PANE:-}" ]; then
  exit 0
fi

# 自分のペインが属するセッション名を取得
session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null)
if [ -z "$session" ]; then
  exit 0
fi

if [ "$state" = "clear" ]; then
  tmux set-option -u -t "$session" @claude_state 2>/dev/null
  tmux set-option -u -t "$session" @claude_state_at 2>/dev/null
else
  tmux set-option -t "$session" @claude_state "$state"
  tmux set-option -t "$session" @claude_state_at "$(date +%s)"
fi
