#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then python3 -m venv .venv; fi
if [ ! -f .venv/packages-ready ]; then
  .venv/bin/python -m pip install --upgrade pip
  .venv/bin/python -m pip install -r backend/requirements.txt
  touch .venv/packages-ready
fi
if [ ! -f .env ]; then cp .env.example .env; fi
exec .venv/bin/python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
