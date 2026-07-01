#!/usr/bin/env bash
# Importa o realm `portal` de PRODUÇÃO uma vez, via Admin API (D-143 / P-006).
# Motivo: `kc.sh start --optimized` ignora `--import-realm`; então fazemos o import como passo de
# deploy (idempotente: se o realm já existe, não faz nada → preserva usuários criados em runtime).
# Segredos vêm do Secret Manager (nunca impressos). Substitui os ${ENV} do realm com os valores de prod.
#
# Uso: KC_URL=https://...run.app bash infrastructure/scripts/importar-realm-prod.sh
set -euo pipefail

: "${KC_URL:?defina KC_URL (terraform output -raw idp_url)}"
REALM="${REALM:-portal}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REALM_SRC="$ROOT/services/portal-identity/realms-prod/portal-realm.json"
TFVARS="$ROOT/infrastructure/terraform/terraform.tfvars"
[ -f "$REALM_SRC" ] || { echo "✗ realm não encontrado: $REALM_SRC"; exit 1; }

val() { grep -E "^\s*$1\s*=" "$TFVARS" | head -1 | sed -E 's/^[^=]*=\s*"?([^"#]*)"?.*/\1/' | xargs; }
SMTP_FROM="$(val smtp_from)"
FRONT_BASE_URL="$(val front_base_url)"
SMTP_HOST="$(val smtp_host)"; SMTP_HOST="${SMTP_HOST:-smtp.gmail.com}"
SMTP_PORT="$(val smtp_port)"; SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER_V="$(val smtp_user)"; SMTP_USER_V="${SMTP_USER_V:-$SMTP_FROM}"

# Segredos (não impressos).
SMTP_PASSWORD="$(gcloud secrets versions access latest --secret=portal-identity-smtp-password)"
ADMIN_CLIENT_SECRET="$(gcloud secrets versions access latest --secret=portal-identity-admin-client-secret)"

# Porta 465 = SSL; caso contrário STARTTLS (ex.: 587).
if [ "$SMTP_PORT" = "465" ]; then SMTP_SSL=true; SMTP_STARTTLS=false; else SMTP_SSL=false; SMTP_STARTTLS=true; fi

# Substitui os placeholders num arquivo temporário (removido no fim).
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
SMTP_HOST="$SMTP_HOST" SMTP_PORT="$SMTP_PORT" SMTP_FROM_DISPLAY="Portal Telemedicina" \
SMTP_USER="$SMTP_USER_V" SMTP_AUTH=true SMTP_STARTTLS="$SMTP_STARTTLS" SMTP_SSL="$SMTP_SSL" \
SMTP_FROM="$SMTP_FROM" FRONT_BASE_URL="$FRONT_BASE_URL" \
SMTP_PASSWORD="$SMTP_PASSWORD" ADMIN_CLIENT_SECRET="$ADMIN_CLIENT_SECRET" \
python3 - "$REALM_SRC" "$TMP" <<'PY'
import os, re, sys
src, out = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
t = re.sub(r"\$\{([A-Z_]+)\}", lambda m: os.environ.get(m.group(1), m.group(0)), t)
open(out, "w", encoding="utf-8").write(t)
PY

# Token do admin bootstrap (senha no Secret Manager).
BOOT_PASS="$(gcloud secrets versions access latest --secret=portal-identity-admin-password)"
TOK="$(curl -fsS -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d client_id=admin-cli -d "username=${KEYCLOAK_ADMIN:-admin}" -d "password=$BOOT_PASS" -d grant_type=password \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')"

# Idempotente: se o realm já existe, não reimporta.
if curl -fsS -o /dev/null "$KC_URL/realms/$REALM/.well-known/openid-configuration" 2>/dev/null; then
  echo "✓ realm '$REALM' já existe — nada a fazer."
  exit 0
fi

echo "▸ importando realm '$REALM'…"
CODE="$(curl -sS -o /tmp/imp.out -w '%{http_code}' -X POST "$KC_URL/admin/realms" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' --data-binary @"$TMP")"
if [ "$CODE" = "201" ]; then
  echo "✓ realm '$REALM' importado."
else
  echo "✗ falha ao importar (HTTP $CODE): $(cat /tmp/imp.out)"; exit 1
fi
