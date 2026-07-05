#!/usr/bin/env python3
"""
Homologação de SEGURANÇA da API do Doctor-Hub em PRODUÇÃO — teste NEGATIVO que TRAVA (D-142/D-154).

ANTES (era medição): media o que a API permitia e reportava "RISCO A CONFIRMAR" — sempre saía 0.
AGORA (matriz D-142 confirmada 2026-07-05): AFIRMA o comportamento CORRETO com check()/report() —
se um limite for violado, a verificação FALHA e o script sai 1 (vira gate de CI, igual aos demais
homolog-*-e2e.py). Prova, contra a infra REAL (Keycloak + API em prod), que:

  · RBAC por papel  — base médica (escala/ficha) só Admin/Demandas; solicitações (criar+status) só
    Admin/Regulação; assumir vaga só Supervisor(gestor)/Admin; admin-only nos endpoints de admin.
  · ESCOPO por cliente (G-1) — Regulação do cliente A NÃO lê nem altera nem cria dado do cliente B (403/
    lista sem B). Fail-closed: Regulação sem clienteId no token → lista vazia.
  · ESCOPO por unidade (G-3) — Supervisor só vê agendamentos da sua unidade; sem unidade → vazio.
  · Não autenticado → 401.

O QUE FAZ:
  1. PROVISIONA (Keycloak master admin) usuários EFÊMEROS `sec-*` com papel/escopo conhecidos.
  2. LOGA cada um (OIDC 2-etapas de e2e_common) e AFIRMA o comportamento da matriz por endpoint.
     Sondas destrutivas usam id FALSO/corpo INVÁLIDO de propósito → 403 = bloqueado pelo RBAC ANTES de
     tocar dado (é o que afirmamos); nunca mutam dado real.
  3. LIMPA: cancela as solicitações de teste (não há DELETE — vira CANCELADO) e EXCLUI todos os `sec-*`.
     Idempotente. O realm volta a ter só o dono.

Uso:  cd infrastructure/scripts && python3 homolog-seguranca-e2e.py   (exit 0 = passou; 1 = violação)
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
from e2e_common import API, api_raw, cpf_valido, check, report

KC = os.environ.get("KC_BASE", "https://id.portaltecnologia.app.br")
REALM = os.environ.get("KC_REALM", "portal")
ADMIN_SECRET = os.environ.get("KC_ADMIN_SECRET", "portal-identity-admin-password")
DONO_USERNAME = "35922911813"  # Alessandro — o ÚNICO usuário humano que deve sobrar no realm.

SUF = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))
UNI_A = "Unidade Alpha"  # unidade do sec-gestor (escopo de Supervisor)


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
    print(f"HOMOLOGAÇÃO DE SEGURANÇA (RBAC + escopo · matriz D-142) · API={API} · realm={REALM}\n")

    ATOK = kc_admin_token()
    cuid = client_uuid()
    print("  ✓ Keycloak master admin OK · client doctor-hub-api =", cuid[:8], "…\n")

    tokens = {}
    sidA = sidB = None
    try:
        # ── 1) PROVISIONA sec-demandas e loga p/ descobrir 2 clientes reais (A, B) ──
        print("1) PROVISIONAMENTO + DESCOBERTA DE ESCOPO")
        provision("sec-demandas", "SecDemandas", ["demandas"], cuid)
        tokens["sec-demandas"] = login_as("sec-demandas", _sec_pw["sec-demandas"])
        if not check(tokens["sec-demandas"], "login sec-demandas"):
            report("HOMOLOGAÇÃO DE SEGURANÇA")  # aborta cedo (limpeza roda no finally)
        st, clientes = call(tokens["sec-demandas"], "GET", "/clientes")
        clientes = clientes if isinstance(clientes, list) else []
        ativos = [c for c in clientes if c.get("ativo")] or clientes
        if not check(len(ativos) >= 2, "há ao menos 2 clientes p/ testar escopo horizontal"):
            report("HOMOLOGAÇÃO DE SEGURANÇA")
        A, B = ativos[0], ativos[1]
        print(f"  cliente A = {A['sigla']} ({A['id']}) · cliente B = {B['sigla']} ({B['id']})")

        provision("sec-rega", "SecRegA", ["regulacao"], cuid, cliente_id=A["id"], unidade=UNI_A)
        provision("sec-regb", "SecRegB", ["regulacao"], cuid, cliente_id=B["id"], unidade="Unidade Beta")
        provision("sec-regc", "SecRegC", ["regulacao"], cuid)              # SEM vínculo (fail-closed)
        provision("sec-gestor", "SecGestor", ["gestor"], cuid, cliente_id=A["id"], unidade=UNI_A)
        provision("sec-gestc", "SecGestC", ["gestor"], cuid)              # gestor SEM unidade (fail-closed)
        for u in ("sec-rega", "sec-regb", "sec-regc", "sec-gestor", "sec-gestc"):
            tokens[u] = login_as(u, _sec_pw[u])
            check(tokens[u], f"login {u}")

        # doutor real p/ a sonda de escalas (id só é usado; corpo/id inválido não cria nada)
        _, docs = call(tokens["sec-demandas"], "GET", "/doctors")
        doc_id = docs[0]["id"] if isinstance(docs, list) and docs else FAKE_GUID

        # ── 2) VERTICAL — elevação de privilégio (papel comum → endpoints de ADMIN) → 403 ──
        print("\n2) VERTICAL — só Admin alcança os endpoints de admin (esperado 403)")
        td = tokens["sec-demandas"]
        st, _ = call(td, "GET", "/admin/users?page=1&pageSize=5")
        check(st == 403, "sec-demandas NÃO lista usuários (GET /admin/users → 403)")
        st, _ = call(td, "POST", "/admin/users", {})
        check(st == 403, "sec-demandas NÃO cria usuário (POST /admin/users → 403)")
        st, _ = call(td, "POST", "/clientes", {"sigla": "x", "nome": "x", "natureza": "publico"})
        check(st == 403, "sec-demandas NÃO cria cliente (POST /clientes → 403)")
        st, _ = call(td, "PUT", f"/clientes/{FAKE_C}", {"sigla": "x", "nome": "x", "natureza": "publico"})
        check(st == 403, "sec-demandas NÃO edita cliente (PUT /clientes/{id} → 403)")
        st, _ = call(td, "DELETE", f"/clientes/{FAKE_C}")
        check(st == 403, "sec-demandas NÃO exclui cliente (DELETE /clientes/{id} → 403)")
        st, _ = call(tokens["sec-gestor"], "GET", "/admin/users?page=1&pageSize=5")
        check(st == 403, "sec-gestor NÃO lista usuários (GET /admin/users → 403)")

        # ── 3) RBAC por papel — base médica / solicitações / assumir vaga → 403 ──
        print("\n3) RBAC por papel (matriz D-142)")
        # Base médica (escala + ficha) = só Admin/Demandas → Regulação/Supervisor 403
        st, _ = call(tokens["sec-rega"], "POST", f"/doctors/{doc_id}/escalas", {"especialidade": "X"})
        check(st == 403, "sec-rega NÃO cria escala (base médica → 403)")
        st, _ = call(tokens["sec-gestor"], "POST", f"/doctors/{doc_id}/escalas", {"especialidade": "X"})
        check(st == 403, "sec-gestor NÃO cria escala (base médica → 403)")
        st, _ = call(tokens["sec-rega"], "DELETE", f"/escalas/{FAKE_GUID}")
        check(st == 403, "sec-rega NÃO exclui escala (base médica → 403)")
        st, _ = call(tokens["sec-gestor"], "PUT", f"/doctors/{FAKE_GUID}", {"cpf": "12345678909"})
        check(st == 403, "sec-gestor NÃO edita ficha/CPF do médico (base médica → 403)")
        # Solicitações (criar + status) = só Admin/Regulação → Demandas/Supervisor 403
        st, _ = call(td, "POST", "/solicitacoes", {"clienteSigla": A["sigla"], "especialidade": "X", "qtd": 1})
        check(st == 403, "sec-demandas NÃO cria solicitação (criar = Admin/Regulação → 403)")
        st, _ = call(tokens["sec-gestor"], "POST", "/solicitacoes", {"clienteSigla": A["sigla"], "especialidade": "X", "qtd": 1})
        check(st == 403, "sec-gestor NÃO cria solicitação (→ 403)")
        # Assumir vaga (POST agendamento) = só Supervisor/Admin → Regulação/Demandas 403
        ag = {"vagaId": "sec-x", "pacienteIniciais": "M. S.", "especialidade": "X", "unidade": UNI_A}
        st, _ = call(tokens["sec-rega"], "POST", "/agendamentos", ag)
        check(st == 403, "sec-rega NÃO assume vaga (POST /agendamentos = Supervisor/Admin → 403)")
        st, _ = call(td, "POST", "/agendamentos", ag)
        check(st == 403, "sec-demandas NÃO assume vaga (→ 403)")

        # ── 4) HORIZONTAL — escopo de cliente (G-1): regA ⟂ dado de regB ──
        print("\n4) HORIZONTAL — Regulação A não toca no cliente B (G-1)")
        sA = {"clienteSigla": A["sigla"], "especialidade": "Cardiologia", "qtd": 1,
              "apelido": f"SEC-E2E-A-{SUF}", "aPartirDe": "05/07", "ate": "31/07", "retorno": 0}
        sB = {"clienteSigla": B["sigla"], "especialidade": "Cardiologia", "qtd": 1,
              "apelido": f"SEC-E2E-B-{SUF}", "aPartirDe": "05/07", "ate": "31/07", "retorno": 0}
        st, rA = call(tokens["sec-rega"], "POST", "/solicitacoes", sA)
        sidA = rA.get("id") if isinstance(rA, dict) else None
        check(st == 201 and sidA, f"sec-rega CRIA no seu cliente A={A['sigla']} (setup)")
        st, rB = call(tokens["sec-regb"], "POST", "/solicitacoes", sB)
        sidB = rB.get("id") if isinstance(rB, dict) else None
        check(st == 201 and sidB, f"sec-regb CRIA no seu cliente B={B['sigla']} (setup)")

        # regA tenta CRIAR para o cliente B → 403 (não deixa criar p/ outro cliente)
        st, _ = call(tokens["sec-rega"], "POST", "/solicitacoes", sB)
        check(st == 403, "sec-rega NÃO cria solicitação para o cliente B (POST cross-cliente → 403)")

        # regA LÊ /solicitacoes → NÃO enxerga o dado do cliente B, e só vê o seu cliente
        st, lst = call(tokens["sec-rega"], "GET", "/solicitacoes")
        lst = lst if isinstance(lst, list) else []
        siglas_vis = sorted({s.get("clienteSigla") for s in lst if s.get("clienteSigla")})
        check(not any(s.get("id") == sidB for s in lst),
              "sec-rega NÃO vê a solicitação do cliente B na lista (leitura horizontal bloqueada)")
        check(siglas_vis in ([A["sigla"]], []),
              f"sec-rega só vê o seu cliente na lista (viu {siglas_vis}, esperado ⊆ [{A['sigla']}])")

        # regA ALTERA a solicitação do cliente B (PATCH) → 403; e B fica intacto
        marca = f"SEC-E2E-XW-{SUF}"
        st, _ = call(tokens["sec-rega"], "PATCH", f"/solicitacoes/{sidB}", {"subEstado": marca})
        check(st == 403, "sec-rega NÃO altera a solicitação do cliente B (PATCH cross-cliente → 403)")
        _, lb = call(tokens["sec-regb"], "GET", "/solicitacoes")
        b_intacto = not any(s.get("id") == sidB and s.get("subEstado") == marca
                            for s in (lb if isinstance(lb, list) else []))
        check(b_intacto, "a solicitação do cliente B permaneceu intacta (nenhuma escrita vazou)")

        # fail-closed: Regulação SEM clienteId no token → lista vazia (não a global)
        st, lc = call(tokens["sec-regc"], "GET", "/solicitacoes")
        check(st == 200 and isinstance(lc, list) and len(lc) == 0,
              "sec-regc (Regulação SEM vínculo) recebe lista VAZIA (fail-closed)")

        # ── 5) ESCOPO por unidade — agendamentos (G-3, LGPD: iniciais) ──
        print("\n5) ESCOPO por unidade — Supervisor só vê a sua unidade (G-3)")
        _, dem_all = call(td, "GET", "/agendamentos")  # Demandas vê tudo (referência)
        dem_all = dem_all if isinstance(dem_all, list) else []
        _, ges = call(tokens["sec-gestor"], "GET", "/agendamentos")
        ges = ges if isinstance(ges, list) else []
        alpha_ids = {a.get("id") for a in dem_all if a.get("unidade") == UNI_A}
        check(all(a.get("unidade") == UNI_A for a in ges),
              f"sec-gestor só vê agendamentos da sua unidade ({UNI_A})")
        check({a.get("id") for a in ges} == alpha_ids,
              "sec-gestor vê EXATAMENTE os agendamentos da sua unidade (nem mais, nem menos)")
        st, lg = call(tokens["sec-gestc"], "GET", "/agendamentos")
        check(st == 200 and isinstance(lg, list) and len(lg) == 0,
              "sec-gestc (Supervisor SEM unidade) recebe lista VAZIA (fail-closed)")

        # ── 6) NÃO AUTENTICADO — sem token deve dar 401 ──
        print("\n6) NÃO AUTENTICADO (sem token → 401)")
        for p in ["/clientes", "/solicitacoes", "/agendamentos", "/doctors", "/admin/users"]:
            st, _ = call(None, "GET", p)
            check(st == 401, f"GET {p} sem token → 401")
        st, _ = call(None, "POST", "/solicitacoes", sA)
        check(st == 401, "POST /solicitacoes sem token → 401")

    finally:
        # ── 7) LIMPEZA — cancela dados de teste + exclui todos os sec-* ──
        print("\n7) LIMPEZA")
        for sid, tk in ((sidA, tokens.get("sec-rega")), (sidB, tokens.get("sec-regb"))):
            if sid and tk:
                call(tk, "PATCH", f"/solicitacoes/{sid}", {"status": "CANCELADO"})
                print(f"  · solicitação de teste {sid} → CANCELADO (não há DELETE no contrato)")
        roster = purge_sec_users()
        secs = [u for u in roster if str(u).startswith("sec-")]
        if secs:
            print(f"  ⚠ AINDA HÁ sec-* no realm: {secs} — reexecute a limpeza!")
        elif DONO_USERNAME in roster:
            print(f"  ✓ realm limpo de sec-* (dono {DONO_USERNAME} presente)")
        else:
            print(f"  · realm sem sec-*; roster: {roster}")

    report("HOMOLOGAÇÃO DE SEGURANÇA (RBAC + escopo D-142)")


if __name__ == "__main__":
    main()
