#!/usr/bin/env bash
# =============================================================================
# reset-ambiente.sh — HARD RESET do ambiente doc hub (fase de construção).
#
# MODELO (P-009/P-010): o banco tem um BASELINE = a carga inicial do tenant
# fundador (Portal Telemedicina) — catálogo de tipos de serviço + DOUTORES +
# CLIENTES (14 HCs reais). O reset PRESERVA esse baseline e LIMPA só o
# TRANSACIONAL (escalas, solicitações, agendamentos, indisponibilidades,
# auditorias, laudos). É como restaurar um snapshot da fundação e reconstruir
# por cima. Reutilizável enquanto nenhum dado é real.
#
# ─── GUARDRAILS ───────────────────────────────────────────────────────────────
# SEGURANÇA:
#   • Exige confirmação explícita: CONFIRM=RESET (senão aborta).
#   • Conecta SÓ ao database `doctorhub` e ASSERTA current_database() — nunca
#     toca no database `keycloak` (mesma instância!) nem em sistemas da empresa.
#   • Segredos vêm do Secret Manager e NUNCA são ecoados.
#   • Limpeza de usuários (--wipe-users) via Admin API do Keycloak, por KEEP-list
#     (mantém o Alessandro + todo service-account-*); nunca por SQL.
# PERFORMANCE:
#   • TRUNCATE (O(1), não DELETE linha-a-linha); doutores NÃO são tocados.
# CUSTO (P-010):
#   • Zero recurso novo: reusa o cloud-sql-proxy e a instância existentes.
#
# USO:
#   CONFIRM=RESET ./reset-ambiente.sh                 # limpa transacional + reafirma HCs
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
HC_JSON="$HERE/../data/health-centers.json"
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
[ -z "$PROXY" ] && [ -x "/tmp/claude-1000/-home-alessandro-portal-tecnologia/656efbd7-5d0e-43bf-8c85-ba78f8e724c4/scratchpad/cloud-sql-proxy" ] \
  && PROXY="/tmp/claude-1000/-home-alessandro-portal-tecnologia/656efbd7-5d0e-43bf-8c85-ba78f8e724c4/scratchpad/cloud-sql-proxy"
if [ -z "$PROXY" ]; then echo "cloud-sql-proxy não encontrado (PATH ou \$CLOUD_SQL_PROXY)." >&2; exit 3; fi

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

echo "── limpando TRANSACIONAL (preserva doutores + catálogo) ──"
"${PSQL[@]}" -c "
TRUNCATE TABLE escalas, solicitacoes, agendamentos, indisponibilidades,
               auditorias, laudos, sync_states, clientes
RESTART IDENTITY CASCADE;"
echo "  ✓ transacional + clientes zerados (doutores/tipos_servico intactos)"

echo "── reafirmando os 14 HCs (baseline de clientes da Portal) ──"
python3 - "$HC_JSON" > /tmp/reset-hcs.sql <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
def esc(s): return s.replace("'", "''")
vals, usadas = [], set()
for c in d["clientes"]:
    ext = c["externalId"]; nome = c["nome"]; nat = c["natureza"]
    sigla = nome[:20].strip(); base, i = sigla, 2
    while sigla.lower() in usadas:
        suf = f" {i}"; sigla = base[:20-len(suf)] + suf; i += 1
    usadas.add(sigla.lower())
    tipo = "estado" if nat == "publico" else "privado"
    vals.append(f"('C-{ext[:8]}', '{esc(sigla)}', '{esc(nome)}', '', '{tipo}', '', '{nat}', true, '{ext}')")
print("INSERT INTO clientes (id, sigla, nome, cnpj, tipo, prazo, natureza, ativo, external_id) VALUES")
print(",\n".join(vals))
print("ON CONFLICT (external_id) DO UPDATE SET nome = EXCLUDED.nome, sigla = EXCLUDED.sigla, natureza = EXCLUDED.natureza, ativo = true;")
PY
"${PSQL[@]}" -f /tmp/reset-hcs.sql
echo "  ✓ HCs reafirmados"

echo "── estado final do banco ──"
"${PSQL[@]}" -c "
SELECT 'doctors=' || (SELECT count(*) FROM doctors)
     || ' clientes=' || (SELECT count(*) FROM clientes)
     || ' tipos_servico=' || (SELECT count(*) FROM tipos_servico)
     || ' escalas=' || (SELECT count(*) FROM escalas)
     || ' solicitacoes=' || (SELECT count(*) FROM solicitacoes)
     || ' agendamentos=' || (SELECT count(*) FROM agendamentos);"
unset PGPASSWORD

# ── limpeza de usuários do Keycloak (opcional) ───────────────────────────────
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

rm -f /tmp/reset-hcs.sql /tmp/reset-delete-ids.txt /tmp/reset-kcusers.json
echo "✅ RESET CONCLUÍDO — baseline da Portal preservado, transacional zerado."
