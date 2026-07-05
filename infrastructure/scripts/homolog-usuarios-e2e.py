#!/usr/bin/env python3
"""
Homologação E2E da tela de USUÁRIOS (CRUD) — contra a API + Keycloak REAIS.

POR QUE EXISTE (2026-07-05): testes unitários usam a API mockada e passam mesmo quando o
dado NÃO dá a volta de verdade (ex.: o Keycloak descartava clienteId/unidade em silêncio — I-009).
"Pronto" de uma tela = ESTE harness passou. Ele cria um usuário DESCARTÁVEL, edita, adiciona
vínculo, desativa/reativa e exclui — afirmando persistência via GET a cada passo — e limpa no fim.

Uso:
  E2E_ADMIN_USER=admin-dh E2E_ADMIN_PASS='***' python3 homolog-usuarios-e2e.py
  (ou API_BASE / KC_BASE para apontar p/ outro ambiente; default = produção)

Sai com código != 0 em qualquer falha (serve p/ CI/pre-deploy smoke). Zero segredo no código.
"""
import base64
import hashlib
import http.cookiejar
import json
import os
import re
import secrets
import sys
import time
import urllib.parse
import urllib.request

KC = os.environ.get("KC_BASE", "https://id.portaltecnologia.app.br")
API = os.environ.get("API_BASE", "https://api.portaltecnologia.app.br/api")
REALM = os.environ.get("KC_REALM", "portal")
CLIENT = os.environ.get("KC_CLIENT", "doctor-hub-web")
REDIRECT = os.environ.get("KC_REDIRECT", "https://doctorhub.app.br/")
USER = os.environ.get("E2E_ADMIN_USER")
PASS = os.environ.get("E2E_ADMIN_PASS")
# Cliente/projeto usado no teste de vínculo (deve existir; default = HC do Piauí importado).
CLIENTE_VINCULO = os.environ.get("E2E_CLIENTE_ID", "C-a1c8e688")

falhas = []
def check(cond, msg):
    ok = bool(cond)
    print(f"  [{'✓' if ok else '✗ FALHOU'}] {msg}")
    if not ok:
        falhas.append(msg)
    return ok

def cpf_valido():
    """Gera um CPF com dígitos verificadores corretos (o backend valida — I-002/QA)."""
    n = [secrets.randbelow(10) for _ in range(9)]
    for _ in range(2):
        s = sum(v * w for v, w in zip(n, range(len(n) + 1, 1, -1)))
        d = 11 - (s % 11)
        n.append(0 if d >= 10 else d)
    return "".join(map(str, n))

def _b64url(b):
    return base64.urlsafe_b64encode(b).decode().rstrip("=")

def login_token():
    """OIDC Authorization Code + PKCE via o form de login do Keycloak (mesmo caminho do app)."""
    if not USER or not PASS:
        print("ERRO: defina E2E_ADMIN_USER e E2E_ADMIN_PASS (nunca hardcode).", file=sys.stderr)
        sys.exit(2)
    jar = http.cookiejar.CookieJar()
    # Segue redirects normalmente; o code sai na URL final (doctorhub?code=...) — mais robusto
    # que interceptar Location.
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    verifier = _b64url(secrets.token_bytes(48))
    challenge = _b64url(hashlib.sha256(verifier.encode()).digest())
    auth = (f"{KC}/realms/{REALM}/protocol/openid-connect/auth?" + urllib.parse.urlencode({
        "client_id": CLIENT, "response_type": "code", "scope": "openid",
        "redirect_uri": REDIRECT, "state": "e2e", "code_challenge": challenge,
        "code_challenge_method": "S256"}))
    def form_action(html):
        m = re.search(r'action="([^"]+)"', html)
        return m.group(1).replace("&amp;", "&") if m else None

    def post_form(action, fields):
        """POST no form; devolve (html, final_url). URLError = redirect p/ host externo (code na URL)."""
        data = urllib.parse.urlencode(fields).encode()
        try:
            resp = op.open(urllib.request.Request(action, data=data))
            return resp.read().decode(), resp.geturl()
        except urllib.error.HTTPError as e:
            return e.read().decode(), (e.geturl() or "")
        except urllib.error.URLError as e:
            return "", getattr(e, "url", "") or ""

    # Fluxo de login em DUAS etapas (I-003): (1) identificador, (2) senha.
    html = op.open(auth).read().decode()
    action1 = form_action(html)
    if not action1:
        print("ERRO: form de login (etapa 1) não encontrado.", file=sys.stderr)
        sys.exit(2)
    html2, _ = post_form(action1, {"username": USER})
    action2 = form_action(html2)
    if not action2:
        print("ERRO: form de senha (etapa 2) não encontrado — identificador rejeitado?", file=sys.stderr)
        sys.exit(2)
    _, final_url = post_form(action2, {"password": PASS})
    # O code de autorização vem SÓ como parâmetro code na redirect_uri (evita casar session_code).
    m = re.search(r"[?&]code=([^&]+)", final_url or "")
    if not m:
        print("ERRO: login falhou (senha inválida?).", file=sys.stderr)
        sys.exit(2)
    tok = api_raw("POST", f"{KC}/realms/{REALM}/protocol/openid-connect/token", form={
        "client_id": CLIENT, "grant_type": "authorization_code", "code": m.group(1),
        "redirect_uri": REDIRECT, "code_verifier": verifier})
    return tok["access_token"]

def api_raw(method, url, token=None, body=None, form=None):
    headers = {}
    data = None
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        return {"_status": e.code, "_body": raw}

def api(method, path, token, body=None):
    return api_raw(method, f"{API}{path}", token=token, body=body)

def main():
    print(f"E2E Usuários · API={API} · realm={REALM}")
    token = login_token()
    print("  login admin OK")

    sufixo = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))
    cpf = cpf_valido()
    email = f"e2e-homolog-{sufixo}@doctorhub.local"  # domínio não-entregável: sem e-mail real
    novo = {"nome": f"E2E Teste {sufixo}", "email": email, "cpf": cpf,
            "telefone": "11987654321", "papeis": ["demandas"]}
    uid = None
    try:
        # 1. CREATE
        print("\n1) CRIAR")
        r = api("POST", "/admin/users", token, novo)
        check("_status" not in r, f"POST 2xx (retorno: {r.get('_body', r)[:80] if '_status' in r else 'ok'})")
        uid = r.get("id")
        check(uid, "usuário criado tem id")
        check(r.get("email") == email, "e-mail retornado bate")
        check(set(r.get("papeis", [])) == {"demandas"}, "papel 'demandas' atribuído")

        # 2. READ-BACK pela LISTA (o que a tela usa)
        print("\n2) LER DE VOLTA (lista)")
        lst = api("GET", "/admin/users?page=1&pageSize=50", token)
        achado = next((u for u in lst.get("itens", []) if u.get("id") == uid), None)
        check(achado, "aparece na listagem")
        if achado:
            check(achado.get("cpf") == cpf, "CPF persistiu")
            check(achado.get("email") == email, "e-mail persistiu")

        # 3. UPDATE — muda nome + adiciona VÍNCULO (o bug do I-009)
        print("\n3) EDITAR (nome + vínculo cliente/unidade)")
        upd = dict(novo)
        upd["nome"] = f"E2E Editado {sufixo}"
        upd["clienteId"] = CLIENTE_VINCULO
        upd["unidade"] = "Núcleo E2E"
        r = api("PUT", f"/admin/users/{uid}", token, upd)
        check("_status" not in r, f"PUT 2xx ({r.get('_body','ok')[:80] if '_status' in r else 'ok'})")
        # o critério de ouro: reabrir e conferir que o VÍNCULO persistiu
        lst = api("GET", "/admin/users?page=1&pageSize=50", token)
        achado = next((u for u in lst.get("itens", []) if u.get("id") == uid), None)
        check(achado and achado.get("nome") == upd["nome"], "nome editado persistiu")
        check(achado and achado.get("clienteId") == CLIENTE_VINCULO, "VÍNCULO clienteId persistiu (I-009)")
        check(achado and achado.get("unidade") == "Núcleo E2E", "unidade persistiu")

        # 4. DESATIVAR / REATIVAR
        print("\n4) DESATIVAR / REATIVAR")
        api("POST", f"/admin/users/{uid}/deactivate", token)
        u = api("GET", f"/admin/users/{uid}", token)
        check(u.get("ativo") is False, "ficou inativo")
        api("POST", f"/admin/users/{uid}/activate", token)
        u = api("GET", f"/admin/users/{uid}", token)
        check(u.get("ativo") is True, "voltou a ativo")

        # 5. VALIDAÇÃO: CPF inválido deve ser REJEITADO (não salvar lixo)
        print("\n5) VALIDAÇÃO (CPF inválido rejeitado)")
        r = api("PUT", f"/admin/users/{uid}", token, {**upd, "cpf": "11111111111"})
        check(r.get("_status") == 400, f"CPF inválido → 400 (got {r.get('_status', '2xx')})")

    finally:
        # 6. LIMPEZA — excluir o usuário de teste (idempotente)
        if uid:
            print("\n6) EXCLUIR (limpeza)")
            r = api_raw("DELETE", f"{API}/admin/users/{uid}", token=token)
            gone = api("GET", f"/admin/users/{uid}", token)
            check(gone.get("_status") == 404, "excluído (GET → 404)")

    print("\n" + "═" * 48)
    if falhas:
        print(f"❌ HOMOLOGAÇÃO FALHOU — {len(falhas)} verificação(ões):")
        for f in falhas:
            print(f"   • {f}")
        sys.exit(1)
    print("✅ HOMOLOGAÇÃO E2E DE USUÁRIOS PASSOU (CRUD + vínculo + validação, contra prod)")

if __name__ == "__main__":
    main()
