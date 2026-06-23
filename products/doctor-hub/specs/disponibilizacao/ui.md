---
id: UI-DISPONIBILIZACAO
title: Disponibilização
status: draft
area: Alocação (estoque × demanda · simular/reservar/emitir)
last_update: 2026-06-14
---

# UI-spec — Disponibilização

> Etapa ③ Alocação (núcleo) do pipeline (`01-domain-overview.md`). Tela Figma de fluxo:
> **Disponibilização** com 4 KPIs (demanda/estoque/saldo/>30d) + Simular/Reservar/Emitir
> (`docs/design/figma-prototipo.md`). É a tela mais pesada (M3, `06-roadmap-telas.md`).

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** hoje o operador **compara mentalmente snapshots** `(1)(2)(3)` do Excel; "Sem médico" é o
  sinal tardio de estouro; não há saldo em tempo real (`05-processo-manual-excel.md` §6, dores 1 e 2).
- **De quem:** Admin/Demandas.
- **Evidência:** D-019 + §7 da análise de planilha ("Simular saldo" elimina o diff manual).
- **Sucesso = quando:** o operador casa demanda × estoque, vê **saldo +/- em tempo real**, identifica
  vagas com prazo de atendimento > 30 dias, e **reserva** (baixa estoque) e **emite** (publica p/ o HC assumir).

## 2. Layout
**Shell:** `.sidebar` (nav "Disponibilização" `.nav-item--active`) + `.topbar` (**Admin · PTM**).

Seções:
1. **Cabeçalho + filtros** — Cliente (`.select`, D-018) · HC · Período (mês). Título `2xl/semibold`.
2. **Faixa de KPIs** (`.kpi`, 4 cartões): **Demanda** (neutral) · **Estoque** (neutral) ·
   **Saldo +/-** (`.kpi--success` se ≥0 / `.kpi--danger` se <0) · **Vagas > 30 dias** (`.kpi--warning`).
3. **Barra de ações** — `.btn--secondary` ("Simular") · `.btn--subtle` ("Limpar") ·
   `.btn--primary` ("Reservar") · `.btn--primary` ("Emitir"). Ações de progressão.
4. **Tabela estoque × demanda** (`.table`) — por especialidade: Especialidade · Qtd solicitada
   (Gov) · Qtd a disponibilizar · Retornos/Extras (manual) · **Saldo +/-** (`.badge` success/danger)
   · flag ">30d" (`.badge--warning`). Header `.table__header`.

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| filtro.cliente / hc / periodo | ref / mês | Clientes & HCs (D-018) + Solicitação |
| linha.qtd_solicitada | inteiro | Solicitação (② Demanda) |
| linha.qtd_a_disponibilizar | inteiro | calculado/editável na Disponibilização |
| linha.retornos_extras | inteiro (manual) | ajuste manual de estoque (D-005) |
| linha.saldo | inteiro (derivado +/-) | **simular**: demanda × estoque (`01-domain-overview.md` ③) |
| flag.maior_30_dias | booleano | regra de vagas > 30 dias (`01-domain-overview.md` ③) |
| kpi.estoque | inteiro | estoque calculado das escalas (D-005, tela Médicos & Escala) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** KPIs + tabela após escolher cliente/HC/período.
- **Vazio:** `.empty-state` — "Selecione cliente, HC e período para simular" ou "Nenhuma demanda
  para este período".
- **Loading:** `.skeleton` na tabela e KPIs durante "Simular"; spinner no `.btn--loading` em
  Reservar/Emitir.
- **Erro:** `.error-state` 403/500; banner de erro se reservar sem estoque suficiente.
- **Sucesso:** `.toast` "Simulação concluída" / "Vagas reservadas" / "Vagas emitidas"; saldo recolorido.

## 5. Comportamento responsivo (D-015)
- **≥ lg:** 4 KPIs em linha + barra de ações + tabela full.
- **md–lg:** `.sidebar` em rail; **KPIs 2 colunas**; tabela com scroll horizontal.
- **< md:** top app bar + `.drawer`; **KPIs 1–2 col**; **tabela → cards empilhados** por
  especialidade (saldo em destaque); ações em **bottom-sheet**.

## 6. Regras de negócio
- **D-003** — A **alocação de médico é NOSSA**: o sistema decide o médico (`preference_of_doctor_id`);
  a Disponibilização é a etapa que prepara essa alocação.
- **D-005** — Estoque misto (calculado + retornos/extras manuais) alimenta a coluna de estoque/saldo.
- Ações **Simular → Limpar → Reservar → Emitir** (`01-domain-overview.md` ③): Simular calcula saldo
  sem efetivar; Reservar bloqueia escala e baixa estoque; Emitir publica para o HC assumir.
- Flag de **vagas > 30 dias** sinalizada na simulação (`01-domain-overview.md` ③; SLA edital 15 dias
  agendamento→atendimento — `05-processo-manual-excel.md` §5).
- **D-008** — operação é do **Admin/Demandas**.

## 7. Critérios de aceite (EARS)
- QUANDO o operador aciona "Simular", O SISTEMA DEVE calcular o saldo (demanda × estoque) por especialidade sem efetivar reserva.
- QUANDO o saldo de uma especialidade é negativo, O SISTEMA DEVE exibi-lo com a cor/badge de danger; QUANDO é ≥ 0, com a cor/badge de success.
- QUANDO uma vaga tem prazo de atendimento superior a 30 dias, O SISTEMA DEVE sinalizá-la com a flag ">30d".
- QUANDO o operador aciona "Reservar", O SISTEMA DEVE bloquear a escala e baixar a quantidade reservada do estoque.
- QUANDO o operador aciona "Emitir", O SISTEMA DEVE publicar as vagas para o HC poder assumi-las.
- QUANDO o operador tenta reservar mais do que o estoque disponível, O SISTEMA DEVE bloquear a ação e exibir erro.
- QUANDO uma ação (simular/reservar/emitir) conclui, O SISTEMA DEVE exibir um toast correspondente.

## 8. Perguntas abertas
- 🟡 **Granularidade do estoque** (contagem vs horário concreto) impacta como o saldo é exibido (`03-open-questions.md`).
- 🟡 Regra exata da flag ">30 dias" (a partir de qual data? data de atendimento prevista?).
- 🟡 Estado/transição entre Reservar e Emitir (pode reverter? "Limpar" desfaz reserva?) — glossário marca Reservar/Emitir como 🟡.
- 🟡 Como o médico é amarrado nesta etapa vs na Assunção (D-003 diz alocação nossa; ponto de decisão a confirmar).
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
