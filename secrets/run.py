#!/usr/bin/env python3
"""Обёртка для запуска MCP-сервера с ключом из ~/.secrets.

Подстрой три константы под свой сервер и укажи этот файл как command
в конфиге Claude — ключ не будет лежать в конфиге открытым текстом.
"""
import os
import subprocess
import sys

SECRETS_FILE = os.path.expanduser("~/.secrets/my-server.env")  # файл вида KEY=значение
ENV_VAR = "MY_SERVER_API_KEY"                                  # какую переменную ждёт сервер
SERVER_CMD = ["npx", "-y", "my-mcp-server"]                    # чем запускается сам сервер


def read_key(path: str, name: str) -> str:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith(name + "="):
                return line.split("=", 1)[1]
    sys.exit(f"{name} не найден в {path}")


env = dict(os.environ)
env[ENV_VAR] = read_key(SECRETS_FILE, ENV_VAR)
sys.exit(subprocess.call(SERVER_CMD, env=env))
