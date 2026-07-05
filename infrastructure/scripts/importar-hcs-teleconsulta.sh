#!/usr/bin/env bash
# Importa os HealthCenters da TELECONSULTA como CLIENTES do doc hub (externalId = health_centers.id).
# PULL READ-ONLY (D-069) via o ferramental oficial da empresa (regula-hub: Vault lease RO + proxy).
# Upsert idempotente por external_id — pode rodar quantas vezes quiser.
#
# Pré-requisito (INTERATIVO, 1x/24h — só o humano): sessão Vault viva.
#   cd ~/ptm/teleconsulta-regula-hub && bash scripts/db/prod-up.sh
#
# Uso: bash infrastructure/scripts/importar-hcs-teleconsulta.sh [--apply]
#   (sem --apply = dry-run: mostra o que seria importado)
set -euo pipefail

HUB=/home/alessandro/ptm/teleconsulta-regula-hub
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# ── 1. PULL read-only dos HCs (ferramental oficial; nada é escrito na TC) ────
echo "▸ lendo health_centers da Teleconsulta (read-only)…"
bash "$HUB/scripts/db/query-prod-ro.sh" core \
  "SELECT id, name, COALESCE(domain,'') FROM health_centers ORDER BY name;" \
  --csv > "$SCRATCH/hcs.csv"
N=$(wc -l < "$SCRATCH/hcs.csv")
echo "  $N HCs lidos."

# ── 2. Gera o upsert (sigla=name ≤20 chars, única; natureza=publico PROVISÓRIO — revisar na tela) ──
python3 - "$SCRATCH/hcs.csv" "$SCRATCH/upsert.sql" <<'PY'
import csv, sys, unicodedata

def sigla_de(nome, usadas):
    s = nome.strip()[:20].strip()
    base, i = s, 2
    while s.lower() in usadas:
        suf = f" {i}"
        s = base[:20 - len(suf)] + suf
        i += 1
    usadas.add(s.lower())
    return s

linhas, usadas = [], set()
with open(sys.argv[1], newline='') as fh:
    for row in csv.reader(fh):
        if len(row) < 2 or row[0] in ('id',):
            continue
        hc_id, nome = row[0].strip(), row[1].strip()
        if not hc_id or not nome:
            continue
        sigla = sigla_de(nome, usadas)
        esc = lambda v: v.replace("'", "''")
        linhas.append(
            f"('C-{hc_id[:8]}', '{esc(sigla)}', '{esc(nome)}', '', 'estado', '', 'publico', true, '{esc(hc_id)}')"
        )

sql = f"""-- Upsert de HCs da Teleconsulta como clientes (externalId = health_centers.id).
INSERT INTO clientes (id, sigla, nome, cnpj, tipo, prazo, natureza, ativo, external_id) VALUES
{',\n'.join(linhas)}
ON CONFLICT (external_id) DO UPDATE SET nome = EXCLUDED.nome;
"""
open(sys.argv[2], 'w').write(sql)
print(f"  {len(linhas)} upserts gerados.")
PY

if [[ "${1:-}" != "--apply" ]]; then
  echo "▸ DRY-RUN (use --apply p/ gravar). Primeiras linhas:"
  head -8 "$SCRATCH/upsert.sql"
  exit 0
fi

# ── 3. APPLY no banco do doc hub (nosso banco; proxy próprio na 5455) ─────────
echo "▸ aplicando no banco do doc hub (prod)…"
PROXY=/tmp/claude-1000/-home-alessandro-portal-tecnologia/656efbd7-5d0e-43bf-8c85-ba78f8e724c4/scratchpad/cloud-sql-proxy
"$PROXY" --port 5455 --token "$(gcloud auth print-access-token)" \
  portal-tecnologia-500920:southamerica-east1:portal-identity-pg >/dev/null 2>&1 &
PP=$!
sleep 4
CS="$(gcloud secrets versions access latest --secret=doctor-hub-db-connection)"
PGPASSWORD="$(sed -E 's/.*Password=([^;]*).*/\1/' <<<"$CS")" \
  psql -h localhost -p 5455 -U doctorhub -d doctorhub -v ON_ERROR_STOP=1 -f "$SCRATCH/upsert.sql"
PGPASSWORD="$(sed -E 's/.*Password=([^;]*).*/\1/' <<<"$CS")" \
  psql -h localhost -p 5455 -U doctorhub -d doctorhub -Atc \
  "SELECT count(*) || ' clientes com external_id (HCs importados)' FROM clientes WHERE external_id IS NOT NULL;"
kill "$PP" 2>/dev/null || true
echo "✓ importação concluída."
