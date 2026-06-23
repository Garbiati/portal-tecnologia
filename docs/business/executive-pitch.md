---
title: Executive Pitch — Cockpit de Demandas
status: draft
date: 2026-06-14
audience: diretoria / decisão de aprovação
---

# Do Excel reativo ao cockpit proativo

> One-pager executivo. Tirar o controle de atendimentos do Excel manual e antecipar a perda — antes da janela expirar.

---

## A dor

Hoje, o controle de demanda de teleconsultas vive em **planilhas Excel** mantidas **manualmente por 1-2 pessoas, horas por dia**, fora de qualquer sistema.

- **Perda silenciosa de 7,7% ao mês.** Cerca de 1 em cada 13 agendamentos expira por "janela de envio vencida" — e isso só fica **visível depois** que já se perdeu. É controle 100% **reativo**: o retrovisor, não o para-brisa.
- **Capacidade do médico vista tarde demais.** "Sem médico / horário ocupado" só aparece **depois** que o slot estourou. Não há visão prévia de oferta versus demanda por especialidade.
- **Sem histórico, sem rastro.** A demanda muda entre exportações (de 947 para 1.547 agendamentos em 2 dias) e cada planilha é um snapshot descartável que o operador compara de cabeça.
- **Risco LGPD.** Dados sensíveis de paciente (CNS, telefone, nascimento) trafegam em **planilha Excel local**, sem base legal nem auditoria.

**Em resumo:** uma operação crítica de saúde governada por arquivos manuais, que enxerga os problemas só depois que viram prejuízo.

---

## A solução

Um **cockpit** que tira o controle do Excel e o coloca num sistema auditável — e, sobre ele, um **Monitor proativo** que alerta **antes** da perda acontecer.

**O cockpit (substitui a planilha):**
1. **Registra a demanda** — o cliente informa quanto precisa ("preciso de N de cardiologia no mês").
2. **Propõe a capacidade** — o sistema responde: temos? quantos? Calcula o saldo em tempo real (estoque − demanda).
3. **Decide com visão certa** — por **Health Center** (ex.: Piauí) ou **consolidado** (todos os clientes, **público e privado**).
4. **Agenda integrado à Teleconsulta** — agendamento completo (médico + paciente + especialidade) inserido direto na plataforma, com médico preferencial e fallback por especialidade.

**O Monitor proativo (o diferencial):**
- Acompanha o funil de integração e **dispara alerta ANTES da janela expirar**, convertendo a perda de 7,7% — hoje só vista no retrovisor — em **fila de ação preventiva**.

---

## Antes × Depois

| | Antes (Excel manual) | Depois (Cockpit + Monitor) |
|---|---|---|
| **Controle** | Planilhas mantidas à mão, horas/dia | Sistema único, auditável |
| **Perda (7,7%/mês)** | Vista depois de perdida | Alerta **antes** da janela expirar |
| **Capacidade do médico** | Estouro visto a posteriori | Saldo calculado **antes** de reservar |
| **Histórico** | Snapshots soltos, sem diff | Estado consultável, rastreável |
| **Decisão** | Painel estático por export | Por HC **ou** consolidado, em tempo real |
| **LGPD** | Dado sensível em arquivo local | Dado em sistema com base legal e auditoria |

---

## Big numbers + ROI

| Métrica | Valor |
|---|---|
| Agendamentos/mês processados | **~5.400** |
| Perda mensal hoje (janela expirada) | **7,7%** (~420 casos/mês) |
| Pessoas dedicadas ao controle manual | **1-2**, horas/dia |
| Taxa de integração atual | **~96%** |
| SLA-alvo agendamento→atendimento | **15 dias** |

**ROI (referência — ver `cost-roi-analysis.md`):**
- **Recuperação de perda:** reduzir os 7,7% mensais via alerta proativo → `[valor recuperado/mês: a calcular]`.
- **Horas liberadas:** eliminar o controle manual de 1-2 pessoas → `[FTE economizado: a calcular]`.
- **Investimento:** `[custo das Fases 0/1/2 a R$180/h: a calcular]`.
- **Payback estimado:** `[a calcular]`.

> Números operacionais extraídos das planilhas reais (`docs/discovery/05-processo-manual-excel.md`). Os campos `[a calcular]` serão preenchidos em `cost-roi-analysis.md`.

---

## Por que agora

A entrega é **AI-Driven** — agentes de IA construindo arquitetura e código sob disciplina de specs (SDD) e testes (TDD):

- **Mais rápida** — fases de capacidade de ~3 e ~6 semanas, com protótipo navegável já na semana 0.
- **Previsível** — escopo fatiado por tela, com checkpoint semanal; cada fase é apresentável e faturável isoladamente.
- **Auditável** — spec como fonte da verdade, zero inferência de regra de negócio, enforcement por hooks. Nada de "caixa-preta".

O **entregável da Semana 0 já está pronto:** protótipo Figma 100% navegável (21+ telas, desktop + mobile), handoff de design e arquitetura completos.

---

## A oferta / o pedido

| Fase | O que entrega | Prazo (capacidade) | Pedido |
|---|---|---|---|
| **Fase 0** | "Ver o produto" — Figma navegável de alta fidelidade + specs de dev | Semana 0 (**pronto**) | **Homologar** o protótipo |
| **Fase 1** | "Sair do Excel" — o cockpit de planejamento (clientes/HCs, capacidade, solicitação, saldo, painel consolidado, exportável) | ~3 semanas | **Aprovar** início do build |
| **Fase 2** | "Executar e integrar" — assunção de vagas, agendamento → Teleconsulta, remanejamento, auditoria/LGPD | ~6 semanas (acum.) | Aprovar na sequência |

**O que pedimos agora:**
1. **Homologar a Fase 0** (o produto já está visível e navegável).
2. **Aprovar a Fase 1** — o cockpit que tira a operação do Excel e captura o ganho mais cedo.

> Fase 1 já entrega valor: a operação deixa o Excel, o controle passa a ser auditável, e o Monitor começa a evitar a perda de 7,7%/mês.
