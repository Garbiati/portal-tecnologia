---
id: UI-MEDICOS-ESCALA
title: Médicos & Escala (perfil do médico + escalas FIXA/FLEX)
status: specified
area: Oferta (escalas / estoque)
last_update: 2026-06-24
---

# UI-spec — Médicos & Escala (v2)

> Regras de negócio: [`./spec.md`](./spec.md) (D-120..D-123). Figma: frame "Escala" (`2:2`).
> **Princípio de UX (pedido do Alessandro):** a escala vive **dentro do cadastro/perfil do médico**
> (menos telas). **Responsivo, UX amigável, didático e elegante.**

## 1. Arquitetura de telas (1 tela, 2 níveis)

- **Nível A — Lista de médicos:** tabela (nome+foto · especialidades · status · capacidade ≈ no período).
  Filtros derivados (Todos · Com fixa · Só flex · Temporários · Inativos). Ação **+ Novo médico**.
- **Nível B — Perfil do médico** (abre da linha, painel à direita em ≥lg / página no mobile):
  1. **Cabeçalho:** foto + nome + CRM + **especialidades** (chips) + status. Ações: editar dados, ← voltar.
  2. **Visão consolidada (semana efetiva = FIXA + Σ FLEX):** grade semanal/heatmap dos slots ocupados,
     com legenda **FIXA** (azul) × **FLEX** (laranja). Banner de **estoque ≈ N vagas** por especialidade no período.
  3. **Escalas** (lista de cards) + **+ Criar escala**. Cada card:
     - Linha 1: `especialidade` · badge **FIXA**/**FLEX** · badge status (ativa/encerrada) · **vigência**
       (FIXA "desde dd/mm · sem fim" · FLEX "dd/mm hh:mm–dd/mm hh:mm").
     - Linha 2: dias + **blocos** ("Ter/Qui · 08:00–12:00 e 13:00–17:00 · 20 min") + "≈ N vagas".
     - Ações: **Linha do tempo** (histórico — placeholder) · **Excluir** (🔒 cadeado se já iniciada — §4).

## 2. Criar / editar escala (drawer ou modal — reusar design system)

Campos (todos com os componentes do DS — `Select`, `Chip`, `Input`, **`DataInput`**, máscaras):
- **Tipo:** segmented **FIXA** | **FLEX** (com microcopy didático: "FIXA = contrato, sem fim · FLEX = período, horas extras").
- **Especialidade:** `Select` com as **especialidades do médico** (INV-5).
- **Dias da semana:** `Chip` toggle (Seg…Dom).
- **Blocos de horário:** lista de `{início, fim}` com **+ adicionar bloco** / remover (permite almoço; INV-4).
- **Consultas/hora** (ou min/atendimento) — `Input` number.
- **Vigência:**
  - FIXA → **data de início** (`DataInput`, ≥ amanhã se substitui — INV-3). Ao salvar com FIXA já existente,
    mostrar o **assistente de troca** (encerra a atual em _data-fim_ default hoje; nova inicia default amanhã;
    editável p/ futuro e com intervalo — D-121).
  - FLEX → **início (data+hora)** e **fim (data+hora)** — granularidade por hora (D-122).
- **Banner de estoque ao vivo:** "≈ N vagas no período" recalcula a cada mudança (D-111/D-112/D-122), ANTES de salvar.
- **Validação inline:** fim ≤ início (bloco/vigência); blocos sobrepostos; **conflito de slot** com outra
  escala do médico (INV-1) → erro claro indicando qual escala conflita; especialidade fora das do médico (INV-5).

## 3. Estados
- **Vazio (médico sem escala):** `.empty-state` "Sem escala — defina a oferta deste médico" + **+ Criar escala**.
- **Loading:** `.skeleton` na lista/grade; banner de estoque em skeleton ao recalcular.
- **Erro de validação:** borda `--color-danger` + mensagem no campo (conflito de slot, fim≤início, retroação).
- **Sucesso:** `.toast` "Escala criada/encerrada" + grade consolidada e estoque atualizados.

## 4. Excluir escala (D-123)
- Início **no futuro** → botão **Excluir** comum, confirma e exclui.
- Já **iniciada** → botão **Excluir 🔒** → **modal "Confirmar exclusão (gestão)"** pedindo a **senha de gestão**
  (`Input` type=password). Senha correta → exclui; errada → erro. **Registra auditoria** (quem, quando, resultado).

## 5. Responsivo / acessibilidade
- **≥ lg:** lista (esq.) + perfil/escala (dir.). **md:** sidebar em rail, 1 coluna, grade full-width.
- **< md:** lista vira cards; perfil em página; grade semanal com scroll horizontal; chips/blocos com alvos ≥44px;
  inputs de hora/data com `font-size:16px`. WCAG AA (foco visível, contraste, labels associadas).
- **Didático:** microcopy explicando FIXA×FLEX; legenda da grade; tooltip do cadeado ("exige senha de gestão").

## 6. Pendências de UI
- 🟢 **Linha do tempo** (vigências/histórico) e **Arquivar** — placeholders.
- 🟡 grade consolidada: definir visual final (heatmap × lista de slots) na homologação.
