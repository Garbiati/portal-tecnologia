#!/usr/bin/env python3
"""
Homologação E2E da ESCALA FIXA (tela medico-detalhe → PerfilEscalas) — o CORE da apresentação.
Roda contra a API + Keycloak REAIS de produção (mesmo caminho do front: OIDC Authorization Code + PKCE).

POR QUE EXISTE: a escala FIXA é a UNIDADE DE OFERTA do hub (capacidade que o médico gera). Testes
unitários usam a API mockada e passam mesmo quando o dado NÃO dá a volta. "Pronto" desta tela = ESTE
harness passar: cria uma FIXA COMPLETA (dias, blocos gerais + blocos por-dia, semanas excluídas,
tipo de serviço, projeto/cliente, vigência futura), RELÊ pela LISTA GLOBAL (GET /escalas — o que o
painel usa) afirmando que CADA campo persistiu, prova os invariantes (INV-2 conflito de FIXA, INV-4
bloco inválido → 400), edita a duração e confirma o efeito, exclui (204) e LIMPA tudo que criou.

Contrato exercido (services/doctor-hub-api/.../EscalaEndpoints.cs + doctor-hub-web/src/lib/api.ts):
  GET  /doctors                     → 1 médico ativo real + especialidade (INV-5)
  GET  /tipos-servico               → catálogo (D-150)
  POST /doctors/{id}/escalas        → cria FIXA (EscalaReq)  → 201 EscalaDto
  GET  /escalas                     → estoque global (EscalaComMedicoDto) — read-back de persistência
  PUT  /escalas/{id}                → edita (duracaoMin)     → 200 EscalaDto
  DELETE /escalas/{id}              → 204

Uso:
  cd infrastructure/scripts && python3 homolog-escalas-e2e.py
  (credenciais no .e2e-env gitignored; API_BASE/KC_BASE p/ apontar noutro ambiente; default = prod)

Sai != 0 em qualquer falha (report()). Zero segredo no código.
"""
import json
import sys
from datetime import date, timedelta

from e2e_common import api, api_raw, check, cpf_valido, login_token, report  # noqa: F401

# Cliente/projeto REAL usado no vínculo da escala (D-150). Default = Piauí Saúde Digital (HC importado).
CLIENTE_ID = "C-a1c8e688"
TIPO_SERVICO = "teleatendimento"


def payload_fixa(esp, inicio, *, dias, blocos, duracao_min,
                 blocos_por_dia=None, semanas_excluidas=None,
                 tipo_servico=TIPO_SERVICO, cliente_id=CLIENTE_ID, fim=None):
    """Mesma forma do payloadEscala (front): manda o objeto COMPLETO (o backend faz overwrite)."""
    p = {
        "especialidade": esp,
        "tipo": "FIXA",
        "dias": dias,
        "blocos": blocos,
        "duracaoMin": duracao_min,
        "vigencia": {"inicio": inicio, "fim": fim},
        "status": "ativa",
        "tipoServico": tipo_servico,
        "clienteId": cliente_id,
        "plantaoReposicao": False,
    }
    if blocos_por_dia is not None:
        p["blocosPorDia"] = blocos_por_dia
    if semanas_excluidas:
        p["semanasExcluidas"] = semanas_excluidas
    return p


def escolher_medico(token):
    """1º médico ATIVO com especialidade e SEM escala (não perturba dados existentes)."""
    docs = api("GET", "/doctors", token)
    if not isinstance(docs, list):
        return None
    for d in docs:
        esps = d.get("especialidades") or []
        if d.get("status") == "ativo" and esps and not d.get("temEscala"):
            return d
    return None


def buscar_na_lista_global(token, escala_id):
    """Read-back de VERDADE: acha a escala pela LISTA GLOBAL (GET /escalas, o que o painel consome)."""
    todas = api("GET", "/escalas", token)
    if not isinstance(todas, list):
        return None
    return next((e for e in todas if e.get("id") == escala_id), None)


def main():
    from e2e_common import API
    print(f"E2E Escala FIXA · API={API}")
    token = login_token()
    print("  login admin OK")

    criadas = []  # ids de escalas criadas (limpeza garantida no finally)
    try:
        # ── 1) MÉDICO REAL + especialidade (INV-5 exige especialidade habilitada) ──
        print("\n1) MÉDICO REAL (GET /doctors)")
        med = escolher_medico(token)
        check(med is not None, "achou 1 médico ativo com especialidade e sem escala")
        if med is None:
            report("HOMOLOGAÇÃO E2E DE ESCALA FIXA")
            return
        doctor_id = med["id"]
        esp = (med.get("especialidades") or [{}])[0].get("nome") or med.get("especialidade")
        print(f"   médico: {med.get('nome')} · esp={esp} · id={doctor_id}")
        check(bool(esp), "médico tem especialidade (base do INV-5)")

        # catálogo de tipos de serviço deve conter o que vamos usar (D-150)
        tipos = api("GET", "/tipos-servico", token)
        ids_tipo = {t.get("id") for t in tipos} if isinstance(tipos, list) else set()
        check(TIPO_SERVICO in ids_tipo, f"tipo de serviço '{TIPO_SERVICO}' existe no catálogo")

        # ── 2) CRIAR FIXA COMPLETA ──────────────────────────────────────────────
        print("\n2) CRIAR FIXA COMPLETA (POST /doctors/{id}/escalas)")
        inicio = (date.today() + timedelta(days=30)).isoformat()  # INV-3: FIXA começa no futuro
        nova = payload_fixa(
            esp, inicio,
            dias=["Seg", "Ter"],
            blocos=[{"inicio": "08:00", "fim": "14:00"}],           # blocos GERAIS
            blocos_por_dia={"Ter": [{"inicio": "10:00", "fim": "18:00"}]},  # Ter sobrescreve
            semanas_excluidas=[2],                                   # D-152
            duracao_min=30,
        )
        r = api("POST", f"/doctors/{doctor_id}/escalas", token, nova)
        ok = check("_status" not in r, f"POST 2xx ({r.get('_body', '')[:160] if '_status' in r else 'ok'})")
        escala_id = r.get("id")
        check(bool(escala_id), "escala criada tem id")
        if escala_id:
            criadas.append(escala_id)
        # a resposta da criação já deve refletir os campos (EscalaDto)
        if ok:
            check(r.get("tipoServico") == TIPO_SERVICO, "resposta: tipoServico bate")
            check(r.get("clienteId") == CLIENTE_ID, "resposta: clienteId bate")

        # ── 3) READ-BACK pela LISTA GLOBAL (o dado dá a volta?) ─────────────────
        print("\n3) LER DE VOLTA (GET /escalas — estoque global do painel)")
        g = buscar_na_lista_global(token, escala_id) if escala_id else None
        check(g is not None, "escala aparece na lista global (só médicos ATIVOS)")
        if g:
            check(g.get("doctorId") == doctor_id, "vinculada ao médico certo (doctorId)")
            check(g.get("tipo") == "FIXA", "tipo FIXA persistiu")
            dias_csv = g.get("diasCsv") or ""
            check("Seg" in dias_csv and "Ter" in dias_csv, f"dias Seg,Ter persistiram (diasCsv='{dias_csv}')")
            # blocos gerais
            try:
                blocos = json.loads(g.get("blocosJson") or "[]")
            except (ValueError, TypeError):
                blocos = None
            check(blocos == [{"inicio": "08:00", "fim": "14:00"}], f"blocos gerais 08:00-14:00 persistiram ({g.get('blocosJson')})")
            # blocos POR DIA — Ter 10:00-18:00 (o teste que costuma pegar dado perdido)
            bpd_raw = g.get("blocosPorDiaJson")
            check(bool(bpd_raw), f"blocosPorDiaJson NÃO é nulo (={bpd_raw})")
            try:
                bpd = json.loads(bpd_raw) if bpd_raw else {}
            except (ValueError, TypeError):
                bpd = {}
            check(bpd.get("Ter") == [{"inicio": "10:00", "fim": "18:00"}],
                  f"blocosPorDia Ter=10:00-18:00 persistiu ({bpd_raw})")
            check(g.get("semanasExcluidasCsv") == "2", f"semanasExcluidasCsv='2' persistiu (={g.get('semanasExcluidasCsv')})")
            check(g.get("tipoServico") == TIPO_SERVICO, f"tipoServico persistiu (={g.get('tipoServico')})")
            check(g.get("clienteId") == CLIENTE_ID, f"clienteId persistiu (={g.get('clienteId')})")
            check(g.get("duracaoMin") == 30, f"duracaoMin=30 persistiu (={g.get('duracaoMin')})")

        # ── 4) INVARIANTE: 2ª FIXA que conflita deve ser REJEITADA (INV) ────────
        print("\n4) INVARIANTE (POST 2ª FIXA sobreposta → 400 INV)")
        conflito = payload_fixa(
            esp, inicio,                     # mesma especialidade + vigência sobreposta (FIXA sem fim = infinita)
            dias=["Seg"], blocos=[{"inicio": "08:00", "fim": "14:00"}], duracao_min=30,
        )
        rc = api("POST", f"/doctors/{doctor_id}/escalas", token, conflito)
        if "_status" not in rc and rc.get("id"):
            # não deveria criar — se criou, é BUG do INV; registra p/ limpeza mesmo assim
            criadas.append(rc["id"])
        check(rc.get("_status") == 400, f"2ª FIXA sobreposta → 400 (got {rc.get('_status', '2xx-CRIOU')})")
        check("INV" in (rc.get("_body") or ""), f"corpo traz mensagem de invariante ({(rc.get('_body') or '')[:160]})")

        # ── 4b) VALIDAÇÃO: lixo rejeitado (bloco com fim < início → INV-4) ──────
        print("\n4b) VALIDAÇÃO (bloco inválido fim<início → 400)")
        lixo = payload_fixa(
            esp, inicio, dias=["Qua"], blocos=[{"inicio": "14:00", "fim": "08:00"}], duracao_min=30,
        )
        rl = api("POST", f"/doctors/{doctor_id}/escalas", token, lixo)
        if "_status" not in rl and rl.get("id"):
            criadas.append(rl["id"])
        check(rl.get("_status") == 400, f"bloco fim<início → 400 (got {rl.get('_status', '2xx-CRIOU')})")

        # ── 5) EDITAR duracaoMin (PUT) + confirmar o EFEITO ─────────────────────
        print("\n5) EDITAR (PUT /escalas/{id} — duracaoMin 30→20)")
        if escala_id:
            editado = payload_fixa(
                esp, inicio,
                dias=["Seg", "Ter"],
                blocos=[{"inicio": "08:00", "fim": "14:00"}],
                blocos_por_dia={"Ter": [{"inicio": "10:00", "fim": "18:00"}]},
                semanas_excluidas=[2],
                duracao_min=20,  # <- a mudança
            )
            ru = api("PUT", f"/escalas/{escala_id}", token, editado)
            check("_status" not in ru, f"PUT 2xx ({ru.get('_body', '')[:160] if '_status' in ru else 'ok'})")
            # reabrir e conferir que a duração nova deu a volta (e o resto ficou intacto)
            g2 = buscar_na_lista_global(token, escala_id)
            check(g2 is not None and g2.get("duracaoMin") == 20, f"duracaoMin=20 persistiu (={g2.get('duracaoMin') if g2 else 'sumiu'})")
            check(g2 is not None and g2.get("semanasExcluidasCsv") == "2", "semanasExcluidas seguiu intacta após edição")
            check(g2 is not None and g2.get("clienteId") == CLIENTE_ID, "clienteId seguiu intacto após edição")

        # ── 6) EXCLUIR (204) + confirmar sumiço ─────────────────────────────────
        print("\n6) EXCLUIR (DELETE /escalas/{id} → 204)")
        if escala_id:
            rd = api_raw("DELETE", f"{API}/escalas/{escala_id}", token=token)
            check("_status" not in rd, f"DELETE 2xx/204 ({rd.get('_body', '') if '_status' in rd else 'ok'})")
            if "_status" not in rd and escala_id in criadas:
                criadas.remove(escala_id)
            g3 = buscar_na_lista_global(token, escala_id)
            check(g3 is None, "escala sumiu da lista global após exclusão")

    finally:
        # ── LIMPEZA — remove QUALQUER escala de teste que ainda exista ──────────
        if criadas:
            print("\n7) LIMPEZA (excluir escalas de teste remanescentes)")
            for eid in list(criadas):
                api_raw("DELETE", f"{API}/escalas/{eid}", token=token)
                sobrou = buscar_na_lista_global(token, eid)
                check(sobrou is None, f"limpeza confirmada da escala {eid}")

    report("HOMOLOGAÇÃO E2E DE ESCALA FIXA")


if __name__ == "__main__":
    main()
