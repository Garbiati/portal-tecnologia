#!/usr/bin/env python3
"""
Homologação E2E do fluxo "Solicitações" (telas minhas-solicitacoes + de-acordo) —
contra a API + Keycloak REAIS de produção.

POR QUE EXISTE: testes unitários das telas usam a API mockada (fixture Promise.resolve) e passam
mesmo que o dado NÃO dê a volta de verdade. "Pronto" deste fluxo = ESTE harness passar. Ele exercita
o caminho REAL das duas telas:

  minhas-solicitacoes (Regulação):  criarSolicitacao  →  POST /api/solicitacoes
  de-acordo           (Regulação):  marcarAceita(id)  →  PATCH /api/solicitacoes/{id} {aceita:true}
  ambas hidratam de:                                     GET  /api/solicitacoes

Fluxo afirmado (PERSISTÊNCIA a cada passo — o bug clássico é o dado não voltar pela LISTA):
  1) POST cria solicitação (clienteSigla de um HC real, especialidade, qtd, janela aPartirDe/ate)
  2) GET  /solicitacoes  → confere que persistiu (todos os campos deram a volta), status=ABERTO
  3) PATCH status=RESERVADO (a Demandas "disponibiliza" — é o que faz o item aparecer no de-acordo)
  4) GET  → confere RESERVADO persistiu
  5) PATCH aceita=true (o "DE ACORDO" do cliente, D-116)
  6) GET  → confere aceita=true persistiu PELA LISTA (crivo de ouro do fluxo de-acordo)
  7) VALIDAÇÃO: campos obrigatórios ausentes / qtd<=0 / status inválido → 400
  8) LIMPEZA: não há DELETE de solicitação (só PATCH) → neutraliza com status=CANCELADO e deixa nota

Uso:  cd infrastructure/scripts && python3 homolog-solicitacoes-e2e.py
      (API_BASE / KC_BASE p/ apontar a outro ambiente; default = produção). Zero segredo no código:
      credenciais saem de E2E_ADMIN_USER/E2E_ADMIN_PASS ou do .e2e-env (gitignored).

Sai != 0 em qualquer falha (report()). Ao achar falha: distinguir BUG REAL (evidência no _body) de
erro do teste (corrige e roda de novo).
"""
import secrets
import time

from e2e_common import api, check, login_token, report, API


def main():
    print(f"E2E Solicitações · API={API}")
    token = login_token()
    print("  login OK (Regulação/admin e2e-homolog)")

    # ── Pré-requisito: um cliente/HC REAL (a solicitação é POR cliente — D-114) ──
    # GET /api/clientes é a mesma fonte que a tela usa (listarClientesApi). Pega um ATIVO.
    print("\n0) CLIENTE REAL (GET /clientes)")
    clientes = api("GET", "/clientes", token)
    check(isinstance(clientes, list) and len(clientes) > 0, "GET /clientes retorna lista não-vazia")
    if not (isinstance(clientes, list) and clientes):
        report("HOMOLOGAÇÃO E2E DE SOLICITAÇÕES")  # aborta com falha
        return
    ativo = next((c for c in clientes if c.get("ativo")), clientes[0])
    sigla = ativo.get("sigla")
    check(bool(sigla), f"cliente escolhido tem sigla ({sigla} · {ativo.get('nome')})")

    sufixo = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))
    apelido = f"E2E-homolog-{sufixo}"  # tag p/ identificar/limpar o dado de teste
    esp = "Cardiologia"
    novo = {
        "clienteSigla": sigla,
        "especialidade": esp,
        "qtd": 3,
        "apelido": apelido,
        "aPartirDe": "05/07",
        "ate": "31/07",
        "retorno": 0,
    }
    sid = None
    try:
        # 1. CRIAR (POST) ────────────────────────────────────────────────────────
        print("\n1) CRIAR (POST /solicitacoes)")
        r = api("POST", "/solicitacoes", token, novo)
        criado_ok = "_status" not in r
        check(criado_ok, f"POST 2xx (retorno: {r.get('_body', r) if not criado_ok else 'ok'})")
        if not criado_ok:
            report("HOMOLOGAÇÃO E2E DE SOLICITAÇÕES")
            return
        sid = r.get("id")
        check(bool(sid), f"solicitação criada tem id ({sid})")
        check(r.get("status") == "ABERTO", f"nasce ABERTO (got {r.get('status')})")
        check(r.get("clienteSigla") == sigla, "clienteSigla no retorno bate")
        check(r.get("especialidade") == esp, "especialidade no retorno bate")
        check(r.get("qtd") == 3, "qtd no retorno bate")
        check(r.get("aceita") is False, "nasce SEM de acordo (aceita=false)")

        # 2. LER DE VOLTA pela LISTA (o que as telas hidratam) ────────────────────
        print("\n2) LER DE VOLTA (GET /solicitacoes)")
        lst = api("GET", "/solicitacoes", token)
        check(isinstance(lst, list), "GET /solicitacoes retorna lista")
        achado = next((s for s in lst if s.get("id") == sid), None) if isinstance(lst, list) else None
        check(achado is not None, "solicitação aparece na LISTA")
        if achado:
            check(achado.get("clienteSigla") == sigla, "clienteSigla persistiu")
            check(achado.get("especialidade") == esp, "especialidade persistiu")
            check(achado.get("qtd") == 3, "qtd persistiu")
            check(achado.get("apelido") == apelido, "apelido persistiu")
            check(achado.get("aPartirDe") == "05/07", "janela aPartirDe persistiu")
            check(achado.get("ate") == "31/07", "janela ate persistiu")
            check(achado.get("status") == "ABERTO", "status ABERTO persistiu")
            check(achado.get("aceita") is False, "aceita=false persistiu")

        # 3. DISPONIBILIZAR (PATCH status=RESERVADO) — o passo da Demandas que faz o
        #    item aparecer na tela de-acordo (que só lista RESERVADO/ENTREGUE) ──────
        print("\n3) DISPONIBILIZAR (PATCH status=RESERVADO)")
        r = api("PATCH", f"/solicitacoes/{sid}", token, {"status": "RESERVADO"})
        patch_ok = "_status" not in r
        check(patch_ok, f"PATCH 2xx ({r.get('_body', 'ok') if not patch_ok else 'ok'})")
        check(patch_ok and r.get("status") == "RESERVADO", "retorno já reflete RESERVADO")
        lst = api("GET", "/solicitacoes", token)
        achado = next((s for s in lst if s.get("id") == sid), None) if isinstance(lst, list) else None
        check(achado and achado.get("status") == "RESERVADO", "status RESERVADO persistiu (via lista)")

        # 4. DE ACORDO (PATCH aceita=true) — o núcleo da tela de-acordo (D-116) ─────
        print("\n4) DE ACORDO (PATCH aceita=true)")
        r = api("PATCH", f"/solicitacoes/{sid}", token, {"aceita": True})
        aceite_ok = "_status" not in r
        check(aceite_ok, f"PATCH aceite 2xx ({r.get('_body', 'ok') if not aceite_ok else 'ok'})")
        check(aceite_ok and r.get("aceita") is True, "retorno já reflete aceita=true")

        # 5. CRIVO DE OURO: aceita=true dá a volta PELA LISTA (a tela re-hidrata daqui)
        print("\n5) LER DE VOLTA O DE ACORDO (GET /solicitacoes)")
        lst = api("GET", "/solicitacoes", token)
        achado = next((s for s in lst if s.get("id") == sid), None) if isinstance(lst, list) else None
        check(achado is not None, "solicitação ainda na lista")
        check(achado and achado.get("aceita") is True, "aceita=true PERSISTIU (crivo D-116)")
        # status não deve regredir com o PATCH de aceite (só mexeu no flag)
        check(achado and achado.get("status") == "RESERVADO", "status seguiu RESERVADO após aceite")

        # 6. VALIDAÇÃO — o backend rejeita lixo? (3 casos) ─────────────────────────
        print("\n6) VALIDAÇÃO (400 esperado)")
        r = api("POST", "/solicitacoes", token, {"clienteSigla": sigla, "especialidade": "", "qtd": 1})
        check(r.get("_status") == 400, f"especialidade vazia → 400 (got {r.get('_status', '2xx')})")
        r = api("POST", "/solicitacoes", token, {"clienteSigla": sigla, "especialidade": esp, "qtd": 0})
        check(r.get("_status") == 400, f"qtd=0 → 400 (got {r.get('_status', '2xx')})")
        r = api("PATCH", f"/solicitacoes/{sid}", token, {"status": "LIXO"})
        check(r.get("_status") == 400, f"status inválido → 400 (got {r.get('_status', '2xx')})")

    finally:
        # 7. LIMPEZA — NÃO há DELETE de solicitação (só GET/POST/PATCH no contrato).
        #    Neutraliza o dado de teste marcando CANCELADO (D-104: "não importa mais").
        if sid:
            print("\n7) LIMPEZA (PATCH status=CANCELADO — não existe DELETE)")
            api("PATCH", f"/solicitacoes/{sid}", token, {"status": "CANCELADO"})
            lst = api("GET", "/solicitacoes", token)
            achado = next((s for s in lst if s.get("id") == sid), None) if isinstance(lst, list) else None
            check(achado and achado.get("status") == "CANCELADO", "dado de teste neutralizado (CANCELADO)")
            print(f"   NOTA: sem DELETE no contrato → a solicitação {sid} (apelido {apelido}) "
                  f"permanece no banco como CANCELADO.")

    report("HOMOLOGAÇÃO E2E DE SOLICITAÇÕES")


if __name__ == "__main__":
    main()
