#!/usr/bin/env python3
"""
Homologação E2E da tela "Clientes & Projetos" (Admin CRUD) — contra a API + Keycloak REAIS.

POR QUE EXISTE (2026-07-05): a partir de 2026-07-04 o cliente deixou de ser fixture e virou
cadastro REAL (natureza publico|privado; "excluir" = apagar em definitivo, mas só sem vínculos —
D-148). Teste unitário roda na API mockada e passa mesmo quando o dado NÃO dá a volta. "Pronto"
desta tela = ESTE harness passou: cria um cliente DESCARTÁVEL, relê pela LISTA (o que a tela usa),
edita nome+natureza, desativa/reativa, prova o GUARD de exclusão (cliente COM vínculo → 409) e
exclui de fato (204) — afirmando PERSISTÊNCIA a cada passo — e limpa tudo no fim.

Reusa o helper comum (login OIDC 2 etapas + api): infrastructure/scripts/e2e_common.py.
Credenciais saem de env (E2E_ADMIN_USER/PASS) ou do .e2e-env gitignored — zero segredo no código.

Uso:
  cd infrastructure/scripts && python3 homolog-clientes-e2e.py
  (API_BASE / KC_BASE apontam p/ outro ambiente; default = produção)

Sai != 0 em qualquer falha (report()). Serve p/ CI/pre-deploy smoke.
"""
import secrets
import time

from e2e_common import API, api, api_raw, check, cpf_valido, login_token, report


def _erro(r):
    """Corpo do erro (evidência) quando a chamada falhou; '' se foi 2xx."""
    return r.get("_body", str(r)) if isinstance(r, dict) and "_status" in r else ""


def _status(r):
    return r.get("_status", "2xx") if isinstance(r, dict) and "_status" in r else "2xx"


def main():
    print(f"E2E Clientes & Projetos · API={API}")
    tok = login_token()
    print("  login admin OK")

    suf = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))
    sigla = f"E2E-CLI-{suf}"
    novo = {
        "sigla": sigla,
        "nome": f"E2E Cliente {suf}",
        "natureza": "publico",
        "cnpj": "12345678000199",
        "prazo": "até 30/06",
    }
    cid = None       # id do cliente descartável
    vinc_uid = None  # id do usuário-vínculo (só p/ provar o guard)
    try:
        # 1) LISTAR (baseline) — a tela carrega GET /clientes; devem vir os 14 HCs importados
        print("\n1) LISTAR (baseline)")
        lst = api("GET", "/clientes", tok)
        check(isinstance(lst, list), f"GET /clientes retornou lista ({_erro(lst)[:100]})")
        lst = lst if isinstance(lst, list) else []
        hcs = [c for c in lst if c.get("externalId")]
        check(len(hcs) >= 14, f"lista traz os HCs importados (>=14) — {len(lst)} total, {len(hcs)} com externalId")
        if lst:
            check(all(k in lst[0] for k in ("id", "sigla", "nome", "natureza", "ativo")),
                  "itens têm id/sigla/nome/natureza/ativo")
        base_ids = {c.get("id") for c in lst}

        # 2) CRIAR (natureza publico) — id volta 'C-xxxx'
        print("\n2) CRIAR (natureza publico)")
        r = api("POST", "/clientes", tok, novo)
        check("_status" not in r, f"POST 2xx ({_erro(r)[:120]})")
        cid = r.get("id")
        check(isinstance(cid, str) and cid.startswith("C-"), f"id volta 'C-xxxx' (got {cid!r})")
        check(r.get("sigla") == sigla, "sigla retornada bate")
        check(r.get("nome") == novo["nome"], "nome retornado bate")
        check(r.get("natureza") == "publico", "natureza retornada bate")
        check(r.get("ativo") is True, "nasce ativo=true")
        check(r.get("tipo") == "estado", f"tipo derivado de publico = 'estado' (got {r.get('tipo')!r})")
        check(r.get("externalId") is None, "externalId null (nascido no hub, não importado)")
        check(cid not in base_ids, "id é novo (não colidiu com o baseline)")

        # 3) LER DE VOLTA pela LISTA (o que a tela realmente usa — o bug clássico é não dar a volta)
        print("\n3) LER DE VOLTA (lista)")
        lst = api("GET", "/clientes", tok)
        achado = next((c for c in (lst if isinstance(lst, list) else []) if c.get("id") == cid), None)
        check(achado, "aparece na listagem")
        if achado:
            check(achado.get("sigla") == sigla, "sigla persistiu")
            check(achado.get("nome") == novo["nome"], "nome persistiu")
            check(achado.get("natureza") == "publico", "natureza persistiu")
            check(achado.get("cnpj") == novo["cnpj"], "cnpj persistiu")
            check(achado.get("prazo") == novo["prazo"], "prazo persistiu")

        # 4) EDITAR nome + natureza (publico -> privado) e reler
        print("\n4) EDITAR (nome + natureza publico->privado)")
        upd = dict(novo)
        upd["nome"] = f"E2E Cliente EDITADO {suf}"
        upd["natureza"] = "privado"
        r = api("PUT", f"/clientes/{cid}", tok, upd)
        check("_status" not in r, f"PUT 2xx ({_erro(r)[:120]})")
        lst = api("GET", "/clientes", tok)
        achado = next((c for c in (lst if isinstance(lst, list) else []) if c.get("id") == cid), None)
        check(achado and achado.get("nome") == upd["nome"], "nome editado persistiu")
        check(achado and achado.get("natureza") == "privado", "natureza editada persistiu (publico->privado)")
        # NOTA (não bloqueia): 'tipo' é rótulo legado; o PUT não o reescreve — fica defasado
        # do 'natureza' novo. A tela usa só 'natureza', então é inconsistência interna, não do fluxo.
        if achado:
            print(f"     · nota: tipo apos editar p/ privado = {achado.get('tipo')!r} "
                  f"(legado; a tela usa 'natureza'={achado.get('natureza')!r})")

        # 5) DESATIVAR / REATIVAR — efeito afirmado pela LISTA (persistência)
        print("\n5) DESATIVAR / REATIVAR")
        r = api("POST", f"/clientes/{cid}/deactivate", tok)
        check("_status" not in r, f"deactivate 2xx ({_erro(r)[:120]})")
        lst = api("GET", "/clientes", tok)
        achado = next((c for c in (lst if isinstance(lst, list) else []) if c.get("id") == cid), None)
        check(achado and achado.get("ativo") is False, "ficou inativo (persistiu)")
        r = api("POST", f"/clientes/{cid}/activate", tok)
        check("_status" not in r, f"activate 2xx ({_erro(r)[:120]})")
        lst = api("GET", "/clientes", tok)
        achado = next((c for c in (lst if isinstance(lst, list) else []) if c.get("id") == cid), None)
        check(achado and achado.get("ativo") is True, "voltou a ativo (persistiu)")

        # 6) VALIDAÇÃO — lixo rejeitado (natureza inválida → 400) e sigla duplicada (→ 409)
        print("\n6) VALIDAÇÃO (lixo rejeitado + sigla duplicada)")
        r = api("POST", "/clientes", tok, {"sigla": f"{sigla}-X", "nome": "x", "natureza": "invalida"})
        check(_status(r) == 400, f"natureza inválida -> 400 (got {_status(r)}) [{_erro(r)[:100]}]")
        r = api("POST", "/clientes", tok, {"sigla": sigla, "nome": "duplicado", "natureza": "publico"})
        check(_status(r) == 409, f"sigla duplicada -> 409 (got {_status(r)}) [{_erro(r)[:100]}]")

        # 7) EXCLUIR + GUARD (D-148): cliente COM vínculo → 409; sem vínculo → 204
        print("\n7) EXCLUIR + GUARD (vínculo bloqueia a exclusão)")
        # cria um usuário DESCARTÁVEL vinculado a este cliente (vínculo reversível, ≠ solicitação)
        vinc = {
            "nome": f"E2E Vinc {suf}", "email": f"e2e-vinc-{suf}@doctorhub.local",
            "cpf": cpf_valido(), "telefone": "11987654321", "papeis": ["demandas"],
            "clienteId": cid, "unidade": "Núcleo E2E",
        }
        ru = api("POST", "/admin/users", tok, vinc)
        check("_status" not in ru, f"usuário-vínculo criado ({_erro(ru)[:120]})")
        vinc_uid = ru.get("id")
        check(bool(vinc_uid), "usuário-vínculo tem id")
        if vinc_uid:
            u = api("GET", f"/admin/users/{vinc_uid}", tok)
            check(u.get("clienteId") == cid, f"vínculo clienteId persistiu (got {u.get('clienteId')!r})")
        # DELETE deve ser BLOQUEADO (409) e a mensagem citar os vínculos
        d = api_raw("DELETE", f"{API}/clientes/{cid}", token=tok)
        check(_status(d) == 409, f"DELETE com vínculo -> 409 (got {_status(d)})")
        check("usuário" in _erro(d).lower(), f"mensagem do guard cita vínculo(s) [{_erro(d)[:140]}]")
        # remove o vínculo → agora o DELETE passa (204)
        api_raw("DELETE", f"{API}/admin/users/{vinc_uid}", token=tok)
        vinc_uid = None
        d = api_raw("DELETE", f"{API}/clientes/{cid}", token=tok)
        check(d == {}, f"DELETE sem vínculo -> 204 ({_erro(d)[:120]})")
        # provou que sumiu da LISTA + idempotência (2º DELETE → 404)
        lst = api("GET", "/clientes", tok)
        check(next((c for c in (lst if isinstance(lst, list) else []) if c.get("id") == cid), None) is None,
              "cliente sumiu da listagem")
        d = api_raw("DELETE", f"{API}/clientes/{cid}", token=tok)
        check(_status(d) == 404, f"segundo DELETE -> 404 (got {_status(d)})")
        cid = None

    finally:
        # 8) LIMPEZA idempotente — nunca deixar resíduo em produção
        print("\n8) LIMPEZA")
        if vinc_uid:
            api_raw("DELETE", f"{API}/admin/users/{vinc_uid}", token=tok)
            print("  · usuário-vínculo removido")
        if cid:
            api_raw("DELETE", f"{API}/clientes/{cid}", token=tok)
            print("  · cliente descartável removido")
        if not vinc_uid and not cid:
            print("  · nada a limpar (fluxo já removeu tudo)")

    report("HOMOLOGAÇÃO E2E DE CLIENTES & PROJETOS")


if __name__ == "__main__":
    main()
