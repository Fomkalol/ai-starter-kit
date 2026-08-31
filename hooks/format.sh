#!/usr/bin/env bash
# PostToolUse(Edit|Write): автоформат изменённого файла. Никогда не блокирует.
input=$(cat)
file=$(printf '%s' "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

dir=$(dirname "$file")
# ищем локальный prettier вверх по дереву проекта
find_prettier() {
  local d="$1"
  while [ "$d" != "/" ]; do
    [ -x "$d/node_modules/.bin/prettier" ] && { echo "$d/node_modules/.bin/prettier"; return; }
    d=$(dirname "$d")
  done
}

case "$file" in
  *.go)
    command -v gofmt >/dev/null && gofmt -w "$file" 2>/dev/null ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md|*.html|*.yml|*.yaml)
    p=$(find_prettier "$dir")
    [ -n "$p" ] && "$p" --write "$file" >/dev/null 2>&1 ;;
esac
exit 0
