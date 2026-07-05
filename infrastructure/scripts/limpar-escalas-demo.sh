#!/usr/bin/env bash
# Remove as 6 escalas de DEMONSTRAÇÃO semeadas em 2026-07-05 (madrugada) para o painel
# de capacidade real. Uso: TOKEN=<bearer de um usuário demandas/admin> ./limpar-escalas-demo.sh
set -euo pipefail
API=https://api.portaltecnologia.app.br/api
[ -n "${TOKEN:-}" ] || { echo "defina TOKEN=<access token>"; exit 1; }
while read -r ID; do
  [ -n "$ID" ] || continue
  code=$(curl -sS -X DELETE "$API/escalas/$ID" -H "Authorization: Bearer $TOKEN" -o /dev/null -w '%{http_code}')
  echo "$ID → $code"
done < "$(dirname "$0")/escalas-demo-ids.txt"
