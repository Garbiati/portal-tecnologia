---
id: UI-MEDICOS-ESCALA
title: Médicos & Escala
status: draft
area: Oferta (escala fixa / estoque)
last_update: 2026-06-14
---

# UI-spec — Médicos & Escala

> Etapa ① Oferta do pipeline (`01-domain-overview.md`). Tela Figma de fluxo: **Médicos & Escala**
> (`docs/design/figma-prototipo.md`) com banner "≈ 208 vagas".

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** hoje a **capacidade do médico só é vista por consequência** — "Sem médico / horário
  ocupado" aparece **depois** que o slot estourou (`05-processo-manual-excel.md` §6, dor 2). Não há
  visão prévia de oferta por especialidade-horário.
- **De quem:** Admin/Demandas.
- **Evidência:** achado da planilha (Substatus "Sem médico" 712 casos) + D-005.
- **Sucesso = quando:** ao cadastrar médico + escala fixa, o sistema **calcula o estoque de vagas
  antes** (não a posteriori), e esse estoque alimenta a Disponibilização.

## 2. Layout
**Shell:** `.sidebar` (nav "Médicos & Escala" `.nav-item--active`) + `.topbar` (**Admin · PTM**).

Seções:
1. **Cabeçalho** — título + `.btn--primary` ("Novo médico").
2. **Lista de médicos** (`.table`) — Nome · Especialidade · Status (`.badge` ativo/inativo) ·
   Vagas calculadas (`.kpi` inline). Linha `.table__row--interactive` abre o detalhe.
3. **Formulário Médico + Escala** (`.card` / `.drawer`):
   - Bloco **Dados do médico** (`.input`/`.select`): nome, especialidade.
   - Bloco **Escala fixa**: dias de atendimento (`.chip` toggle por dia), horário (início/fim,
     `.input` time), consultas por hora (`.input` number), período válido (date range), flag
     ativo/inativo (`.switch`).
   - **Banner de estoque calculado** (`.card` com `.kpi--neutral`): "≈ N vagas no período"
     (derivado da escala — D-005).
   - Bloco **Ajuste manual** (retornos/extras) — `.input` + nota de auditoria.
4. Ações: `.btn--primary` ("Salvar") · `.btn--secondary` ("Cancelar").

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| medico.nome | texto | cadastro Admin (`01-domain-overview.md` ①); **Doutor é DADO, não usuário** (D-010) |
| medico.especialidade | texto/ref | cadastro Admin; mapear com `internal_specialization_id` da TC (🟡 `04-integration-teleconsulta.md`) |
| escala.dias | lista (dias da semana) | cadastro Admin |
| escala.horario_inicio / fim | hora | cadastro Admin |
| escala.consultas_por_hora | inteiro | cadastro Admin (param edital ≈ 3/hora, `05-processo-manual-excel.md` §5) |
| escala.periodo_inicio / fim | data | "período válido de prestação de serviço" (`01-domain-overview.md`) |
| escala.ativo | booleano | cadastro Admin |
| estoque_calculado | inteiro (derivado) | **calculado** dias×horário×consultas/hora×período (D-005) |
| ajuste_manual (retornos/extras) | inteiro + nota | manual com auditoria (D-005) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** lista de médicos + detalhe/escala.
- **Vazio:** `.empty-state` — "Nenhum médico cadastrado ainda" + "Novo médico".
- **Loading:** `.skeleton` na tabela; spinner no `.btn--loading`; banner de estoque em skeleton enquanto recalcula.
- **Erro:** erro de formulário (horário fim ≤ início, consultas/hora ≤ 0, período inválido) com
  borda `--color-danger`; `.error-state` 403/500.
- **Sucesso:** `.toast` "Médico salvo" + banner de estoque atualizado.

## 5. Comportamento responsivo (D-015)
- **≥ lg:** lista (esquerda) + formulário/detalhe (direita).
- **md–lg:** `.sidebar` em rail; 1 coluna; banner de estoque full width.
- **< md:** top app bar + `.drawer`; tabela → cards; formulário 1 coluna; inputs time/number com
  `font-size:16px`; chips de dia em wrap com alvos ≥44px.

## 6. Regras de negócio
- **D-005** — Estoque **misto**: base **calculada** da escala (dias × horário × consultas/hora ×
  período) + **ajuste manual** ("retornos/extras") com auditoria.
- **D-010** — Doutor é **dado**, não usuário (não loga); é cadastrado por operador Admin/Demandas.
- **D-008** — Cadastro de médico/escala é do **Admin/Demandas**.
- A escala alimenta ① Oferta → estoque consumido pela Disponibilização (`01-domain-overview.md`).

## 7. Critérios de aceite (EARS)
- QUANDO o operador preenche dias, horário, consultas/hora e período válidos, O SISTEMA DEVE exibir o estoque calculado (≈ N vagas) no banner antes de salvar (D-005).
- QUANDO o horário de fim é menor ou igual ao de início, O SISTEMA DEVE bloquear o salvamento e exibir erro no campo de horário.
- QUANDO o operador aplica um ajuste manual de retornos/extras, O SISTEMA DEVE registrar a alteração com trilha de auditoria (D-005).
- QUANDO não há médicos cadastrados, O SISTEMA DEVE exibir o estado vazio com a ação "Novo médico".
- QUANDO o médico é salvo com sucesso, O SISTEMA DEVE exibir um toast e atualizar o estoque calculado na lista.
- QUANDO um usuário sem papel Admin acessa esta tela, O SISTEMA DEVE responder com o estado de erro 403 (D-008).

## 8. Perguntas abertas
- 🟡 **Fórmula exata** de capacidade não confirmada: tratar intervalos (almoço), duração fixa de
  consulta, feriados (`03-open-questions.md`).
- 🟡 **Granularidade do estoque**: vaga = contagem de capacidade OU horário concreto? (`03-open-questions.md`).
- 🟡 Trilha de auditoria do ajuste manual: quem pode, o que se registra (LGPD) (D-005, `03-open-questions.md`).
- 🟡 Mapeamento de especialidades com a TC (texto / `internal_specialization_id`).
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
