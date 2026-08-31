#!/usr/bin/env bash
# PreToolUse(Bash): best-effort предохранитель — ловит ТИПОВЫЕ опасные команды по шаблонам.
# Это НЕ гарантия: команду через переменные/эскейпы шаблон не поймает. Головой думать всё равно надо.
# Тела heredoc из проверки выкидываются: это данные (текст файла), а не команды — иначе хук
# блокирует безобидную запись файла, в котором просто УПОМЯНУТЫ опасные строки (ловилось на себе).
# Обратная сторона: `sh <<EOF … EOF` (heredoc, который исполняется шеллом) тоже не проверяется.
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
c = d.get('tool_input', {}).get('command', '')
print(re.sub(r\"<<-?\s*['\\\"]?(\w+)['\\\"]?\r?\n.*?^\1[ \t]*\$\", ' <<HEREDOC ', c, flags=re.S | re.M))
" 2>/dev/null)
[ -z "$cmd" ] && exit 0
cmd_flat=$(printf '%s' "$cmd" | tr '\n' ' ')

deny() {
  python3 -c "import json,sys; print(json.dumps({'hookSpecificOutput':{'hookEventName':'PreToolUse','permissionDecision':'deny','permissionDecisionReason':sys.argv[1]}}))" "$1"
  exit 0
}

# heredoc, скармливаемый шеллу: тело не проверяется, поэтому не пропускаем вслепую
if printf '%s' "$cmd_flat" | grep -Eq '(^|[|;&[:space:]])(sudo[[:space:]]+)?(ba|z)?sh[[:space:]]*<<'; then
  deny "Заблокировано хуком: heredoc, исполняемый шеллом (sh <<EOF) — его тело предохранитель не проверяет. Разверни в явные команды."
fi
# рекурсивное удаление корня/домашней папки
if printf '%s' "$cmd_flat" | grep -Eq 'rm[[:space:]]+((-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[[:space:]]+)(-[a-zA-Z-]+[[:space:]]+)*[\"'"'"']?(/|~|\$\{?HOME\}?|/\*|\.\.)[\"'"'"']?([[:space:]/]|$)|rm[[:space:]]+[^|;&]*--recursive[^|;&]*[\"'"'"']?(/|~|\$\{?HOME\}?)[\"'"'"']?([[:space:]/]|$)'; then
  deny "Заблокировано хуком: рекурсивное удаление корня/домашней папки. Уточни путь."
fi
# загрузка скрипта с пайпом в shell (curl|wget … | sh/bash)
if printf '%s' "$cmd_flat" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh|zsh)'; then
  deny "Заблокировано хуком: запуск скачанного скрипта через | sh. Сохрани и проверь файл сначала."
fi
# force-push — по самому флагу, а не по слову main: `git push -f origin HEAD` на выкаченном main
# затирает чужую работу ровно так же. Смотрим только сегмент самой команды (до | ; &&),
# чтобы -f из соседних тестов [ -f … ] не срабатывал.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^|;&]*(--force(-with-lease(=[^[:space:]]+)?)?|-f)([[:space:]]|$)|git[[:space:]]+push[[:space:]][^|;&]*[[:space:]]\+[^[:space:]:]+'; then
  deny "Заблокировано хуком: force-push. Перезаписывает чужие коммиты; если это точно нужно — сделай сам в терминале."
fi
# разрушающий git: стирает незакоммиченную работу без спроса
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(reset[^|;&]*--hard|clean[[:space:]]+-[a-zA-Z]*f|checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)|restore[[:space:]]+(--[a-zA-Z-]+[[:space:]]+)*\.([[:space:]]|$)|branch[^|;&]*-D([[:space:]]|$))'; then
  deny "Заблокировано хуком: разрушающая git-команда (reset --hard / clean -f / checkout . / branch -D) — стирает незакоммиченную работу. Сохрани WIP-коммитом или уточни путь."
fi
# затирание диска / форматирование
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(mkfs|dd[[:space:]]+if=.*of=/dev/)'; then
  deny "Заблокировано хуком: операция с дисковым устройством."
fi
# chmod 777 на корень
if printf '%s' "$cmd" | grep -Eq 'chmod[[:space:]]+(-R[[:space:]]+)?777[[:space:]]+/( |$)'; then
  deny "Заблокировано хуком: chmod 777 на /."
fi
exit 0
