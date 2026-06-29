#!/usr/bin/env bash
# Derruba a stack local: front Vite + API .NET (via pid files) e o Postgres (docker compose).
# Uso: make down  (ou PRODUCT=<outro> make down). Não apaga o volume do banco (dados ficam).
set -euo pipefail

PRODUCT="${PRODUCT:-doctor-hub}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/${PRODUCT}-api"
RUN="$API_DIR/.run"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
info() { printf '  \033[36m▸\033[0m %s\n' "$1"; }

kill_pid() { # $1=arquivo-pid  $2=rótulo
  local f="$1" label="$2" pid
  [ -f "$f" ] || { info "$label: sem pid registrado"; return; }
  pid="$(cat "$f")"
  if kill -0 "$pid" 2>/dev/null; then
    # Os serviços sobem com setsid (pgid = pid). 'kill -- -pid' derruba o grupo inteiro
    # (pnpm→node/esbuild, dotnet host) — não só o líder.
    kill -TERM -- -"$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
    ok "$label parado (grupo $pid)"
  else
    info "$label: pid $pid já não roda"
  fi
  rm -f "$f"
}

kill_pid "$RUN/web.pid" "Front Vite"
kill_pid "$RUN/api.pid" "API .NET"

info "Postgres (docker compose down)…"
( cd "$API_DIR" && docker compose down ) >/dev/null 2>&1 && ok "Postgres parado (volume preservado)"
