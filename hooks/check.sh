#!/usr/bin/env bash
# PostToolUse(Edit|Write): проверка изменённого файла — tsc для .ts/.tsx, go vet для .go.
# Ошибки уходят Клоду через exit 2 (stderr); чисто — молча exit 0.
# Отключить: export CLAUDE_NO_CHECK=1
[ -n "$CLAUDE_NO_CHECK" ] && exit 0

input=$(cat)
file=$(printf '%s' "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

find_up() { # find_up <start_dir> <filename> -> печатает каталог, где нашли
  local d="$1"
  while [ "$d" != "/" ]; do
    [ -e "$d/$2" ] && { echo "$d"; return; }
    d=$(dirname "$d")
  done
  return 1
}

case "$file" in
  *.ts|*.tsx)
    root=$(find_up "$(dirname "$file")" tsconfig.json) || exit 0
    tsc_bin="$root/node_modules/.bin/tsc"
    [ -x "$tsc_bin" ] || exit 0
    out_all=$(cd "$root" && "$tsc_bin" --noEmit --pretty false 2>&1); rc=$?
    out=$(printf '%s\n' "$out_all" | grep -F "${file#"$root"/}" | head -15)
    [ -z "$out" ] && [ "$rc" -ne 0 ] && out=$(printf '%s\n' "$out_all" | head -5)
    if [ -n "$out" ]; then
      echo "[check.sh] tsc: ошибки в $file:" >&2
      echo "$out" >&2
      exit 2
    fi
    ;;
  *.go)
    command -v go >/dev/null || exit 0
    find_up "$(dirname "$file")" go.mod >/dev/null || exit 0
    out_all=$(cd "$(dirname "$file")" && go vet ./ 2>&1); rc=$?
    out=$(printf '%s\n' "$out_all" | grep -v '^#' | head -15)
    [ -z "$out" ] && [ "$rc" -ne 0 ] && out=$(printf '%s\n' "$out_all" | head -5)
    if [ -n "$out" ]; then
      echo "[check.sh] go vet: проблемы в пакете $(dirname "$file"):" >&2
      echo "$out" >&2
      exit 2
    fi
    ;;
esac
exit 0
