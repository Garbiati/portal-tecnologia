#!/usr/bin/env bash
# =============================================================================
# reset-ambiente.sh — RESET do ambiente Doctor-Hub para uma BASE NOVA (homologação).
#
# MODELO (P-009/P-010 · política D-183): há CONFIG/IDENTIDADE que SOBREVIVE a
# cada reset — doutores, CATÁLOGO (tipos de serviço), tenants/features, CLIENTES
# (14 HCs + os que o admin criar), CONFIG POR CLIENTE (branding/logos; contrato:
# telemedicina + especialidades), LAUDOS (faturamento por serviço do médico),
# SYNC_STATES (watermark do sync com a Teleconsulta) e os USUÁRIOS (Keycloak).
# O reset LIMPA só o TRANSACIONAL do pipeline:
#   escalas · solicitacoes · agendamentos · indisponibilidades · auditorias
# Sempre parte de uma base nova por cima. Reutilizável ENQUANTO nada é real —
# quando escalas/solicitações forem reais, o Alessandro avisa e paramos de usar.
#
# ─── GUARDRAILS ───────────────────────────────────────────────────────────────
# SEGURANÇA:
#   • Exige confirmação explícita: CONFIRM=RESET (senão aborta).
#   • BACKUP primeiro: pg_dump completo com timestamp ANTES de truncar (rede de
#     segurança — dá pra restaurar). Fica em infrastructure/backups/ (gitignored).
#     Se o backup falhar, o script aborta ANTES de tocar em qualquer dado.
#   • Conecta SÓ ao database `doctorhub` e ASSERTA current_database() — nunca
#     toca no database `keycloak` (mesma instância!) nem em sistemas da empresa.
#   • Segredos vêm do Secret Manager e NUNCA são ecoados.
#   • CLIENTES e USUÁRIOS são PRESERVADOS (não trunca clientes; usuários só com
#     --wipe-users, opt-in, via Admin API do Keycloak por KEEP-list — nunca por SQL).
# PERFORMANCE:
#   • TRUNCATE (O(1), não DELETE linha-a-linha).
# CUSTO (P-010):
#   • Zero recurso novo: reusa o cloud-sql-proxy e a instância existentes.
#
# USO:
#   CONFIRM=RESET ./reset-ambiente.sh                 # backup + limpa transacional
#   CONFIRM=RESET ./reset-ambiente.sh --wipe-users    # + deixa só o usuário do Alessandro
# =============================================================================
set -euo pipefail

INSTANCE="portal-tecnologia-500920:southamerica-east1:portal-identity-pg"
DB="doctorhub"
DB_USER="doctorhub"
PORT="${RESET_PGPORT:-5456}"
KC="https://id.portaltecnologia.app.br"
KEEP_CPF="35922911813"     # usuário do Alessandro (username = CPF) — NUNCA excluir
HERE="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HERE/../backups"
WIPE_USERS=0
[ "${1:-}" = "--wipe-users" ] && WIPE_USERS=1

# ── guarda de confirmação ────────────────────────────────────────────────────
if [ "${CONFIRM:-}" != "RESET" ]; then
  echo "⛔ Ação destrutiva. Rode com: CONFIRM=RESET $0 [--wipe-users]" >&2
  exit 2
fi

# ── localizar o cloud-sql-proxy ──────────────────────────────────────────────
PROXY="$(command -v cloud-sql-proxy || true)"
[ -z "$PROXY" ] && [ -x "${CLOUD_SQL_PROXY:-}" ] && PROXY="$CLOUD_SQL_PROXY"
if [ -z "$PROXY" ]; then
  echo "cloud-sql-proxy não encontrado. Instale (brew install cloud-sql-proxy) ou defina \$CLOUD_SQL_PROXY." >&2
  exit 3
fi

echo "▶ reset-ambiente · db=$DB · wipe-users=$WIPE_USERS"
"$PROXY" --port "$PORT" --token "$(gcloud auth print-access-token)" "$INSTANCE" > /tmp/reset-proxy.log 2>&1 &
PROXY_PID=$!
trap 'kill $PROXY_PID 2>/dev/null || true' EXIT
sleep 4
grep -qi ready /tmp/reset-proxy.log || { echo "proxy não subiu:"; tail -3 /tmp/reset-proxy.log; exit 3; }

CS="$(gcloud secrets versions access latest --secret=doctor-hub-db-connection)"
export PGPASSWORD="$(sed -E 's/.*Password=([^;]*).*/\1/' <<<"$CS")"
PSQL=(psql -h localhost -p "$PORT" -U "$DB_USER" -d "$DB" -v ON_ERROR_STOP=1 -qtA)

# ── GUARDRAIL: garantir que estamos MESMO no doctorhub ───────────────────────
CUR="$("${PSQL[@]}" -c 'SELECT current_database();')"
if [ "$CUR" != "$DB" ]; then echo "⛔ conectado a '$CUR', não '$DB' — abortando." >&2; exit 4; fi

# ── BACKUP de segurança (pg_dump completo, timestamp) ANTES de truncar ───────
# `set -e` garante: se o pg_dump falhar, o script para AQUI, sem tocar em dado.
mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BACKUP_DIR/doctorhub-$STAMP.sql"
echo "── backup de segurança → $BACKUP ──"
pg_dump -h localhost -p "$PORT" -U "$DB_USER" "$DB" > "$BACKUP"
echo "  ✓ backup salvo ($(du -h "$BACKUP" | cut -f1)). Restore: psql -h localhost -p $PORT -U $DB_USER -d $DB < \"$BACKUP\""

echo "── limpando TRANSACIONAL (preserva clientes/usuários/doutores/catálogo/branding/laudos/sync) ──"
# Só o pipeline transacional. NÃO se toca em: clientes, doctors, tipos_servico, tenants, features,
# tenant_features, cliente_branding (logos/tema — D-163), cliente_atividade/cliente_especialidade
# (contrato — D-164), laudos (faturamento/serviço do médico) e sync_states (watermark do sync).
"${PSQL[@]}" -c "
TRUNCATE TABLE escalas, solicitacoes, agendamentos, indisponibilidades, auditorias
RESTART IDENTITY CASCADE;"
echo "  ✓ transacional zerado (clientes/usuários/doutores/laudos/sync intactos)"

echo "── estado final do banco ──"
"${PSQL[@]}" -c "
SELECT 'doctors=' || (SELECT count(*) FROM doctors)
     || ' clientes=' || (SELECT count(*) FROM clientes)
     || ' tipos_servico=' || (SELECT count(*) FROM tipos_servico)
     || ' escalas=' || (SELECT count(*) FROM escalas)
     || ' solicitacoes=' || (SELECT count(*) FROM solicitacoes)
     || ' agendamentos=' || (SELECT count(*) FROM agendamentos);"
unset PGPASSWORD

# ── limpeza de usuários do Keycloak (OPCIONAL, opt-in via --wipe-users) ───────
if [ "$WIPE_USERS" = "1" ]; then
  echo "── Keycloak: mantendo só o Alessandro (+ service accounts) ──"
  BOOT="$(gcloud secrets versions access latest --secret=portal-identity-admin-password)"
  ATOK="$(curl -sS -X POST "$KC/realms/master/protocol/openid-connect/token" \
        -d client_id=admin-cli -d username=admin -d "password=$BOOT" -d grant_type=password \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')"
  curl -fsS "$KC/admin/realms/portal/users?max=200" -H "Authorization: Bearer $ATOK" > /tmp/reset-kcusers.json
  python3 - "$KEEP_CPF" > /tmp/reset-delete-ids.txt <<'PY'
import json, sys
keep = sys.argv[1]
for u in json.load(open('/tmp/reset-kcusers.json')):
    un = u.get("username", "")
    if un == keep or un.startswith("service-account-"):
        continue          # NUNCA excluir o dono nem service accounts
    print(u["id"], un)
PY
  while read -r KUID UN; do
    [ -n "$KUID" ] || continue
    code=$(curl -sS -X DELETE "$KC/admin/realms/portal/users/$KUID" -H "Authorization: Bearer $ATOK" -o /dev/null -w '%{http_code}')
    echo "  excluído $UN → $code"
  done < /tmp/reset-delete-ids.txt
  echo "  ✓ realm limpo (só o Alessandro)"
fi

rm -f /tmp/reset-kcusers.json /tmp/reset-delete-ids.txt
echo "✅ RESET CONCLUÍDO — config/identidade preservada, transacional zerado (backup em $BACKUP)."
