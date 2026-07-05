"""
Helper comum dos harnesses de homologação E2E (D-153) — login OIDC (2 etapas, I-003) + API.

Zero segredo no código: credenciais vêm de env (E2E_ADMIN_USER/E2E_ADMIN_PASS) ou do arquivo
gitignored `.e2e-env` ao lado deste script. Cada harness importa `login_token`, `api`, `check`,
`report`, `cpf_valido` e monta seu próprio fluxo (criar → reler → editar → excluir), afirmando
PERSISTÊNCIA contra a API + Keycloak REAIS. Ver 25-definicao-de-pronto-e2e.md.
"""
import base64
import hashlib
import http.cookiejar
import json
import os
import re
import secrets
import sys
import urllib.parse
import urllib.request

KC = os.environ.get("KC_BASE", "https://id.portaltecnologia.app.br")
API = os.environ.get("API_BASE", "https://api.portaltecnologia.app.br/api")
REALM = os.environ.get("KC_REALM", "portal")
CLIENT = os.environ.get("KC_CLIENT", "doctor-hub-web")
REDIRECT = os.environ.get("KC_REDIRECT", "https://doctorhub.app.br/")


def _load_creds():
    u, p = os.environ.get("E2E_ADMIN_USER"), os.environ.get("E2E_ADMIN_PASS")
    if u and p:
        return u, p
    env = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".e2e-env")
    if os.path.exists(env):
        for line in open(env):
            if line.startswith("E2E_ADMIN_USER="):
                u = line.split("=", 1)[1].strip()
            elif line.startswith("E2E_ADMIN_PASS="):
                p = line.split("=", 1)[1].strip()
    return u, p


_failures = []


def check(cond, msg):
    ok = bool(cond)
    print(f"  [{'✓' if ok else '✗ FALHOU'}] {msg}")
    if not ok:
        _failures.append(msg)
    return ok


def report(titulo):
    print("\n" + "═" * 52)
    if _failures:
        print(f"❌ {titulo} FALHOU — {len(_failures)} verificação(ões):")
        for f in _failures:
            print(f"   • {f}")
        sys.exit(1)
    print(f"✅ {titulo} PASSOU (contra prod)")


def cpf_valido():
    """CPF com dígitos verificadores corretos (o backend valida)."""
    n = [secrets.randbelow(10) for _ in range(9)]
    for _ in range(2):
        s = sum(v * w for v, w in zip(n, range(len(n) + 1, 1, -1)))
        d = 11 - (s % 11)
        n.append(0 if d >= 10 else d)
    return "".join(map(str, n))


def _b64url(b):
    return base64.urlsafe_b64encode(b).decode().rstrip("=")


def login_token():
    """Authorization Code + PKCE via o form de login (2 etapas: identificador, senha)."""
    user, pw = _load_creds()
    if not user or not pw:
        print("ERRO: defina E2E_ADMIN_USER/E2E_ADMIN_PASS (ou .e2e-env).", file=sys.stderr)
        sys.exit(2)
    jar = http.cookiejar.CookieJar()
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    verifier = _b64url(secrets.token_bytes(48))
    challenge = _b64url(hashlib.sha256(verifier.encode()).digest())
    auth = (f"{KC}/realms/{REALM}/protocol/openid-connect/auth?" + urllib.parse.urlencode({
        "client_id": CLIENT, "response_type": "code", "scope": "openid",
        "redirect_uri": REDIRECT, "state": "e2e", "code_challenge": challenge,
        "code_challenge_method": "S256"}))

    def action(html):
        m = re.search(r'action="([^"]+)"', html)
        return m.group(1).replace("&amp;", "&") if m else None

    def post(url, fields):
        data = urllib.parse.urlencode(fields).encode()
        try:
            r = op.open(urllib.request.Request(url, data=data))
            return r.read().decode(), r.geturl()
        except urllib.error.HTTPError as e:
            return e.read().decode(), (e.geturl() or "")
        except urllib.error.URLError as e:
            return "", getattr(e, "url", "") or ""

    html = op.open(auth).read().decode()
    a1 = action(html)
    if not a1:
        print("ERRO: form de login não encontrado.", file=sys.stderr)
        sys.exit(2)
    html2, _ = post(a1, {"username": user})
    a2 = action(html2)
    if not a2:
        print("ERRO: identificador rejeitado.", file=sys.stderr)
        sys.exit(2)
    _, final = post(a2, {"password": pw})
    m = re.search(r"[?&]code=([^&]+)", final or "")
    if not m:
        print("ERRO: senha inválida.", file=sys.stderr)
        sys.exit(2)
    tok = api_raw("POST", f"{KC}/realms/{REALM}/protocol/openid-connect/token", form={
        "client_id": CLIENT, "grant_type": "authorization_code", "code": m.group(1),
        "redirect_uri": REDIRECT, "code_verifier": verifier})
    return tok["access_token"]


def api_raw(method, url, token=None, body=None, form=None):
    headers, data = {}, None
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=headers, method=method)) as r:
            raw = r.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        return {"_status": e.code, "_body": e.read().decode()}


def api(method, path, token, body=None):
    """Chamada à API do doc hub. Retorna dict; erro vira {'_status','_body'}."""
    return api_raw(method, f"{API}{path}", token=token, body=body)
