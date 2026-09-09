#!/usr/bin/env bash
set -euo pipefail

# 把本仓库 skills/ 下的技能链接进各个 agent harness 的技能目录。
# 每个条目都是指向本仓库的符号链接，改了仓库内容即刻生效，不需要重装。
#
# 注意：~/.cc-switch/skills 由 cc-switch 应用管理，不要往那里写。
# bug-fix-flow 和 feature-flow 已于 2026-09-09 从 cc-switch 注销，
# 现在由本仓库直接管理这两个名字。

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

# 收集仓库里的技能，跳过不推广的桶。
names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -not -path '*/misc/*' -print0)

for DEST in "${DESTS[@]}"; do
  # 如果 DEST 本身是指向本仓库的符号链接，链接会写回仓库内部，检测到就退出。
  if [ -L "$DEST" ]; then
    resolved="$(cd "$DEST" 2>/dev/null && pwd -P || true)"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $DEST 是指向本仓库的符号链接 ($resolved)。" >&2
        echo "先删除它 (rm \"$DEST\") 再重跑，脚本会重新建为真实目录。" >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    target="$DEST/$name"

    # 已存在的真实目录不直接删，先备份，避免覆盖用户内容。
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      backup="$HOME/.cc-switch/skill-backups/$(date +%Y%m%d_%H%M%S)_${name}"
      mkdir -p "$backup"
      mv "$target" "$backup/skill"
      echo "backed up $target -> $backup/skill"
    fi

    ln -sfn "$src" "$target"
    echo "linked $name -> $src ($DEST)"
  done
done
