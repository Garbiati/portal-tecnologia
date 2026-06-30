#!/usr/bin/env bash
# Cria o 1º ADMIN do realm `portal` em PRODUÇÃO e dispara o convite por e-mail (D-143 / P-006).
# Usa o admin bootstrap do Keycloak (senha no Secret Manager) — roda UMA vez, após o deploy.
# PII (CPF/telefone) NÃO fica no git: vem por variável de ambiente no momento de rodar.
#
# Uso:
#   KC_URL=https://portal-identity-xxxx.run.app \
#   ADMIN_NOME="Alessandro Garbiati" ADMIN_EMAIL=voce@gmail.com \
#   ADMIN_CPF=00000000000 ADMIN_TELEFONE=11999999999 \
#   bash infrastructure/scripts/criar-admin-prod.sh
set -euo pipefail

: "${KC_URL:?defina KC_URL (output keycloak_url do terraform)}"
: "${ADMIN_NOME:?defina ADMIN_NOME}"
: "${ADMIN_EMAIL:?defina ADMIN_EMAIL}"
: "${ADMIN_CPF:?defina ADMIN_CPF (só dígitos)}"
: "${ADMIN_TELEFONE:?defina ADMIN_TELEFONE (só dígitos)}"
REALM="${REALM:-portal}"
BOOT_USER="${KEYCLOAK_ADMIN:-admin}"

CPF_DIG="$(printf '%s' "$ADMIN_CPF" | tr -cd 0-9)"
TEL_DIG="$(printf '%s' "$ADMIN_TELEFONE" | tr -cd 0-9)"
FIRST="${ADMIN_NOME%% *}"; LAST="${ADMIN_NOME#* }"; [ "$LAST" = "$ADMIN_NOME" ] && LAST=""

echo "▸ lendo a senha do admin bootstrap no Secret Manager…"
BOOT_PASS="$(gcloud secrets versions access latest --secret=portal-identity-admin-password)"

echo "▸ obtendo token do admin master…"
TOK="$(curl -fsS -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d client_id=admin-cli -d "username=$BOOT_USER" -d "password=$BOOT_PASS" -d grant_type=password \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')"

echo "▸ resolvendo o client doctor-hub-api e o papel admin…"
CUUID="$(curl -fsS "$KC_URL/admin/realms/$REALM/clients?clientId=doctor-hub-api" -H "Authorization: Bearer $TOK" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["id"])')"
ROLE="$(curl -fsS "$KC_URL/admin/realms/$REALM/clients/$CUUID/roles/admin" -H "Authorization: Bearer $TOK")"

echo "▸ criando o usuário admin (username = CPF)…"
CODE="$(curl -fsS -o /tmp/criaadmin.out -w '%{http_code}' -X POST "$KC_URL/admin/realms/$REALM/users" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d @- <<JSON
{ "username": "$CPF_DIG", "firstName": "$FIRST", "lastName": "$LAST", "email": "$ADMIN_EMAIL",
  "enabled": true, "emailVerified": false,
  "attributes": { "cpf": ["$CPF_DIG"], "telefone": ["$TEL_DIG"] } }
JSON
)"
if [ "$CODE" = "409" ]; then echo "  (usuário já existe — seguindo p/ papel + convite)"; fi
[ "$CODE" = "201" ] || [ "$CODE" = "409" ] || { echo "✗ falha ao criar (HTTP $CODE): $(cat /tmp/criaadmin.out)"; exit 1; }

UID_KC="$(curl -fsS "$KC_URL/admin/realms/$REALM/users?username=$CPF_DIG&exact=true" -H "Authorization: Bearer $TOK" \
  | python3 -c 'import sys,json;u=json.load(sys.stdin);print(u[0]["id"] if u else "")')"
[ -n "$UID_KC" ] || { echo "✗ não achei o usuário recém-criado"; exit 1; }

echo "▸ atribuindo o papel admin…"
curl -fsS -X POST "$KC_URL/admin/realms/$REALM/users/$UID_KC/role-mappings/clients/$CUUID" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d "[$ROLE]" >/dev/null

echo "▸ enviando o convite (definir senha) por e-mail…"
curl -fsS -X PUT "$KC_URL/admin/realms/$REALM/users/$UID_KC/execute-actions-email?client_id=account-console&redirect_uri=$KC_URL/realms/$REALM/account&lifespan=86400" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d '["UPDATE_PASSWORD"]' >/dev/null

echo "✓ admin criado e convite enviado para $ADMIN_EMAIL. Abra o e-mail, defina a senha e entre em:"
echo "  $KC_URL/realms/$REALM/account"
