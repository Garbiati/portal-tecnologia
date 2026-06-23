---
title: Documentação de Arquitetura — Índice
status: draft
date: 2026-06-14
author: Staff Architect (agente)
---

# Arquitetura — Saúde Digital · Demandas ("Agenda Fixa")

> Documentação de arquitetura do **cockpit a montante** que tira o controle do Excel (D-019) e
> alimenta a Teleconsulta a jusante (D-002/D-003). **Factual e rastreável**: nenhuma regra de negócio
> foi inventada — cada uma cita um `D-xxx` (`../decisions/decisions-log.md`) ou um doc de descoberta.
> O que falta está marcado 🔴 (bloqueia) / 🟡 (importante). **Stack NÃO é escolhida (D-001).**

## Documentos

| # | Documento | Conteúdo |
|---|---|---|
| 00 | [00-overview.md](./00-overview.md) | **Contexto C4 (L1/L2)**: Demandas (montante) → Teleconsulta (jusante); atores/papéis (D-008); clientes público/privado (D-018); fronteira de integração (D-002). |
| 01 | [01-domain-model.md](./01-domain-model.md) | **Bounded contexts e agregados** (Cliente/HC; Médico+Escala+Estoque; Solicitação; Disponibilização; Assunção+Agendamento; Remanejamento; Monitor/Integração; RBAC; Auditoria) + **invariantes-chave** (D-003, D-005, D-011, D-013) + perguntas abertas. |
| 02 | [02-system-design.md](./02-system-design.md) | **Arquitetura proposta**: monólito modular + **Adapter de Integração TC** (idempotência por `external_id`, retry/backoff, **monitor proativo da janela** que mata os 7,7%) + padrões de resiliência (outbox, read-models, jobs, observabilidade) + contratos de API + Auth/RBAC + **opções de stack (DECISÃO ABERTA — D-001)**. |
| 03 | [03-sdd-tdd-e-agentes-paralelos.md](./03-sdd-tdd-e-agentes-paralelos.md) | **SDD+TDD** (spec→teste→código, hooks de enforcement) + como **múltiplos agentes de IA trabalham em paralelo sem quebrar a arquitetura** + **mapa de paralelização** dos módulos. Aplica o método de plataforma (`../../../../docs/method/`) ao domínio Doctor-Hub. |

## Decisões de arquitetura que orientam estes docs

- **D-001** — stack/linguagem/banco **não decididos** (gate de fase). Aqui apresentamos opções, não escolhemos.
- **D-002** — repo **separado**, integra com a TC como **parceiro** via `X-API-KEY`.
- **D-003** — alocação de médico é **nossa** (`preference_of_doctor_id`); TC respeita.
- **D-008 / D-010** — só 3 papéis logam (Admin/Demandas, Solicitante, Gestor); Doutor/Paciente são dados.
- **D-013** — remanejamento por janela configurável, critério "demanda não atendida", determinístico.
- **D-018** — clientes público/privado, acima de HC.
- **D-019** — problema-núcleo = sair do Excel; o Monitor proativo ataca os **7,7%** de perda por janela.

## Bloqueios abertos (🔴) que afetam a construção

1. **Regra de prazo da "janela de envio"** (gatilho do Monitor) — não definida (`../discovery/05-processo-manual-excel.md` §8; `../../specs/monitor-integracao/ui.md` §8).
2. **Fonte do funil de integração** (nossa integração TC vs hub externo AM/SISReg) — a confirmar.

## Referências cruzadas

- Decisões: `../decisions/decisions-log.md` (D-001..D-020, M-001..M-004)
- Domínio: `../discovery/01-domain-overview.md`, `02-roles.md`, `03-open-questions.md`
- Integração (contrato factual): `../discovery/04-integration-teleconsulta.md`
- Processo manual (Excel / 7,7%): `../discovery/05-processo-manual-excel.md`
- Produto/escopo/fases: `../product/02-scope-entrega-1.md`, `07-fases-entrega.md`
- Design system: `../../design/design-system.md`, `../../design/BUILD-PROGRESS.md`, `../../design/tokens.*`
- UI-specs: `../../specs/*/ui.md`
- Enforcement (método de plataforma): `docs/method/spec-first-hook.md`
