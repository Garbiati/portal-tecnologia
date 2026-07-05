#!/usr/bin/env python3
"""Semeia um CENÁRIO DE DEMO REAL (D-155/doc 29 #2) contra prod: escalas + solicitações reais
em médicos e clientes reais, gerando um quadro capacidade × demanda com DÉFICIT visível no painel.
Reversível: reset-ambiente.sh limpa o transacional. Idempotência simples por apelido/tag."""
import sys, e2e_common as e
tok = e.login_token()
docs = e.api("GET", "/doctors", tok)
docs = docs if isinstance(docs, list) else docs.get("itens", [])
clientes = [c for c in e.api("GET","/clientes",tok) if c.get("ativo")]
# médicos por especialidade (1º nome de espec.)
por_esp = {}
for d in docs:
    esps = d.get("especialidades") or []
    if not esps: continue
    nome = esps[0]["nome"] if isinstance(esps[0], dict) else esps[0]
    por_esp.setdefault(nome, []).append(d)

# Escalas: cria oferta em algumas especialidades (varia dias/tipo/projeto)
plano_esc = [
    ("Clínico Geral",       3, ["Seg","Ter","Qua","Qui","Sex"], [{"inicio":"08:00","fim":"14:00"}], "teleatendimento", "C-a1c8e688"),
    ("Cardiologia",         1, ["Seg","Qua"],                    [{"inicio":"08:00","fim":"12:00"}], "teleatendimento", "C-a1c8e688"),
    ("Dermatologia",        1, ["Ter","Qui"],                    [{"inicio":"09:00","fim":"13:00"}], "laudo",           None),
    ("Ortopedia",           1, ["Seg","Sex"],                    [{"inicio":"08:00","fim":"12:00"}], "atendimento",     "C-770c5438"),
    ("Psiquiatria",         1, ["Qua"],                          [{"inicio":"14:00","fim":"18:00"}], "teleatendimento", "C-a1c8e688"),
]
criadas = 0
for esp, n, dias, blocos, tipo, cli in plano_esc:
    for d in (por_esp.get(esp) or [])[:n]:
        body = {"especialidade": esp, "tipo":"FIXA", "dias":dias, "blocos":blocos,
                "duracaoMin":30, "vigencia":{"inicio":"2026-07-06"}, "tipoServico":tipo, "clienteId":cli}
        r = e.api("POST", f"/doctors/{d['id']}/escalas", tok, body)
        if "_status" not in r: criadas += 1
print(f"  escalas criadas: {criadas}")

# Solicitações: demanda por cliente/especialidade — algumas > capacidade (déficit), outras cobertas
# demanda por cliente/especialidade — sigla real dos clientes
sig = {c["id"]: c["sigla"] for c in clientes}
piaui = sig.get("C-a1c8e688"); amaz = sig.get("C-770c5438")
demanda = [
    (piaui, "Cardiologia", 300),   # capacidade baixa → DÉFICIT grande
    (piaui, "Clínico Geral", 120), # capacidade alta → coberto/quase
    (piaui, "Psiquiatria", 80),    # continuidade → déficit
    (amaz,  "Ortopedia", 90),
]
scr = 0
for cli_sig, esp, qtd in demanda:
    if not cli_sig: continue
    r = e.api("POST","/solicitacoes",tok,{"clienteSigla":cli_sig,"especialidade":esp,"qtd":qtd,
              "aPartirDe":"06/07","ate":"31/07","apelido":f"DEMO-DIR {esp}","retorno":0})
    if "_status" not in r: scr += 1
    else: print("   sol erro:", r.get("_body","")[:80])
print(f"  solicitações criadas: {scr}")
print("✓ cenário de demo semeado (reversível via reset-ambiente.sh)")
