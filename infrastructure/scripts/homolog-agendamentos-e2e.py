#!/usr/bin/env python3
"""
Homologação E2E do fluxo ASSUNÇÃO / AGENDAMENTOS (etapas ④/⑤ do pipeline) — contra a
API + Keycloak REAIS de produção. Reusa o login OIDC de e2e_common (nunca reimplementar).

PROPÓSITO DA TELA (doctor-hub-web/src/pages/assuncao/index.tsx): o Gestor assume uma vaga
emitida para SUA unidade, escolhe o paciente (SÓ INICIAIS — LGPD) e o doutor preferencial e
confirma → cria um AGENDAMENTO persistido (confirmar() → criarAgendamentoApi → POST
/api/agendamentos). O envio real à Teleconsulta é STUB: EnviadoTc é sempre false (DEP-TC-1,
decisão 2026-07-04 — persiste aqui, fica pronto p/ ligar, NÃO entra na TC ainda).

O QUE ESTE HARNESS AFIRMA (o bug clássico é o dado NÃO dar a volta pelo banco):
  1) POST /api/agendamentos cria e devolve 201 com o corpo persistido.
  2) GET /api/agendamentos (o que a tela usa em listarAgendamentosApi) RELISTA o agendamento —
     cada campo bate (vagaId, pacienteIniciais, especialidade, médico, unidade, solicitação).
  3) enviadoTc = false — é STUB. Se algum dia virar true sem integração real, é regressão.
  4) LGPD (regra dura do repo): pacienteIniciais > 20 chars é REJEITADO (400) e NÃO persiste
     — nunca deixa nome completo de paciente entrar no banco.
  5) Campo obrigatório ausente (vagaId vazio) → 400 (lixo rejeitado).

GAPS CONHECIDOS (M1) — testados/reportados, não são falha do harness:
  • A TELA deriva as vagas de FIXTURE (VG-001/VG-002 → UC-COBRE em assuncao/data.ts), não de um
    endpoint de vagas. Por isso exercitamos o POST/GET REAIS da API (o contrato que a tela chama).
  • NÃO há DELETE de agendamento na API → este harness NÃO consegue limpar o que cria. Marca os
    registros com vagaId 'E2E-…' e paciente só por iniciais (LGPD-safe) p/ rastreio.

Uso:  cd infrastructure/scripts && python3 homolog-agendamentos-e2e.py
Sai != 0 em qualquer falha (report()). Zero segredo no código (credenciais no .e2e-env gitignored).
"""
import secrets
import time

from e2e_common import API, api, api_raw, check, login_token, report


def main():
    print(f"E2E Assunção/Agendamentos · API={API}")
    token = login_token()
    print("  login OK (conta e2e-homolog)")

    sufixo = str(int(time.time()))[-6:] + str(secrets.randbelow(1000))
    vaga_id = f"E2E-{sufixo}"
    # Payload = o MESMO shape que confirmar() monta no front (criarAgendamentoApi):
    # vagaId da tela, paciente SÓ iniciais (fixture §6: Maria S.), vínculo à solicitação (D-116),
    # especialidade/médico/unidade do resumo do sheet de assunção.
    payload = {
        "vagaId": vaga_id,
        "pacienteIniciais": "M.S.",
        "solicitacaoId": "UC-COBRE",
        "especialidade": "Cardiologia",
        "medicoNome": "Dr. Henrique Sampaio",
        "unidade": "Núcleo E2E",
    }
    ag_id = None

    # 1) CRIAR — o clique "Confirmar assunção" do sheet
    print("\n1) CRIAR (POST /agendamentos)")
    r = api("POST", "/agendamentos", token, payload)
    check("_status" not in r, f"POST 2xx (retorno: {r.get('_body', r) if '_status' in r else 'ok'})")
    ag_id = r.get("id")
    check(bool(ag_id), "agendamento criado tem id")
    check(r.get("vagaId") == vaga_id, "vagaId retornado bate")
    check(r.get("pacienteIniciais") == "M.S.", "pacienteIniciais (iniciais) retornado bate")
    check(r.get("especialidade") == "Cardiologia", "especialidade retornada bate")
    check(r.get("enviadoTc") is False, "enviadoTc=false no retorno (envio à TC é stub — DEP-TC-1)")

    # 2) LER DE VOLTA pela LISTA — exatamente o que a tela consome (listarAgendamentosApi).
    #    Este é o critério de ouro: o dado tem de dar a volta pelo banco, não só ecoar no POST.
    print("\n2) LER DE VOLTA (GET /agendamentos)")
    lst = api("GET", "/agendamentos", token)
    check(isinstance(lst, list), f"GET /agendamentos devolve lista (got {type(lst).__name__}: "
                                 f"{lst.get('_status') if isinstance(lst, dict) else ''})")
    itens = lst if isinstance(lst, list) else []
    achado = next((a for a in itens if a.get("id") == ag_id), None)
    check(achado is not None, "agendamento aparece na listagem (deu a volta pelo banco)")
    if achado:
        check(achado.get("vagaId") == vaga_id, "vagaId persistiu")
        check(achado.get("pacienteIniciais") == "M.S.", "pacienteIniciais persistiu")
        check(achado.get("especialidade") == "Cardiologia", "especialidade persistiu")
        check(achado.get("medicoNome") == "Dr. Henrique Sampaio", "medicoNome persistiu")
        check(achado.get("unidade") == "Núcleo E2E", "unidade persistiu")
        check(achado.get("solicitacaoId") == "UC-COBRE", "solicitacaoId (vínculo D-116) persistiu")
        check(achado.get("enviadoTc") is False, "enviadoTc=false persistiu (stub DEP-TC-1)")

    # 3) VALIDAÇÃO LGPD (regra dura): paciente por NOME COMPLETO (>20 chars) deve ser REJEITADO,
    #    e não pode deixar rastro no banco. Nunca vaza identidade de paciente.
    print("\n3) VALIDAÇÃO LGPD (nome completo rejeitado + não persiste)")
    nome_completo = "Maria Silva Santos Oliveira"  # 27 chars > 20
    lgpd_vaga = f"E2E-LGPD-{sufixo}"
    r = api("POST", "/agendamentos", token, {**payload, "vagaId": lgpd_vaga, "pacienteIniciais": nome_completo})
    check(r.get("_status") == 400, f"pacienteIniciais>20 → 400 (got {r.get('_status', '2xx')})")
    lst2 = api("GET", "/agendamentos", token)
    itens2 = lst2 if isinstance(lst2, list) else []
    vazou = any(a.get("vagaId") == lgpd_vaga for a in itens2)
    check(not vazou, "payload LGPD rejeitado NÃO persistiu (sem nome completo de paciente no banco)")

    # 4) VALIDAÇÃO campo obrigatório: vagaId vazio → 400 (lixo rejeitado).
    print("\n4) VALIDAÇÃO (vagaId obrigatório)")
    r = api("POST", "/agendamentos", token, {**payload, "vagaId": "  "})
    check(r.get("_status") == 400, f"vagaId em branco → 400 (got {r.get('_status', '2xx')})")

    # 5) LIMPEZA — não existe DELETE de agendamento na API (stub M1). Tenta e apenas ANOTA o
    #    resultado (não faz check: a ausência de DELETE é gap conhecido, não falha do harness).
    print("\n5) LIMPEZA (gap M1: API não expõe DELETE de agendamento)")
    if ag_id:
        d = api_raw("DELETE", f"{API}/agendamentos/{ag_id}", token=token)
        st = d.get("_status", "2xx") if isinstance(d, dict) else "2xx"
        print(f"  [i] DELETE /agendamentos/{ag_id} → {st} — sem endpoint de exclusão; "
              f"registro E2E fica no banco marcado vagaId={vaga_id} (paciente só iniciais).")

    report("HOMOLOGAÇÃO E2E DE ASSUNÇÃO/AGENDAMENTOS")


if __name__ == "__main__":
    main()
