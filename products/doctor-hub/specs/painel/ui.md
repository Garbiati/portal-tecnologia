---
id: UI-PAINEL
title: Painel / Visão Geral
status: draft
area: Visibilidade (visões macro · por cliente · consolidado)
last_update: 2026-06-14
---

# UI-spec — Painel / Visão Geral

> Telas Figma: **Visão geral** (id `28:2`) e **Painel/Visões** (id `32:2`) (`design/BUILD-PROGRESS.md`).
> Substitui a aba `Visão Geral` do Excel (`05-processo-manual-excel.md` §2).

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** o "raio-x do dia" hoje é uma aba de Excel montada por export (KPIs, volume por dia, top
  especialidades, unidades) que o operador olha primeiro mas que é **snapshot descartável sem
  histórico/diff** (`05-processo-manual-excel.md` §2 e §6, dor 1).
- **De quem:** Admin/Demandas.
- **Evidência:** D-019 + aba `Visão Geral` da planilha.
- **Sucesso = quando:** o operador vê, em tempo real e por Cliente/HC, total a entregar, taxa de
  integração e onde estão as pendências (por dia, especialidade, unidade) — **sem exportar planilha**.

## 2. Layout
**Shell:** `.sidebar` (nav "Visão geral / Painel" `.nav-item--active`) + `.topbar` (**Admin · PTM**).

Seções:
1. **Cabeçalho + filtros** — Cliente (`.select`, D-018; inclui "Todos os clientes" = consolidado) ·
   HC · período. Segmented `.chip` (por HC / consolidado).
2. **Faixa de KPIs** (`.kpi`) — Total futuro · Média/dia · Pico · **Taxa de integração** ·
   Saldo/pendentes (cores neutral/success/warning conforme o valor).
3. **Volume por dia** (`.card` com barras `.kpi`/gráfico simples) — Data · Total · Integrados ·
   Pendentes · **Situação** (semáforo `.badge`: ✅ Completo / ⚠️ N pendentes).
4. **Top especialidades** (`.table`) — Especialidade · Total · % · Integrados · Pendentes (barra).
5. **Unidades / Capital vs Interior** (`.table`/`.card`) — Unidade · Total · % · Integrados.
6. **Atividade recente** (`.card`/lista) — eventos de simular/reservar/emitir/assumir.

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| filtro.cliente / hc / periodo | ref / mês | Clientes & HCs (D-018) |
| kpi.total_futuro / media_dia / pico | inteiro | agregação dos agendamentos/vagas do sistema |
| kpi.taxa_integracao | % | derivado (integrados / total) — métrica nativa (§7 análise planilha) |
| volume_por_dia[] | linhas (data, total, integrados, pendentes, situação) | agregação por dia |
| top_especialidades[] | linhas (especialidade, total, %, integrados, pendentes) | agregação por especialidade |
| unidades[] | linhas (unidade, total, %, integrados) | agregação por HC/unidade |
| situacao (semáforo) | enum | regra ✅ Completo / ⚠️ N pendentes (espelha o Excel) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** KPIs + blocos preenchidos para o filtro atual.
- **Vazio:** `.empty-state` — "Sem dados para o período/cliente selecionado".
- **Loading:** `.skeleton` em KPIs, barras e tabelas durante a carga.
- **Erro:** `.error-state` 403/500.
- **Sucesso:** não há ação de escrita aqui (tela de leitura); reflete dados ao reabrir/atualizar.

## 5. Comportamento responsivo (D-015)
- **≥ lg:** KPIs em linha + blocos em grade 2–3 colunas.
- **md–lg:** `.sidebar` em rail; **KPIs 2 colunas**; blocos em 1–2 colunas; tabelas com scroll.
- **< md:** top app bar + `.drawer`; **KPIs 1–2 col**; **tabelas → cards empilhados**; barras
  simplificadas; 1 coluna.

## 6. Regras de negócio
- **D-018** — visões **por HC** e **consolidada** (todos os clientes); filtro por Cliente.
- **D-019** — internaliza a camada de visibilidade que hoje é export de Excel.
- Métricas nativas (taxa de integração, pendências, latência) substituem o painel montado por export
  (`05-processo-manual-excel.md` §7).
- **D-008** — visão é do **Admin/Demandas** (escopo global).

## 7. Critérios de aceite (EARS)
- QUANDO o operador seleciona "Todos os clientes", O SISTEMA DEVE exibir a visão consolidada de todos os clientes (D-018).
- QUANDO o operador seleciona um Cliente/HC, O SISTEMA DEVE recalcular KPIs e blocos para aquele escopo.
- QUANDO um dia tem pendências, O SISTEMA DEVE marcá-lo no semáforo como "⚠️ N pendentes"; QUANDO não tem, como "✅ Completo".
- QUANDO não há dados para o filtro, O SISTEMA DEVE exibir o estado vazio.
- QUANDO os dados estão carregando, O SISTEMA DEVE exibir skeletons em KPIs e tabelas.
- QUANDO um usuário sem papel Admin acessa o painel, O SISTEMA DEVE responder com erro 403 (D-008).

## 8. Perguntas abertas
- 🟡 Quais KPIs exatos entram na v1 (o conjunto do Excel é amplo) e quais são derivados vs nativos.
- 🟡 Definição de "integrado" no nosso sistema (a planilha vem do hub AM; é o mesmo conceito? — `05-processo-manual-excel.md` §8, "REGULA-HUB é o mesmo cliente?").
- 🟡 Há histórico/diff entre períodos (a dor nº 1 do Excel é a falta de diff) — escopo da v1?
- 🟢 "PDF Modelo" de cobertura citado no whiteboard pertence ao Mapa de Cobertura, não a este painel (`03-open-questions.md`).
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
