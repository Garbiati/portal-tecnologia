#!/usr/bin/env bash
# limpar-solicitacoes.sh — CLEAR CIRÚRGICO só da tabela `solicitacoes` em PROD.
#
# Por quê separado do reset-ambiente.sh: o reset limpa TODO o transacional
# (escalas, solicitacoes, agendamentos, indisponibilidades…) — apagaria também as
# ESCALAS. Quando você só quer zerar as SOLICITAÇÕES (ex.: limpar dado de
# homologação/teste que sobrou), use ESTE, que NÃO toca em escalas/doutores/clientes.
#
# Guard-rails (iguais ao reset-ambiente.sh):
#   • Exige CONFIRM=LIMPAR (senão aborta) — ação DESTRUTIVA e IRREVERSÍVEL.
#   • Conecta SÓ ao database `doctorhub` e ASSERTA current_database() antes de mexer.
#   • Segredo vem do Secret Manager, sem echo. Proxy via cloud-sql-proxy + gcloud token.
#   • TRUNCATE (O(1)); só a tabela `solicitacoes`.
#
# Uso:  CONFIRM=LIMPAR bash infrastructure/scripts/limpar-solicitacoes.sh
set -euo pipefail

INSTANCE="portal-tecnologia-500920:southamerica-east1:portal-identity-pg"
DB="doctorhub"
DB_USER="doctorhub"
PORT="${LIMPAR_PGPORT:-5457}"

if [ "${CONFIRM:-}" != "LIMPAR" ]; then
  echo "⛔ Ação destrutiva e IRREVERSÍVEL (apaga TODAS as solicitações em PROD)." >&2
  echo "   Rode com: CONFIRM=LIMPAR $0" >&2
  exit 2
fi

# ── localizar o cloud-sql-proxy (PATH ou \$CLOUD_SQL_PROXY) ───────────────────
PROXY="$(command -v cloud-sql-proxy || true)"
[ -z "$PROXY" ] && [ -x "${CLOUD_SQL_PROXY:-}" ] && PROXY="$CLOUD_SQL_PROXY"
if [ -z "$PROXY" ]; then
  echo "cloud-sql-proxy não encontrado (adicione ao PATH ou defina \$CLOUD_SQL_PROXY)." >&2
  exit 3
fi

echo "▶ limpar-solicitacoes · db=$DB"
"$PROXY" --port "$PORT" --token "$(gcloud auth print-access-token)" "$INSTANCE" > /tmp/limpar-proxy.log 2>&1 &
PROXY_PID=$!
trap 'kill $PROXY_PID 2>/dev/null || true' EXIT
sleep 4
grep -qi ready /tmp/limpar-proxy.log || { echo "proxy não subiu:"; tail -3 /tmp/limpar-proxy.log; exit 3; }

CS="$(gcloud secrets versions access latest --secret=doctor-hub-db-connection)"
export PGPASSWORD="$(sed -E 's/.*Password=([^;]*).*/\1/' <<<"$CS")"
PSQL=(psql -h localhost -p "$PORT" -U "$DB_USER" -d "$DB" -v ON_ERROR_STOP=1 -qtA)

# ── GUARDRAIL: garantir que estamos MESMO no doctorhub ───────────────────────
CUR="$("${PSQL[@]}" -c 'SELECT current_database();')"
if [ "$CUR" != "$DB" ]; then echo "⛔ conectado a '$CUR', não '$DB' — abortando." >&2; exit 4; fi

ANTES="$("${PSQL[@]}" -c 'SELECT count(*) FROM solicitacoes;')"
echo "── solicitações antes: $ANTES ──"
"${PSQL[@]}" -c "TRUNCATE TABLE solicitacoes RESTART IDENTITY;"
DEPOIS="$("${PSQL[@]}" -c 'SELECT count(*) FROM solicitacoes;')"
echo "  ✓ solicitações agora: $DEPOIS (escalas/agendamentos/doutores/clientes intactos)"
echo "▶ pronto. Dê hard-refresh no app (o front é real-puro; vai mostrar 0)."
