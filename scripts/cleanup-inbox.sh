#!/usr/bin/env bash
#
# cleanup-inbox.sh — 列出（并可选清理）inbox/ 中超过保留期仍未归位的文件
#
# 用法：
#   ./scripts/cleanup-inbox.sh           # 只读检查，输出报告，不动任何文件
#   ./scripts/cleanup-inbox.sh --yes     # 按报告执行清理（仅处理已纳入 git 的文件）
#   DAYS=14 ./scripts/cleanup-inbox.sh   # 自定义保留天数，默认 30
#
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="$ROOT/inbox"
DAYS="${DAYS:-30}"
APPLY=0

for arg in "$@"; do
  case "$arg" in
    --yes|-y) APPLY=1 ;;
    -h|--help)
      echo "用法: $0 [--yes]"
      echo "  --yes   执行清理（默认只读检查）"
      echo "  DAYS=14 环境变量可调整保留天数"
      exit 0
      ;;
    *)
      echo "未知参数: $arg（--help 查看用法）" >&2
      exit 1
      ;;
  esac
done

if [ ! -d "$INBOX" ]; then
  echo "找不到 inbox 目录: $INBOX" >&2
  exit 1
fi

echo "inbox:   $INBOX"
echo "保留期:  $DAYS 天"
echo

files=()
while IFS= read -r f; do
  files+=("$f")
done < <(find "$INBOX" -type f -mtime +"$DAYS" ! -name '.gitkeep' ! -name 'README.md' | sort)

if [ "${#files[@]}" -eq 0 ]; then
  echo "没有逾期文件。inbox 是干净的。"
  exit 0
fi

echo "以下 ${#files[@]} 个文件超过 ${DAYS} 天未归位："
echo
for f in "${files[@]}"; do
  rel="${f#$ROOT/}"
  printf '  %-58s %s\n' "$rel" "$(date -r "$f" '+%Y-%m-%d')"
done
echo
echo "出栈方式：升级到 design/ 或 research/ · 归档到 archive/ · 直接删除"
echo

if [ "$APPLY" -eq 0 ]; then
  echo "当前为只读检查，未改动任何文件。确认清单无误后执行："
  echo "  $0 --yes"
  exit 0
fi

cd "$ROOT"
removed=0
skipped=0
for f in "${files[@]}"; do
  rel="${f#$ROOT/}"
  if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
    git rm -q "$rel"
    removed=$((removed + 1))
  else
    echo "跳过（未纳入 git，请手动处理）: $rel"
    skipped=$((skipped + 1))
  fi
done

echo "已清理 $removed 个文件。"
if [ "$skipped" -gt 0 ]; then
  echo "另有 $skipped 个未纳入 git 的文件被跳过。"
fi
echo "删除内容仍在 git 历史中，可用 git log --diff-filter=D --name-only 找回。"
