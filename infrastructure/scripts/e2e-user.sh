#!/usr/bin/env bash
# =============================================================================
# e2e-user.sh — provisiona/remove a conta EFÊMERA de automação dos harnesses E2E.
#
# Os harnesses (homolog-*-e2e.py) precisam de um login com todos os papéis. Em vez de
# deixar uma conta de bot parada no realm (o Alessandro quer só o usuário dele), este
# script cria a conta SÓ na hora de rodar e a remove depois:
#
#   ./e2e-user.sh up      # cria e2e-homolog (papéis admin/demandas/regulacao/gestor) + grava .e2e-env
#   <roda os harnesses>
#   ./e2e-user.sh down    # apaga a conta e remove .e2e-env  → realm volta a ter só o dono
#
# Zero segredo no código: senha aleatória por execução, gravada só no .e2e-env (gitignored).
# =============================================================================
set -euo pipefail
KC="https://id.portaltecnologia.app.br"
HERE="$(cd "$(dirname "$0")" && pwd)"
ENVF="$HERE/.e2e-env"
CMD="${1:-}"

atoken() {
  local boot; boot="$(gcloud secrets versions access latest --secret=portal-identity-admin-password)"
  curl -sS -X POST "$KC/realms/master/protocol/openid-connect/token" \
    -d client_id=admin-cli -d username=admin -d "password=$boot" -d grant_type=password \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
}

case "$CMD" in
  up)
    ATOK="$(atoken)"; PW="$(openssl rand -base64 18)"
    python3 - "$KC" "$ATOK" "$PW" "$ENVF" <<'PY'
import json, sys, urllib.request
KC, ATOK, PW, ENVF = sys.argv[1:5]
def req(m, p, b=None):
    r = urllib.request.Request(f"{KC}/admin/realms/portal{p}", method=m,
        headers={"Authorization": f"Bearer {ATOK}", "Content-Type": "application/json"},
        data=json.dumps(b).encode() if b is not None else None)
    try:
        with urllib.request.urlopen(r) as x: raw=x.read().decode(); return x.status,(json.loads(raw) if raw else None),x.headers
    except urllib.error.HTTPError as e: return e.code, e.read().decode(), e.headers
st,_,hdr = req("POST","/users",{"username":"e2e-homolog","enabled":True,"email":"e2e-homolog@doctorhub.local",
    "firstName":"E2E","lastName":"Homolog","emailVerified":True,"attributes":{"cpf":["11144477735"],"telefone":["11987654321"]}})
uid = hdr["Location"].rstrip("/").split("/")[-1] if st==201 else req("GET","/users?username=e2e-homolog")[1][0]["id"]
req("PUT",f"/users/{uid}/reset-password",{"type":"password","value":PW,"temporary":False})
cuid = req("GET","/clients?clientId=doctor-hub-api")[1][0]["id"]
roles = [r for r in req("GET",f"/clients/{cuid}/roles")[1] if r["name"] in ("admin","demandas","regulacao","gestor")]
req("POST",f"/users/{uid}/role-mappings/clients/{cuid}",roles)
open(ENVF,"w").write(f"E2E_ADMIN_USER=e2e-homolog\nE2E_ADMIN_PASS={PW}\nE2E_UID={uid}\n")
print("✓ e2e-homolog provisionado (papéis:", ",".join(r["name"] for r in roles)+") · .e2e-env gravado")
PY
    ;;
  down)
    [ -f "$ENVF" ] || { echo "sem .e2e-env — nada a remover"; exit 0; }
    UID_E2E="$(grep '^E2E_UID=' "$ENVF" | cut -d= -f2)"
    ATOK="$(atoken)"
    code=$(curl -sS -X DELETE "$KC/admin/realms/portal/users/$UID_E2E" -H "Authorization: Bearer $ATOK" -o /dev/null -w '%{http_code}')
    rm -f "$ENVF"
    echo "✓ e2e-homolog removido ($code) · .e2e-env apagado"
    ;;
  *) echo "uso: $0 {up|down}" >&2; exit 2 ;;
esac
