#!/bin/sh
# Самопроверка AI Starter Kit: поставлено ли и пользуются ли. Только чтение.
# Запуск: sh ~/ai-starter-kit/doctor.sh   (Windows: из Git Bash)
KIT=$(cd "$(dirname "$0")" && pwd); B=0; W=0
ok() { printf '✓ %s\n' "$*"; }; warn() { printf '⚠ %s\n' "$*"; W=$((W+1)); }; bad() { printf '✗ %s\n' "$*"; B=$((B+1)); }
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1;; *) WIN=0;; esac
echo "== Установка"
# версия кита
LOCAL=$(git -C "$KIT" rev-parse HEAD 2>/dev/null); REMOTE=$(git -C "$KIT" ls-remote origin -h refs/heads/main 2>/dev/null | cut -f1)
if [ -z "$REMOTE" ]; then warn "не удалось сверить версию кита с GitHub (сеть?)"
elif [ "$LOCAL" = "$REMOTE" ] || git -C "$KIT" merge-base --is-ancestor "$REMOTE" "$LOCAL" 2>/dev/null; then ok "кит актуален ($(git -C "$KIT" log -1 --format=%ad --date=short))"
else warn "кит отстал от GitHub: cd $KIT && git pull && sh setup.sh"; fi
# хук
H="$HOME/.claude/hooks/guard-bash.sh"
if [ ! -f "$H" ]; then bad "нет $H — запусти setup.sh"
elif ! cmp -s "$H" "$KIT/hooks/guard-bash.sh"; then warn "guard-bash.sh отличается от версии кита (обнови: sh setup.sh)"
else ok "guard-хук на месте и совпадает с китом"; fi
if python3 -c 'import json,sys,os; d=json.load(open(os.path.expanduser("~/.claude/settings.json"))); sys.exit(0 if any(r.get("matcher","") in ("Bash","*","") or "Bash" in r.get("matcher","").split("|") for r in d.get("hooks",{}).get("PreToolUse",[]) for h in r.get("hooks",[]) if h.get("type","command")=="command" and h.get("command","").strip().strip("\"\x27").endswith("guard-bash.sh")) else 1)' 2>/dev/null
then ok "хук прописан в settings.json → PreToolUse, matcher Bash"; else bad "guard-хук не прописан на Bash в ~/.claude/settings.json (или JSON битый): sh setup.sh"; fi
# скилы и команды
for s in "$KIT"/skills/*/; do n=$(basename "$s")
  if [ -f "$HOME/.claude/skills/$n/SKILL.md" ]; then ok "скил $n (Claude)"; else bad "скил $n не читается в ~/.claude/skills (битая ссылка? на Windows — запусти setup.sh ещё раз, он скопирует)"; fi
  [ -d "$HOME/.codex" ] && { [ -f "$HOME/.codex/skills/$n/SKILL.md" ] && ok "скил $n (Codex)" || warn "скила $n нет в ~/.codex/skills (sh setup.sh)"; }
done
for c in "$KIT"/commands/*.md; do n=$(basename "$c")
  [ -f "$HOME/.claude/commands/$n" ] && { cmp -s "$c" "$HOME/.claude/commands/$n" || warn "команда $n отличается от кита"; } || bad "нет команды ~/.claude/commands/$n"
done
# правила
R="$HOME/.claude/CLAUDE.md"
if [ ! -s "$R" ]; then bad "нет ~/.claude/CLAUDE.md — заполни по rules/CLAUDE.global.md"
elif grep -q '<русский>\|<чем занимаюсь>\|<твой стек>' "$R"; then warn "~/.claude/CLAUDE.md — незаполненный шаблон (остались <...>)"
else ok "~/.claude/CLAUDE.md заполнен ($(grep -c . "$R") строк)"; fi
[ -d "$HOME/.codex" ] && { [ -s "$HOME/.codex/AGENTS.md" ] && ok "~/.codex/AGENTS.md есть" || warn "нет ~/.codex/AGENTS.md (скопируй туда правила)"; }
# бинарники
command -v claude >/dev/null 2>&1 && ok "claude в PATH ($(claude --version 2>/dev/null | head -1))" || warn "claude не в PATH — review.sh claude и запуск из терминала не работают: npm i -g @anthropic-ai/claude-code"
command -v codex  >/dev/null 2>&1 && ok "codex в PATH ($(codex --version 2>/dev/null | head -1))" || warn "codex не в PATH — кросс-ревью второй моделью не работает: npm i -g @openai/codex"
command -v gitleaks >/dev/null 2>&1 && ok "gitleaks есть" || warn "gitleaks нет — review.sh не сканирует дифф на секреты"
# секреты
if [ ! -d "$HOME/.secrets" ]; then warn "нет ~/.secrets"
elif [ "$WIN" = 1 ]; then warn "~/.secrets есть, но права НЕ проверены: в Windows доступ задаётся ACL. Проверь сам: icacls \"%USERPROFILE%\\.secrets\" — в списке только ты, SYSTEM и Administrators"
else P=$(stat -f %Lp "$HOME/.secrets" 2>/dev/null || stat -c %a "$HOME/.secrets" 2>/dev/null); [ "$P" = 700 ] && ok "~/.secrets права 700" || warn "~/.secrets права $P, нужно 700: chmod 700 ~/.secrets"; fi

echo "== Использование"
WS="$HOME/ai-workspace"
if [ -d "$WS" ]; then
  if [ ! -s "$WS/TASKS.md" ]; then warn "TASKS.md нет или пустой"
  elif grep -q '<задача>\|<дата>' "$WS/TASKS.md"; then warn "TASKS.md — всё ещё шаблон, задачами не пользуются"
  else ok "TASKS.md ведётся"; fi
  N=$(find "$WS/memory" -name '*.md' ! -name MEMORY.md ! -name '*template*' 2>/dev/null | wc -l | tr -d ' '); [ "$N" -gt 0 ] && ok "файлов памяти: $N" || warn "память пустая: агент каждый раз узнаёт проект заново (команда /learn)"
  N=$(find "$WS/handoffs" -name '*.md' ! -name '*template*' 2>/dev/null | wc -l | tr -d ' '); [ "$N" -gt 0 ] && ok "хендоффов: $N" || warn "хендоффов нет (команда /handoff перед сменой сессии)"
else warn "нет ~/ai-workspace"; fi
# репо: CLAUDE.md и отчёты ревью. Где искать: KIT_REPOS="путь путь" или типовые папки.
# Корни: KIT_REPOS — пути через двоеточие (как PATH), иначе типовые папки. Пробелы в путях допустимы.
REPOS=0; WITH=0; REPORTS=0; LAST=""; GITS=$(mktemp)
scan_root() { r="$1"; case "$r" in [A-Za-z]) echo "⚠ KIT_REPOS: путь вида C:/... не подходит (двоеточие — разделитель). В Git Bash пиши /c/Users/...:/d/src"; W=$((W+1)); return;; esac
  case "$r" in "~/"*) r="$HOME/${r#\~/}";; "~") r="$HOME";; esac   # ~ в переменной сам не раскрывается
  [ -d "$r" ] && find "$r" -maxdepth 3 -name .git -type d 2>/dev/null >> "$GITS"; }
if [ -n "${KIT_REPOS:-}" ]; then OLDIFS=$IFS; IFS=:; for root in $KIT_REPOS; do IFS=$OLDIFS; scan_root "$root"; IFS=:; done; IFS=$OLDIFS
else for d in source Projects projects dev code work Documents; do scan_root "$HOME/$d"; done; fi
while IFS= read -r g; do r=$(dirname "$g"); REPOS=$((REPOS+1))   # построчно: пути с пробелами целы
  if [ -f "$r/CLAUDE.md" ] || [ -f "$r/AGENTS.md" ]; then WITH=$((WITH+1)); fi
  for f in "$r"/out/reports/*review*.md; do [ -f "$f" ] || continue; REPORTS=$((REPORTS+1)); if [ -z "$LAST" ] || [ "$f" -nt "$LAST" ]; then LAST="$f"; fi; done
done < "$GITS"; rm -f "$GITS"
if [ "$REPOS" -eq 0 ]; then warn "рабочих репо не найдено (укажи: KIT_REPOS=\"путь1:путь2\" sh doctor.sh). Без локального репо review.sh и правила проекта не работают"
else
  [ "$WITH" -eq "$REPOS" ] && ok "CLAUDE.md/AGENTS.md во всех $REPOS репо" || warn "правила проекта есть в $WITH из $REPOS репо (шаблон: rules/CLAUDE.project.md)"
  [ "$REPORTS" -gt 0 ] && ok "отчётов кросс-ревью: $REPORTS, последний: $LAST" || warn "отчётов review.sh нет ни в одном репо — кросс-ревью второй моделью не запускалось"
fi
echo "== итог: ✗ $B · ⚠ $W"; [ "$B" -eq 0 ]
