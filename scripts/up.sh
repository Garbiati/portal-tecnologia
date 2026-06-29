#!/usr/bin/env bash
# Sobe a stack local do produto (Postgres + API .NET + front Vite) com health-check.
# Idempotente: se um serviço já responde, não reinicia. Logs/pids em services/<p>-api/.run/
# (gitignored, pois /services/ está no .gitignore). Uso: make up  (ou PRODUCT=<outro> make up)
set -euo pipefail

PRODUCT="${PRODUCT:-doctor-hub}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/${PRODUCT}-api"
WEB_DIR="$ROOT/services/${PRODUCT}-web"
RUN="$API_DIR/.run"
mkdir -p "$RUN"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
info() { printf '  \033[36m▸\033[0m %s\n' "$1"; }
die()  { printf '  \033[31m✗\033[0m %s\n' "$1" >&2; exit 1; }

[ -f "$API_DIR/.env" ] || die "falta $API_DIR/.env (POSTGRES_PASSWORD, ConnectionStrings__Postgres, ASPNETCORE_URLS)"
# .env tem ';' em connection string → 'set -a; source' lida com aspas do próprio arquivo.
set -a; . "$API_DIR/.env"; set +a

API_URL="${ASPNETCORE_URLS:-http://localhost:5092}"; API_URL="${API_URL%%;*}"   # 1ª URL se houver várias
API_HEALTH="${API_URL%/}/health"

# ── 1) Postgres (docker compose) ──────────────────────────────────────────────
info "Postgres (docker compose)…"
( cd "$API_DIR" && docker compose up -d db ) >/dev/null
for _ in $(seq 1 40); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' doctorhub-db 2>/dev/null)" = healthy ] && break
  sleep 1
done
[ "$(docker inspect -f '{{.State.Health.Status}}' doctorhub-db 2>/dev/null)" = healthy ] \
  || die "Postgres não ficou healthy (veja: docker logs doctorhub-db)"
ok "Postgres healthy (host :5440)"

# Keycloak (IdP) é infra da EMPRESA — vive no repo portal-identity (P-003), não no Doctor-Hub.
# Aqui só checamos alcance (não-fatal): se não estiver no ar, oriente subir de lá.
if curl -fsS http://localhost:8089/realms/portal/.well-known/openid-configuration >/dev/null 2>&1; then
  ok "Keycloak (portal-identity) no ar — realm portal (http://localhost:8089)"
else
  info "Keycloak fora do ar — suba em: make -C services/portal-identity up (necessário p/ login OIDC)"
fi

# ── 2) API .NET ───────────────────────────────────────────────────────────────
if curl -fsS "$API_HEALTH" >/dev/null 2>&1; then
  ok "API já no ar — $API_HEALTH"
else
  info "API .NET…"
  DLL="$API_DIR/src/DoctorHub.Api/bin/Debug/net10.0/DoctorHub.Api.dll"
  if [ ! -f "$DLL" ]; then
    info "build (dll ausente)…"
    ( cd "$API_DIR" && dotnet build -c Debug --nologo -v q ) >/dev/null || die "build da API falhou"
  fi
  # setsid → sessão/grupo próprio (pgid = pid do líder). O líder grava o PRÓPRIO pid ($$) e dá
  # 'exec' p/ virar o dotnet com esse mesmo pid → o pid file = pgid real, e o down mata o grupo todo.
  ( cd "$API_DIR" && RUN="$RUN" DLL="$DLL" setsid bash -c 'echo $$ >"$RUN/api.pid"; exec dotnet "$DLL" --no-launch-profile' >"$RUN/api.log" 2>&1 & )
  for _ in $(seq 1 30); do curl -fsS "$API_HEALTH" >/dev/null 2>&1 && break; sleep 1; done
  curl -fsS "$API_HEALTH" >/dev/null 2>&1 || die "API não respondeu em $API_HEALTH (veja $RUN/api.log)"
  ok "API healthy — $API_URL (pid $(cat "$RUN/api.pid"))"
fi

# ── 3) Front Vite ─────────────────────────────────────────────────────────────
# Porta não é fixa (5173 → cai p/ 5174…). Subimos e lemos a porta escolhida do log.
# '|| true' é obrigatório: com 'set -o pipefail', grep sem match retorna ≠0 e abortaria o script.
detect_vite_url() { { grep -oE 'http://localhost:[0-9]+/' "$RUN/web.log" 2>/dev/null || true; } | head -1; }
WEB_URL="$(detect_vite_url)"
if [ -n "$WEB_URL" ] && curl -fsS -o /dev/null "$WEB_URL" 2>/dev/null; then
  ok "Front já no ar — $WEB_URL"
else
  info "Front Vite (pnpm dev)…"
  # setsid: pnpm gera filhos (sh→node/esbuild) — grupo próprio + pid do líder ($$) garantem que o
  # down mate todos. 'exec' preserva o pid; CHOKIDAR_USEPOLLING ajuda o watch neste ambiente.
  ( cd "$WEB_DIR" && RUN="$RUN" setsid bash -c 'echo $$ >"$RUN/web.pid"; exec env CHOKIDAR_USEPOLLING=1 pnpm dev' >"$RUN/web.log" 2>&1 & )
  for _ in $(seq 1 30); do WEB_URL="$(detect_vite_url)"; [ -n "$WEB_URL" ] && break; sleep 1; done
  [ -n "$WEB_URL" ] || die "Vite não anunciou a porta (veja $RUN/web.log)"
  for _ in $(seq 1 15); do curl -fsS -o /dev/null "$WEB_URL" 2>/dev/null && break; sleep 1; done
  curl -fsS -o /dev/null "$WEB_URL" 2>/dev/null || die "Front não respondeu em $WEB_URL (veja $RUN/web.log)"
  ok "Front HTTP 200 — $WEB_URL (pid $(cat "$RUN/web.pid"))"
fi

echo
printf '  \033[1mStack no ar:\033[0m  Postgres :5440   API %s   Front %s   (Keycloak :8089 = portal-identity)\n' "$API_URL" "${WEB_URL:-?}"
echo  "  logs: $RUN/api.log · $RUN/web.log   |   derrubar: make down"
