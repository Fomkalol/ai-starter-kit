# MCP: проверенные подключения

MCP — «мостик», через который агент дотягивается до реальных данных и инструментов.
Записи добавляются в конфиг Claude: `claude_desktop_config.json` (десктоп, Settings →
Developer → Edit Config) или `.mcp.json` в корне проекта (Claude Code).

## Без ключей — просто вставь

**context7** — свежая документация библиотек (меньше выдуманного кода):
```json
{"mcpServers": {"context7": {"command": "npx", "args": ["-y", "@upstash/context7-mcp"]}}}
```

**playwright** — агент управляет настоящим браузером (E2E-тесты, проверка сайтов вживую):
```json
{"mcpServers": {"playwright": {"command": "npx", "args": ["-y", "@playwright/mcp@latest"]}}}
```

**youtube-transcript** — расшифровка видео по ссылке (разборы вместо часа просмотра):
```json
{"mcpServers": {"youtube-transcript": {"command": "npx", "args": ["-y", "@kimtaeyoon83/mcp-server-youtube-transcript"]}}}
```

Несколько серверов — в один объект `mcpServers`, через запятую. После правки конфига
полностью перезапусти Claude.

## С ключами

Источники вроде AppStoreSpy, Google Ads, Google Trends требуют API-ключей. Схема
хранения ключей — `../secrets/README.md`. Сами серверы и ключи — у того, кто дал тебе
этот кит, либо заводи свои.

## Проверка

Спроси в чате: «какие MCP-серверы тебе доступны?» — и попроси тестовый запрос к каждому.
Данные не пришли — проверь конфиг и перезапуск, потом спроси Claude: «почему MCP X не отвечает?»
