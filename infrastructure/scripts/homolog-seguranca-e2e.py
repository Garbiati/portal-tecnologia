#!/usr/bin/env python3
"""
Sonda de AUTORIZAÇÃO/ESCOPO da API do Doctor-Hub em PRODUÇÃO — relatório de risco (AppSec).

POR QUE EXISTE: a matriz papel×ação×escopo (D-142) NÃO está confirmada. Este harness NÃO afirma
pass/fail contra ela — ele MEDE o que a API realmente permite hoje e reporta cada comportamento como
"RISCO A CONFIRMAR" com a expectativa provável (docs/product/27-seguranca-gestao-de-risco.md · G-1..G-4).
Complementa os homolog-*-e2e.py (que provam PERSISTÊNCIA); aqui a pergunta é LIMITE, não persistência.

O QUE FAZ:
  1. PROVISIONA (Keycloak master admin, mesma trilha do e2e-user.sh) usuários EFÊMEROS `sec-*` com
     papel/escopo específico e senha conhecida não-temporária:
        sec-demandas (só demandas) · sec-rega (regulacao, clienteId=A) · sec-regb (regulacao,
        clienteId=B) · sec-gestor (gestor).
  2. LOGA cada um (fluxo OIDC 2-etapas reusado de e2e_common, parametrizado por user/senha) e SONDA:
        · Vertical  (elevação de privilégio): papel comum tenta endpoints de ADMIN.
        · Horizontal (escopo de cliente, G-1): regA lê/altera dado do cliente de regB.
        · LGPD/escopo (G-3): qualquer papel faz GET /agendamentos (lista global de iniciais).
        · Não autenticado: chamadas sem token → 401?
        · RBAC (G-2): quem consegue POST /solicitacoes, POST /doctors/{id}/escalas, DELETE destrutivo.
     Sondas destrutivas usam id FALSO ou corpo INVÁLIDO de propósito: 403=bloqueado (limite existe),
     404/400=chegou no handler (limite NÃO aplicado) — mede autorização SEM mutar/criar dado real.
  3. RELATÓRIO em texto: tabela (ator → ação → status observado → é RISCO? severidade) + resumo dos
     RISCOS ALTOS com evidência. Sempre sai 0 (é medição, não pass/fail).
  4. LIMPA: cancela as solicitações de teste (não há DELETE — vira CANCELADO) e EXCLUI todos os `sec-*`.
     Idempotente: uma nova execução varre `sec-*` residual. O realm volta a ter só o dono.

Uso:  cd infrastructure/scripts && python3 homolog-seguranca-e2e.py
Zero segredo no código: senha do master admin vem do Secret Manager (gcloud); senhas dos sec-* são
aleatórias por execução e ficam só em memória.
"""
import json
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.request

import e2e_common
from e2e_common import API, api_raw, cpf_valido

KC = os.environ.get("KC_BASE", "https://id.portaltecnologia.app.br")
REALM = os.environ.get("KC_REALM", "portal")
ADMIN_SECRET = os.environ.get("KC_ADMIN_SECRET", "portal-identity-admin-password")
DONO_USERNAME = "35922911813"  # Alessandro — o ÚNICO usuário humano que deve sobrar no realm.

SUF = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))

# ─────────────────────────────────────────────────────────────────────────────
# Coleta de achados. risk ∈ {ALTO, MÉDIO, BAIXO, OK, INFO}. Nada aqui é "fail" —
# é medição. OK = comportamento esperado observado; os demais = risco a confirmar.
# ─────────────────────────────────────────────────────────────────────────────
findings = []  # (ator, acao, status, risk, esperado)


def add(ator, acao, status, risk, esperado=""):
    findings.append((ator, acao, str(status), risk, esperado))
    tag = "" if risk in ("OK", "INFO") else f"   <<< RISCO {risk}"
    print(f"    [{ator:11}] {acao:54} -> {str(status):5}{tag}")


# ── Keycloak master admin (idêntico ao e2e-user.sh: gcloud secret + password grant) ──
def sh(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True).stdout.strip()


def kc_admin_token():
    boot = sh(f"gcloud secrets versions access latest --secret={ADMIN_SECRET}")
    r = api_raw("POST", f"{KC}/realms/master/protocol/openid-connect/token", form={
        "client_id": "admin-cli", "username": "admin", "password": boot, "grant_type": "password"})
    if "access_token" not in r:
        print(f"ERRO: token admin do Keycloak falhou: {r}", file=sys.stderr)
        sys.exit(2)
    return r["access_token"]


ATOK = None


def kc(method, path, body=None):
    """Chamada à Admin REST API do realm portal. Retorna (status, json|texto, headers)."""
    req = urllib.request.Request(f"{KC}/admin/realms/{REALM}{path}", method=method,
        headers={"Authorization": f"Bearer {ATOK}", "Content-Type": "application/json"},
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as x:
            raw = x.read().decode()
            return x.status, (json.loads(raw) if raw else None), x.headers
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(), e.headers


def client_uuid():
    _, data, _ = kc("GET", "/clients?clientId=doctor-hub-api")
    return data[0]["id"]


def roles_for(cuid, names):
    _, data, _ = kc("GET", f"/clients/{cuid}/roles")
    return [r for r in data if r["name"] in names]


created_uids = []
_sec_pw = {}  # senhas geradas na provisão — só em memória, nunca em disco.


def _senha():
    # Aleatória por execução; sufixo garante classes de caractere se houver política de senha.
    return secrets.token_urlsafe(20) + "Aa1!"


def provision(username, first, role_names, cuid, cliente_id=None, unidade=None):
    pw = _senha()
    attrs = {"cpf": [cpf_valido()], "telefone": ["11987654321"]}
    if cliente_id:
        attrs["clienteId"] = [cliente_id]
    if unidade:
        attrs["unidade"] = [unidade]
    body = {"username": username, "enabled": True, "emailVerified": True,
            "email": f"{username}-{SUF}@doctorhub.local", "firstName": first, "lastName": "SecE2E",
            "requiredActions": [], "attributes": attrs}
    st, data, hdr = kc("POST", "/users", body)
    if st == 201:
        uid = hdr["Location"].rstrip("/").split("/")[-1]
    elif st == 409:  # resíduo de execução anterior — reaproveita
        _, ex, _ = kc("GET", f"/users?username={username}&exact=true")
        uid = ex[0]["id"]
    else:
        print(f"ERRO ao criar {username}: {st} {data}", file=sys.stderr)
        return None, None
    kc("PUT", f"/users/{uid}/reset-password", {"type": "password", "value": pw, "temporary": False})
    kc("POST", f"/users/{uid}/role-mappings/clients/{cuid}", roles_for(cuid, role_names))
    created_uids.append(uid)
    _sec_pw[username] = pw
    return uid, pw


def login_as(username, pw):
    """Reusa o login OIDC 2-etapas de e2e_common, parametrizado por env. None se falhar (não aborta)."""
    os.environ["E2E_ADMIN_USER"] = username
    os.environ["E2E_ADMIN_PASS"] = pw
    try:
        return e2e_common.login_token()
    except SystemExit:
        return None


def call(token, method, path, body=None):
    """(status, payload). 2xx → (200, dado); erro → (código, corpo)."""
    r = api_raw(method, f"{API}{path}", token=token, body=body)
    if isinstance(r, dict) and "_status" in r:
        return r["_status"], r.get("_body", "")
    return 200, r


def purge_sec_users():
    """Exclui TODO usuário username^='sec-'. Idempotente. Devolve o roster final de usernames."""
    _, data, _ = kc("GET", "/users?max=1000")
    if isinstance(data, list):
        for u in data:
            if str(u.get("username", "")).startswith("sec-"):
                kc("DELETE", f"/users/{u['id']}")
    _, data2, _ = kc("GET", "/users?max=1000")
    return [u.get("username") for u in data2] if isinstance(data2, list) else []


FAKE_C = "C-000nao-existe"
FAKE_GUID = "00000000-0000-0000-0000-000000000000"


def main():
    global ATOK
    print(f"SONDA DE SEGURANÇA (autorização/escopo) · API={API} · realm={REALM}")
    print("  NOTA: mede o comportamento atual como RISCO A CONFIRMAR — a matriz D-142 não está fechada.\n")

    ATOK = kc_admin_token()
    cuid = client_uuid()
    print("  ✓ Keycloak master admin OK · client doctor-hub-api =", cuid[:8], "…")

    tokens = {}
    sidA = sidB = None
    try:
        # ── 1) PROVISIONA sec-demandas e loga p/ escolher 2 clientes reais (A, B) ──
        print("\n1) PROVISIONAMENTO + DESCOBERTA DE ESCOPO")
        provision("sec-demandas", "SecDemandas", ["demandas"], cuid)
        tokens["sec-demandas"] = login_as("sec-demandas", _sec_pw["sec-demandas"])
        if not tokens["sec-demandas"]:
            print("  ✗ login sec-demandas falhou — abortando sondas (limpeza segue).", file=sys.stderr)
            return
        st, clientes = call(tokens["sec-demandas"], "GET", "/clientes")
        clientes = clientes if isinstance(clientes, list) else []
        ativos = [c for c in clientes if c.get("ativo")] or clientes
        A, B = ativos[0], ativos[1]
        print(f"  ✓ cliente A = {A['sigla']} ({A['id']}) · cliente B = {B['sigla']} ({B['id']})")

        provision("sec-rega", "SecRegA", ["regulacao"], cuid, cliente_id=A["id"], unidade="Unidade Alpha")
        provision("sec-regb", "SecRegB", ["regulacao"], cuid, cliente_id=B["id"], unidade="Unidade Beta")
        provision("sec-gestor", "SecGestor", ["gestor"], cuid, cliente_id=A["id"], unidade="Unidade Alpha")
        for u in ("sec-rega", "sec-regb", "sec-gestor"):
            tokens[u] = login_as(u, _sec_pw[u])
            print(f"  {'✓' if tokens[u] else '✗'} login {u}")

        # doutor real p/ a sonda de escalas (id só é usado; corpo inválido não cria nada)
        _, docs = call(tokens["sec-demandas"], "GET", "/doctors")
        doc_id = docs[0]["id"] if isinstance(docs, list) and docs else FAKE_GUID

        # ── 2) VERTICAL — elevação de privilégio (papel comum → endpoints de ADMIN) ──
        # Esperado provável: 403 (só admin). 2xx/400/404 = chegou no handler = elevação.
        print("\n2) VERTICAL — elevação de privilégio (sec-demandas tenta ADMIN)")
        td = tokens["sec-demandas"]
        st, body = call(td, "GET", "/admin/users?page=1&pageSize=5")
        add("sec-demandas", "GET /admin/users (lista de usuários)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 (admin) — 2xx vaza a lista de usuários")
        st, _ = call(td, "POST", "/admin/users", {})
        add("sec-demandas", "POST /admin/users (criar usuário)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 — 400 já provou que alcançou o criar-usuário")
        st, _ = call(td, "POST", "/clientes", {"sigla": "", "nome": "", "natureza": "invalida"})
        add("sec-demandas", "POST /clientes (criar cliente)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 (admin)")
        st, _ = call(td, "PUT", f"/clientes/{FAKE_C}", {"sigla": "x", "nome": "x", "natureza": "publico"})
        add("sec-demandas", "PUT /clientes/{id} (editar cliente)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 — 404 provou que alcançou o editar")
        st, _ = call(td, "DELETE", f"/clientes/{FAKE_C}")
        add("sec-demandas", "DELETE /clientes/{id} (excluir cliente)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 — 404 provou que alcançou o excluir")
        # cruzamento: gestor/regulação também não deveriam ler a lista de usuários
        st, _ = call(tokens["sec-gestor"], "GET", "/admin/users?page=1&pageSize=5")
        add("sec-gestor", "GET /admin/users (lista de usuários)", st,
            "OK" if st == 403 else "ALTO", "esperado 403 (admin)")

        # ── 3) HORIZONTAL — escopo de cliente (G-1): regA ↔ dado de regB ──
        print("\n3) HORIZONTAL — vazamento entre clientes (G-1)")
        sA = {"clienteSigla": A["sigla"], "especialidade": "Cardiologia", "qtd": 1,
              "apelido": f"SEC-E2E-A-{SUF}", "aPartirDe": "05/07", "ate": "31/07", "retorno": 0}
        sB = {"clienteSigla": B["sigla"], "especialidade": "Cardiologia", "qtd": 1,
              "apelido": f"SEC-E2E-B-{SUF}", "aPartirDe": "05/07", "ate": "31/07", "retorno": 0}
        st, rA = call(tokens["sec-rega"], "POST", "/solicitacoes", sA)
        sidA = rA.get("id") if isinstance(rA, dict) else None
        add("sec-rega", f"POST /solicitacoes (cliente A={A['sigla']})", st, "INFO", "setup: cria dado de A")
        st, rB = call(tokens["sec-regb"], "POST", "/solicitacoes", sB)
        sidB = rB.get("id") if isinstance(rB, dict) else None
        add("sec-regb", f"POST /solicitacoes (cliente B={B['sigla']})", st, "INFO", "setup: cria dado de B")

        # regA LÊ /solicitacoes → enxerga o dado do cliente B?
        st, lst = call(tokens["sec-rega"], "GET", "/solicitacoes")
        lst = lst if isinstance(lst, list) else []
        ve_B = any(s.get("id") == sidB for s in lst)
        siglas_vis = sorted({s.get("clienteSigla") for s in lst if s.get("clienteSigla")})
        add("sec-rega", f"GET /solicitacoes (vê o cliente B? {ve_B}; {len(siglas_vis)} clientes na lista)",
            st, "ALTO" if ve_B else "OK",
            "esperado ver SÓ o cliente A — vê B = vazamento horizontal de leitura")

        # regA ALTERA a solicitação do cliente B (PATCH)?
        marca = f"SEC-E2E-XW-{SUF}"
        st, pr = call(tokens["sec-rega"], "PATCH", f"/solicitacoes/{sidB}", {"subEstado": marca})
        escreveu = st == 200
        # confirma pela ótica de B
        confirmado = False
        if escreveu and tokens.get("sec-regb"):
            _, lb = call(tokens["sec-regb"], "GET", "/solicitacoes")
            confirmado = any(s.get("id") == sidB and s.get("subEstado") == marca
                             for s in (lb if isinstance(lb, list) else []))
        add("sec-rega", f"PATCH /solicitacoes/{{B}} (alterar dado de B; confirmado={confirmado})",
            st, "ALTO" if escreveu else "OK",
            "esperado 403/404 (fora do escopo) — 2xx = escrita horizontal cross-cliente")

        # ── 4) LGPD / escopo de agendamentos (G-3) ──
        print("\n4) LGPD — GET /agendamentos global (G-3)")
        st, ld = call(tokens["sec-demandas"], "GET", "/agendamentos")
        n_dem = len(ld) if isinstance(ld, list) else 0
        st2, lg = call(tokens["sec-gestor"], "GET", "/agendamentos")
        n_ges = len(lg) if isinstance(lg, list) else 0
        # mesma contagem p/ papéis de escopos diferentes = lista global, sem filtro por unidade
        risco_g3 = "ALTO" if (st == 200 and n_dem == n_ges and n_dem > 0) else (
            "MÉDIO" if st == 200 else "OK")
        add("sec-demandas", f"GET /agendamentos (retorna {n_dem} itens — iniciais de paciente)", st,
            risco_g3, "esperado filtrar por unidade do token")
        add("sec-gestor", f"GET /agendamentos (retorna {n_ges} itens — mesma lista? {n_dem == n_ges})",
            st2, "INFO" if st2 == 200 else "MÉDIO",
            "contagem igual à de demandas = escopo por unidade NÃO aplicado")

        # ── 5) NÃO AUTENTICADO — sem token deve dar 401 ──
        print("\n5) NÃO AUTENTICADO (sem token → 401?)")
        for p in ["/clientes", "/solicitacoes", "/agendamentos", "/doctors", "/admin/users"]:
            st, _ = call(None, "GET", p)
            add("anon", f"GET {p} (sem token)", st,
                "OK" if st == 401 else "ALTO", "esperado 401")
        st, _ = call(None, "POST", "/solicitacoes", sA)
        add("anon", "POST /solicitacoes (sem token)", st, "OK" if st == 401 else "ALTO", "esperado 401")

        # ── 6) RBAC por papel em solicitações/escalas/destrutivos (G-2) ──
        # Corpo inválido de propósito: 400/404 = alcançou o handler (papel aceito) = RBAC não aplicado.
        print("\n6) RBAC por papel (G-2) — quem alcança o quê")
        st, _ = call(td, "POST", "/solicitacoes", {"clienteSigla": A["sigla"], "especialidade": "X", "qtd": 0})
        add("sec-demandas", "POST /solicitacoes (papel demandas)", st,
            "OK" if st == 403 else "MÉDIO", "prop. matriz: cria = Regulação — 400 = demandas alcança")
        st, _ = call(tokens["sec-gestor"], "POST", "/solicitacoes", {"clienteSigla": A["sigla"], "especialidade": "X", "qtd": 0})
        add("sec-gestor", "POST /solicitacoes (papel gestor)", st,
            "OK" if st == 403 else "MÉDIO", "prop. matriz: cria = Regulação — 400 = gestor alcança")

        escala_inv = {"especialidade": "Cardiologia", "tipo": "FLEX", "dias": [], "blocos": [],
                      "duracaoMin": 20, "vigencia": {"inicio": "2026-07-10", "fim": "2026-07-11"}}
        st, er = call(tokens["sec-rega"], "POST", f"/doctors/{doc_id}/escalas", escala_inv)
        if st == 200 and isinstance(er, dict) and er.get("id"):  # criou por acaso → limpa
            call(tokens["sec-rega"], "DELETE", f"/escalas/{er['id']}")
        add("sec-rega", "POST /doctors/{id}/escalas (papel regulacao)", st,
            "OK" if st == 403 else "MÉDIO", "prop. matriz: cria escala = Demandas/Admin — 400 = alcança")
        st, er = call(tokens["sec-gestor"], "POST", f"/doctors/{doc_id}/escalas", escala_inv)
        if st == 200 and isinstance(er, dict) and er.get("id"):
            call(tokens["sec-gestor"], "DELETE", f"/escalas/{er['id']}")
        add("sec-gestor", "POST /doctors/{id}/escalas (papel gestor)", st,
            "OK" if st == 403 else "MÉDIO", "prop. matriz: cria escala = Demandas/Admin — 400 = alcança")

        # destrutivos sensíveis: DELETE escala e PUT ficha do médico (PII/CPF) — id falso, sem mutar
        st, _ = call(tokens["sec-rega"], "DELETE", f"/escalas/{FAKE_GUID}")
        add("sec-rega", "DELETE /escalas/{id} (excluir escala)", st,
            "OK" if st == 403 else "ALTO", "esperado restrito — 404 = qualquer autenticado alcança o excluir")
        st, _ = call(tokens["sec-gestor"], "PUT", f"/doctors/{FAKE_GUID}", {"cpf": "12345678909"})
        add("sec-gestor", "PUT /doctors/{id} (editar ficha/CPF do médico)", st,
            "OK" if st == 403 else "MÉDIO", "esperado restrito — 404 = qualquer autenticado alcança editar PII")

    finally:
        # ── 7) LIMPEZA — cancela dados de teste + exclui todos os sec-* ──
        print("\n7) LIMPEZA")
        for sid, tk in ((sidA, tokens.get("sec-rega")), (sidB, tokens.get("sec-regb"))):
            if sid and tk:
                call(tk, "PATCH", f"/solicitacoes/{sid}", {"status": "CANCELADO"})
                print(f"  · solicitação de teste {sid} → CANCELADO (não há DELETE no contrato)")
        roster = purge_sec_users()
        secs = [u for u in roster if str(u).startswith("sec-")]
        print(f"  · usuários sec-* removidos · restam no realm: {roster}")
        if secs:
            print(f"  ⚠ AINDA HÁ sec-* no realm: {secs} — reexecute a limpeza!")
        elif DONO_USERNAME in roster:
            print(f"  ✓ realm limpo de sec-* (dono {DONO_USERNAME} presente)")

    _relatorio()


def _relatorio():
    print("\n" + "═" * 100)
    print("RELATÓRIO DE RISCO — AUTORIZAÇÃO/ESCOPO (Doctor-Hub API · prod)")
    print("Cada linha = comportamento MEDIDO. 'Risco' = A CONFIRMAR contra a matriz D-142 (não fechada).")
    print("═" * 100)
    print(f"{'ATOR':12} {'AÇÃO':56} {'STATUS':7} {'RISCO':7} EXPECTATIVA PROVÁVEL")
    print("─" * 100)
    ordem = {"ALTO": 0, "MÉDIO": 1, "BAIXO": 2, "INFO": 3, "OK": 4}
    for ator, acao, status, risk, esp in sorted(findings, key=lambda f: (ordem.get(f[3], 9), f[0])):
        print(f"{ator:12} {acao[:56]:56} {status:7} {risk:7} {esp}")

    altos = [f for f in findings if f[3] == "ALTO"]
    medios = [f for f in findings if f[3] == "MÉDIO"]
    print("\n" + "═" * 100)
    print(f"RESUMO: {len(altos)} risco(s) ALTO · {len(medios)} MÉDIO · "
          f"{sum(1 for f in findings if f[3] == 'OK')} controle(s) OK observado(s).")
    if altos:
        print("\nRISCOS ALTOS (evidência = status observado):")
        for ator, acao, status, _, esp in altos:
            print(f"  ⚠ [{ator}] {acao} → HTTP {status}. {esp}")
    print("\nLembrete: isto é MEDIÇÃO, não veredito. Feche a matriz D-142 → vira teste negativo que trava.")
    print("═" * 100)


if __name__ == "__main__":
    main()
