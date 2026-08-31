#!/bin/sh
# Установка AI Starter Kit. Безопасно: ничего не удаляет, существующее бэкапит,
# каждое действие печатает. Повторный запуск — ок.
set -e
KIT=$(cd "$(dirname "$0")" && pwd)
say() { printf '%s\n' "$*"; }

say "== AI Starter Kit → установка =="

# 1. Хуки
mkdir -p "$HOME/.claude/hooks"
STAMP=$(date +%Y%m%d-%H%M%S)
for h in guard-bash.sh format.sh check.sh; do
  if [ -f "$HOME/.claude/hooks/$h" ] && ! cmp -s "$KIT/hooks/$h" "$HOME/.claude/hooks/$h"; then
    cp "$HOME/.claude/hooks/$h" "$HOME/.claude/hooks/$h.$STAMP.bak"
    say "  ~/.claude/hooks/$h отличался — бэкап в $h.$STAMP.bak"
  fi
  cp "$KIT/hooks/$h" "$HOME/.claude/hooks/$h"
  chmod +x "$HOME/.claude/hooks/$h"
done
say "✓ хуки скопированы в ~/.claude/hooks/"

# PostToolUse-хуки (автоформат и проверка типов) запускают prettier/tsc ИЗ ОТКРЫТОГО ПРОЕКТА.
# В недоверенном репозитории это исполнение чужого кода — поэтому ставим только по согласию.
printf "Включить автоформат и проверку типов после правок (запускают prettier/tsc текущего проекта; в чужих репо = исполнение их кода)? [y/N] "
read -r hooks_ans || hooks_ans=n

# 2. Хуки в settings.json (аккуратный merge с бэкапом)
INSTALL_POST="$hooks_ans" STAMP="$STAMP" python3 - "$HOME/.claude/settings.json" <<'PY'
import json, os, sys, tempfile
path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
backed = ""
if os.path.exists(path):
    data = json.load(open(path))  # невалидный JSON упадёт ДО каких-либо правок
    bak = f"{path}.{os.environ['STAMP']}.bak"
    with open(bak, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    backed = f" (бэкап: {os.path.basename(bak)})"
hooks = data.setdefault("hooks", {})
home = os.path.expanduser("~")
def ensure(event, matcher, cmd):
    rules = hooks.setdefault(event, [])
    for r in rules:
        if r.get("matcher") == matcher:
            cmds = [h.get("command") for h in r.get("hooks", [])]
            if cmd not in cmds:
                r.setdefault("hooks", []).append({"type": "command", "command": cmd})
            return
    rules.append({"matcher": matcher, "hooks": [{"type": "command", "command": cmd}]})
ensure("PreToolUse", "Bash", f"{home}/.claude/hooks/guard-bash.sh")
if os.environ.get("INSTALL_POST", "n").lower() == "y":
    ensure("PostToolUse", "Edit|Write", f"{home}/.claude/hooks/format.sh")
    ensure("PostToolUse", "Edit|Write", f"{home}/.claude/hooks/check.sh")
    extra = " + автоформат/проверка типов"
else:
    extra = "; автоформат/проверка типов НЕ включены"
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
with os.fdopen(fd, "w") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.flush(); os.fsync(f.fileno())
os.replace(tmp, path)
print(f"✓ guard-хук прописан в ~/.claude/settings.json{extra}{backed}")
PY

# 3. Скилы и команды
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
for s in "$KIT"/skills/*/; do
  name=$(basename "$s")
  if [ -e "$HOME/.claude/skills/$name" ]; then
    say "  скил $name уже есть — пропускаю"
  else
    ln -s "$KIT/skills/$name" "$HOME/.claude/skills/$name"
    say "✓ скил $name → симлинк в ~/.claude/skills/"
  fi
done
for c in "$KIT"/commands/*.md; do
  name=$(basename "$c")
  [ -e "$HOME/.claude/commands/$name" ] && { say "  команда $name уже есть — пропускаю"; continue; }
  cp "$c" "$HOME/.claude/commands/$name"
  say "✓ команда /$( basename "$name" .md ) установлена"
done

# 4. Секреты
if [ ! -d "$HOME/.secrets" ]; then
  mkdir -p "$HOME/.secrets" && chmod 700 "$HOME/.secrets"
  say "✓ создана папка ~/.secrets (доступ только тебе). Как класть ключи — secrets/README.md"
else
  perms=$(stat -f %Lp "$HOME/.secrets" 2>/dev/null || stat -c %a "$HOME/.secrets" 2>/dev/null)
  if [ "$perms" != "700" ]; then
    say "⚠ ~/.secrets уже есть, но права $perms (не 700) — читать могут другие. Исправь: chmod 700 ~/.secrets"
  else
    say "  ~/.secrets уже есть, права 700 — ок"
  fi
fi

# 5. Workspace с файлами-знаниями
WS="$HOME/ai-workspace"
if [ ! -d "$WS" ]; then
  mkdir -p "$WS/handoffs" "$WS/memory" "$WS/products"
  cp "$KIT/templates/TASKS.md" "$WS/TASKS.md"
  cp "$KIT/templates/MEMORY.md" "$WS/memory/MEMORY.md"
  cp "$KIT/templates/memory-entry-template.md" "$WS/memory/"
  cp "$KIT/templates/backlog-template.md" "$WS/products/"
  cp "$KIT/templates/changelog-template.md" "$WS/products/"
  cp "$KIT/templates/handoff-template.md" "$WS/handoffs/"
  say "✓ создан ~/ai-workspace (TASKS.md, memory/, handoffs/, products/)."
  say "  Совет: сделай его приватным git-репо — история знаний не потеряется."
else
  say "  ~/ai-workspace уже есть — не трогаю (шаблоны лежат в templates/)"
fi

# 6. Опционально: superpowers + marketingskills
printf "Поставить superpowers (методология для кодинг-агента)? [y/N] "
read -r ans || ans=n
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
  mkdir -p "$HOME/.claude/skill-repos"
  [ -d "$HOME/.claude/skill-repos/superpowers" ] || git clone https://github.com/obra/superpowers "$HOME/.claude/skill-repos/superpowers"
  for s in "$HOME/.claude/skill-repos/superpowers/skills"/*/; do
    name=$(basename "$s")
    [ -e "$HOME/.claude/skills/$name" ] || ln -s "$s" "$HOME/.claude/skills/$name"
  done
  say "✓ superpowers установлен"
fi
printf "Поставить marketingskills (маркетинг/ASO/тексты)? [y/N] "
read -r ans || ans=n
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
  mkdir -p "$HOME/.claude/skill-repos"
  [ -d "$HOME/.claude/skill-repos/marketingskills" ] || git clone https://github.com/coreyhaines31/marketingskills "$HOME/.claude/skill-repos/marketingskills"
  for s in "$HOME/.claude/skill-repos/marketingskills/skills"/*/; do
    name=$(basename "$s")
    [ -e "$HOME/.claude/skills/$name" ] || ln -s "$s" "$HOME/.claude/skills/$name"
  done
  say "✓ marketingskills установлен"
fi

say ""
say "== Готово. Осталось руками =="
say "1. Заполни правила: возьми rules/CLAUDE.global.md, сохрани как ~/.claude/CLAUDE.md"
say "   (для Codex тот же текст в ~/.codex/AGENTS.md). В код-репо — rules/CLAUDE.project.md."
say "2. MCP context7/playwright: сниппеты в mcp/README.md."
say "3. Кросс-ревью: из корня код-репо  sh $KIT/review/review.sh codex"
say "4. Перезапусти Claude Code, чтобы подхватились хуки и скилы."
