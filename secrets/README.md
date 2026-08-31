# Секреты: ключи вне конфигов и чатов

Правило: API-ключи и пароли никогда не вставляются в чат и не лежат в конфигах проектов
(конфиг легко закоммитить и слить). Схема:

1. Папка `~/.secrets/` с доступом только тебе (`chmod 700 ~/.secrets`) — её создаёт setup.sh.
2. По файлу на сервис, внутри строки `KEY=значение`:
   ```
   ~/.secrets/appstorespy.env   → APPSTORESPY_KEY=abc123
   ~/.secrets/google-ads.env    → GOOGLE_ADS_TOKEN=...
   ```
   Файлам тоже `chmod 600`.
3. MCP-серверу ключ передаёт обёртка `run.py` (лежит рядом): конфиг Claude запускает её,
   она читает ключ из `~/.secrets` и стартует сервер. Ключ нигде не светится.

Пример записи в конфиге Claude (claude_desktop_config.json или .mcp.json):

```json
{
  "mcpServers": {
    "my-server": {
      "command": "python3",
      "args": ["/путь/к/run.py"]
    }
  }
}
```

Нюанс macOS: обёртка именно на Python — shell-скрипты (.sh) Claude Desktop не запускает,
подключение молча не стартует.
