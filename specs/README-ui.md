---
id: UI-INDEX
title: Índice de UI-specs (Handoff de Telas do Cockpit)
status: draft
area: Design/Handoff
last_update: 2026-06-14
---

# `specs/<slug>/ui.md` — UI-specs de Handoff

> Cada tela do cockpit ("sair do Excel", D-019) tem uma **UI-spec de handoff** que descreve
> layout, dados, estados, responsividade, regras (rastreadas ao `decisions-log`) e critérios de
> aceite em notação **EARS**. É o artefato #5 do handoff zero-inferência do design system
> (`design/design-system.md` §8) e entra no ciclo **spec → teste → código** (`specs/README.md`).
>
> ⚠️ **Zero inferência de regra de negócio** (Diretriz Suprema, `CLAUDE.md`). Onde a regra não
> está confirmada em `docs/discovery/` ou no `decisions-log`, ela aparece aqui como
> **Pergunta aberta 🔴/🟡** — nunca como decisão silenciosa.

## Relação entre `ui.md` e `spec.md`
- `spec.md` (template `_template/spec-template.md`) = contrato funcional/regras/Gherkin de uma feature.
- `ui.md` (este conjunto) = **camada de apresentação** dessa feature: como a tela se monta sobre os
  componentes, seus estados e seu comportamento responsivo. As duas convivem na mesma pasta `slug/`.

## Índice das telas do cockpit
| # | Slug | Tela | Papel principal | Etapa do pipeline | Milestone (06-roadmap-telas) |
|---|------|------|-----------------|-------------------|------------------------------|
| 1 | [`clientes-hcs`](./clientes-hcs/ui.md) | Clientes & HCs | Admin/Demandas | Cadastro base (D-018) | — (novo, BUILD-PROGRESS) |
| 2 | [`medicos-escala`](./medicos-escala/ui.md) | Médicos & Escala | Admin/Demandas | ① Oferta | M1 |
| 3 | [`solicitacao`](./solicitacao/ui.md) | Solicitação | Solicitante (Sec. estadual) | ② Demanda | M2 |
| 4 | [`disponibilizacao`](./disponibilizacao/ui.md) | Disponibilização | Admin/Demandas | ③ Alocação | M3 |
| 5 | [`assuncao`](./assuncao/ui.md) | Assunção de Vagas | Gestor local (HC) | ④ Assunção → ⑤ Agendamento | M4 |
| 6 | [`painel`](./painel/ui.md) | Painel / Visão Geral | Admin/Demandas | Visibilidade | M6 |
| 7 | [`monitor-integracao`](./monitor-integracao/ui.md) | Monitor de Integração / Janela | Admin/Demandas | Visibilidade + SLA | Fase 2 (diferencial) |

## Convenção de cada `ui.md`
Frontmatter obrigatório: `id`, `title`, `status: draft`, `area`, `last_update`.

Seções (nesta ordem):
1. **Propósito / Dor** — Definition of Success (outcome, não output).
2. **Layout** — shell (sidebar + topbar) + seções da tela em termos de **componentes** do
   design system (tabela §5 de `design-system.md`; classes canônicas em `design/components/components.css`).
3. **Dados & campos** — nome, tipo e **origem** de cada campo (ex.: paciente vem da TC por HC, D-012).
4. **Estados** — default · vazio · erro · loading · sucesso (referência: board **"Estados"** id `36:2`,
   `design/BUILD-PROGRESS.md`; estados obrigatórios §6 de `design-system.md`).
5. **Comportamento responsivo** — desktop ≥lg / tablet md–lg / mobile <md (D-015, §7 design-system).
6. **Regras de negócio** — cada uma com seu `Dxxx` do `docs/decisions/decisions-log.md`.
7. **Critérios de aceite (EARS)** — `QUANDO <gatilho>, O SISTEMA DEVE <resposta>`.
8. **Perguntas abertas** — 🔴 bloqueia · 🟡 importante · 🟢 pode esperar.

## Fontes canônicas (read-only) usadas por estas specs
- `CLAUDE.md` (Diretriz Suprema), `docs/decisions/decisions-log.md` (Dxxx).
- `design/design-system.md`, `design/tokens.css`, `design/tokens.json`, `design/BUILD-PROGRESS.md`.
- `docs/discovery/01-domain-overview.md`, `02-roles.md`, `03-open-questions.md`,
  `04-integration-teleconsulta.md`, `05-processo-manual-excel.md`, `glossary.md`.
- `docs/product/02-scope-entrega-1.md`, `06-roadmap-telas.md`.

## Nota sobre `design/components/components.css`
A pasta `design/components/` está prevista no handoff (§8 do design-system; item ⏭️ de
`BUILD-PROGRESS.md`) mas **ainda não contém `components.css`** no momento desta redação. As classes
referenciadas abaixo (`.btn`, `.input`, `.table`, `.kpi`, `.badge`, `.chip`, `.nav-item`,
`.sidebar`, `.topbar`, `.drawer`, `.toast`, `.empty-state`, `.error-state`, `.skeleton`, etc.)
correspondem 1:1 ao inventário de componentes do **UI Kit** (Figma id `24:2`) e à tabela §5 do
design system, e são a nomenclatura-alvo desse arquivo. Ver **Pergunta aberta** em cada spec.
