#!/bin/sh
# Глубокое кросс-ревью PR/диффа второй моделью — по образцу пайплайна, который
# нашёл блокеры в stone-api PR#1: изолированные клоны, N параллельных «финдеров»
# с ПРАВОМ ЗАПУСКАТЬ КОД (workspace-write), адверсариальные скептики по каждому
# отчёту (тоже запуском), затем синтез. В отличие от review.sh: ревьюер обязан
# подтверждать утверждения исполнением (тесты, repro, замеры), а не чтением.
#
# Использование: из корня код-репо
#   sh review-deep.sh [база=main] [тема=deep]
# Опционально: DEEP_FINDERS=6 (число финдеров), DEEP_MODEL=gpt-5.6-sol,
#   DEEP_EFFORT=high, DEEP_SETUP="npm ci --omit=dev" (команда подготовки клона).
# Отчёт: out/reports/deep_review_<тема>_<head>.md (появляется только при успехе).
set -u
BASE="${1:-main}"; TOPIC=$(printf %s "${2:-deep}" | tr -c 'A-Za-z0-9._-' '-')
FINDERS="${DEEP_FINDERS:-6}"; MODEL="${DEEP_MODEL:-gpt-5.6-sol}"; EFFORT="${DEEP_EFFORT:-high}"
ROOT=$(git rev-parse --show-toplevel) || { echo "не git-репо"; exit 1; }
cd "$ROOT" || exit 1
HEAD_SHA=$(git rev-parse HEAD); BASE_SHA=$(git rev-parse "$BASE") || { echo "нет базы $BASE"; exit 1; }
MB=$(git merge-base "$BASE_SHA" HEAD) || { echo "нет merge-base"; exit 1; }
[ "$MB" = "$HEAD_SHA" ] && { echo "пустой дифф: HEAD == merge-base"; exit 2; }
SHORT=$(git rev-parse --short HEAD)
OUT_DIR="$ROOT/out/reports"; mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/deep_review_${TOPIC}_${SHORT}.md"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/deep-review-XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT
git diff "$MB..HEAD" > "$TMP/diff.patch" || exit 1
[ -s "$TMP/diff.patch" ] || { echo "пустой дифф"; exit 2; }
git log --oneline "$MB..HEAD" > "$TMP/commits.txt"

# Базовый клон + подготовка (зависимости); финдерам — дешёвые копии.
git clone -q --no-hardlinks "$ROOT" "$TMP/base" || exit 1
git -C "$TMP/base" checkout -q "$HEAD_SHA"
if [ -n "${DEEP_SETUP:-}" ]; then (cd "$TMP/base" && sh -c "$DEEP_SETUP" >/dev/null 2>&1); fi

ANGLES_1="Correctness and logic: off-by-one, inverted conditions, wrong defaults, schema/contract mismatches, broken edge cases. Run the unit tests of the project and write your own minimal repro scripts for each suspicion."
ANGLES_2="Concurrency, resources and lifecycle: races, leaked sockets/files/timers, missing timeouts and cancellation, shutdown ordering, retry storms. Prove hangs/leaks with small runnable repros."
ANGLES_3="Security and safety filters: adversarial inputs, injection, bypasses of any validation/sanitization in the diff (try many phrasings and encodings BY RUNNING the code), ReDoS (measure with long inputs and a timer), secrets in logs."
ANGLES_4="Performance: quadratic loops, repeated full-file rewrites, oversized allocations, needless decoding. MEASURE suspicious paths with node/python timers on realistic sizes; report numbers."
ANGLES_5="Cross-file contracts: trace call chains across files touched by the diff; log-line formats vs their parsers; env var names vs docs; JSON schemas vs consumers; config plumbed end-to-end. Verify by executing the involved functions together."
ANGLES_6="Operational failure modes: disk full/read-only/missing dirs, dependency errors, provider HTTP failures, process restart mid-operation, malformed persisted state. Simulate each with fault-injection scripts against the real modules."

i=1
while [ "$i" -le "$FINDERS" ]; do
  case "$i" in
    1) ANGLE="$ANGLES_1";; 2) ANGLE="$ANGLES_2";; 3) ANGLE="$ANGLES_3";;
    4) ANGLE="$ANGLES_4";; 5) ANGLE="$ANGLES_5";; 6) ANGLE="$ANGLES_6";;
    *) ANGLE="$ANGLES_1";;
  esac
  cp -Rc "$TMP/base" "$TMP/f$i" 2>/dev/null || cp -R "$TMP/base" "$TMP/f$i"
  cp "$TMP/diff.patch" "$TMP/commits.txt" "$TMP/f$i/"
  (
    codex exec -C "$TMP/f$i" -s workspace-write -m "$MODEL" -c model_reasoning_effort="$EFFORT" \
      -o "$TMP/finder$i.md" \
      "You are an independent code reviewer with FULL permission to run code in this working copy (a disposable clone; nothing you do here affects anything real). The change under review is diff.patch (commits: commits.txt) applied on top of this checkout — the checkout already contains the change.

Your dimension: $ANGLE

Rules:
- Never trust reasoning alone: every finding MUST be confirmed by executing something (a test, a repro script, a measurement) and you must include the exact command and observed output.
- Focus on the diff, but follow its consequences anywhere in the repo.
- Ignore style; report only defects that matter in production.
- Output format: for each finding a section '### FINDING <n> [P1|P2|P3] <title>' with: Where (file:line), What, Repro (command + output), Fix direction. If nothing found, write 'NO FINDINGS'." >/dev/null 2>&1
    echo "finder $i done"
  ) &
  i=$((i+1))
done
wait

# Скептики: опровергнуть findings соответствующего финдера, тоже запуском.
i=1
while [ "$i" -le "$FINDERS" ]; do
  if [ -s "$TMP/finder$i.md" ] && ! grep -q "NO FINDINGS" "$TMP/finder$i.md"; then
    cp -Rc "$TMP/base" "$TMP/s$i" 2>/dev/null || cp -R "$TMP/base" "$TMP/s$i"
    cp "$TMP/diff.patch" "$TMP/finder$i.md" "$TMP/s$i/"
    (
      codex exec -C "$TMP/s$i" -s workspace-write -m "$MODEL" -c model_reasoning_effort="$EFFORT" \
        -o "$TMP/skeptic$i.md" \
        "You are an adversarial verifier in a disposable clone with full permission to run code. finder$i.md contains findings from another reviewer about the change in diff.patch (already applied to this checkout). For EACH finding: try to REFUTE it by running the claimed repro yourself and probing the surrounding code. Verdict per finding: CONFIRMED (repro reproduces, impact as claimed), DOWNGRADED (real but lesser severity — explain), or REFUTED (with the run that disproves it). Include commands and outputs. Be strict: a finding whose repro you cannot reproduce is REFUTED." >/dev/null 2>&1
      echo "skeptic $i done"
    ) &
  fi
  i=$((i+1))
done
wait

# Синтез.
SYN="$TMP/syn"; mkdir -p "$SYN"; cp "$TMP"/finder*.md "$SYN"/ 2>/dev/null; cp "$TMP"/skeptic*.md "$SYN"/ 2>/dev/null
cp "$TMP/diff.patch" "$SYN/"
# --skip-git-repo-check: каталог синтеза (в отличие от клонов финдеров) не git-репо,
# без флага codex отказывается работать. </dev/null: иначе он ждёт ввода со stdin.
# Вывод больше не глушим целиком — при падении причина должна быть видна.
codex exec -C "$SYN" -s read-only --skip-git-repo-check -m "$MODEL" -c model_reasoning_effort="$EFFORT" -o "$TMP/final.md" \
  "Combine the reviewer reports (finder*.md) with the adversarial verdicts (skeptic*.md) into ONE final review of diff.patch, in Russian. Include only findings CONFIRMED or DOWNGRADED by the skeptics (drop REFUTED, but list them briefly in an 'Опровергнуто' section with one line why). Deduplicate. Sort by severity (P1/P2/P3). For each: Где, Что, Воспроизведение (команда+вывод), Как чинить. End with a verdict: можно ли мержить." </dev/null >"$TMP/syn.log" 2>&1

[ -s "$TMP/final.md" ] || {
  echo "синтез не удался; причина:"; tail -5 "$TMP/syn.log" 2>/dev/null
  cp -R "$TMP" "$OUT_DIR/deep_raw_${TOPIC}_${SHORT}" 2>/dev/null
  echo "сырые отчёты финдеров и скептиков: $OUT_DIR/deep_raw_${TOPIC}_${SHORT}"
  exit 3
}
{
  echo "# Deep review ($MODEL x$FINDERS finders + skeptics) — $TOPIC"
  echo "base: $BASE_SHA · merge-base: $MB · head: $HEAD_SHA · $(date '+%Y-%m-%d %H:%M')"
  echo
  cat "$TMP/final.md"
} > "$REPORT"
# Сырые отчёты финдеров/скептиков сохраняем рядом для разбора.
RAW="$OUT_DIR/deep_raw_${TOPIC}_${SHORT}"; mkdir -p "$RAW"; cp "$TMP"/finder*.md "$TMP"/skeptic*.md "$RAW"/ 2>/dev/null
echo "OK: $REPORT (raw: $RAW)"
