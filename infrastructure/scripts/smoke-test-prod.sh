#!/usr/bin/env bash
# Smoke test do IdP em produção (D-143 / P-006). Uso: KC_URL=https://...run.app bash smoke-test-prod.sh
set -euo pipefail
: "${KC_URL:?defina KC_URL}"
REALM="${REALM:-portal}"
ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }
FAIL=0

echo "Smoke test: $KC_URL (realm $REALM)"
curl -fsS -o /dev/null "$KC_URL/health/ready" && ok "health/ready 200" || bad "health/ready falhou"
curl -fsS -o /dev/null "$KC_URL/realms/$REALM/.well-known/openid-configuration" \
  && ok "discovery OIDC do realm $REALM" || bad "discovery falhou"
# Tela de conta (valida tema + flows acessíveis a um humano).
curl -fsS -o /dev/null "$KC_URL/realms/$REALM/account" && ok "account console acessível" || bad "account console falhou"
# O realm exige login por CPF/telefone + OTP? confere o browserFlow ativo via well-known (indireto): só checa que responde.
[ "$FAIL" = 0 ] && echo "✓ IdP no ar e respondendo." || { echo "✗ algo falhou — veja os logs do Cloud Run."; exit 1; }
