---
id: SPEC-MEDICOS-ESCALA
title: Médicos & Escala (cadastro-dono do médico + escala fixa + estoque)
status: draft            # draft | specified | tested | implemented
owner: Alessandro
area: Oferta
clickup: ""
figma: "snTNGRUJO2GwoKpXTHCBjf"   # frame "Médicos & Escala"
validated_by: ""
validated_at: ""
last_update: 2026-06-23
---

# Médicos & Escala

> **1ª entrega (D-052)** — Fase 1 do roadmap da diretoria: **escala médica + cadastro-dono do médico**.
> Etapa ① **Oferta** do pipeline ([`../../docs/discovery/01-domain-overview.md`](../../docs/discovery/01-domain-overview.md)).
> Recorte de UI (handoff de tela): [`./ui.md`](./ui.md). Modelo de domínio do contexto ② Médico+Escala+Estoque:
> [`../../docs/architecture/01-domain-model.md`](../../docs/architecture/01-domain-model.md).
>
> **Status `draft` por decisão de método:** há perguntas 🔴 abertas (§8) que **bloqueiam** o
> `specified`. Não inferimos a fórmula de capacidade nem a granularidade do estoque — perguntamos.

## 1. Problema / Dor  _(Definition of Success)_

- **Dor:** hoje a **capacidade do médico só é vista por consequência** — "Sem médico / horário
  ocupado" aparece **depois** que o slot estourou ([`05-processo-manual-excel.md`](../../docs/discovery/05-processo-manual-excel.md) §6, dor 2; Substatus "Sem médico" = 712 casos na planilha). Não há visão prévia de oferta por especialidade-horário.
- **De quem:** **Admin/Demandas** (operador que cadastra a oferta).
- **Evidência:** achado da planilha + D-005 (estoque misto) + D-052 (1ª entrega = escala + cadastro do médico).
- **Sucesso = quando:** ao cadastrar **médico + escala fixa**, o sistema **calcula o estoque de vagas
  ANTES** (não a posteriori), e esse estoque alimenta a Disponibilização (etapa ③).

## 2. Função  _(o "o quê")_

Permitir ao operador Admin/Demandas:
1. **Cadastrar/editar um médico** (dado, não usuário — D-010): nome, especialidade, ativo/inativo.
2. **Definir a escala fixa** do médico: dias de atendimento, horário (início/fim), consultas por hora,
   período válido de prestação (date range), ativo/inativo.
3. **Ver o estoque de vagas calculado** a partir da escala, **antes de salvar** (banner "≈ N vagas no período").
4. **Aplicar ajuste manual** ("retornos/extras") sobre o estoque, **com trilha de auditoria**.
5. **Listar** médicos com especialidade, status e vagas calculadas.

## 3. Regras de negócio  _(somente CONFIRMADAS — `D-xxx` no decisions-log)_

- ✅ **D-010** — O **Doutor é DADO, não usuário** (não loga); é cadastrado por operador Admin/Demandas.
- ✅ **D-008** — O **cadastro de médico/escala é do papel Admin/Demandas** (RBAC).
- ✅ **D-005** — O **estoque é MISTO**: uma **base calculada** a partir da escala (dias × horário ×
  consultas/hora × período) **+ ajuste manual** ("retornos/extras"), e o ajuste manual é **auditado**.

> ⚠️ A **fórmula exata** de derivação da base calculada e a **granularidade** do estoque **NÃO** estão
> confirmadas — ver §8 (🔴). Por isso esta spec permanece `draft`.

## 4. Critérios de aceite  _(Gherkin — fonte do teste; TDD)_

> Cenários abaixo cobrem o que **independe** das perguntas 🔴. Os cenários de **cálculo de estoque**
> ficam pendentes da confirmação da fórmula/granularidade (§8) e estão marcados como ⛔ PENDENTE.

```gherkin
Cenário: cadastrar médico exige papel Admin/Demandas (D-008)
  Dado um usuário SEM o papel Admin/Demandas
  Quando ele acessa a tela Médicos & Escala
  Então o sistema responde com erro de autorização (403) e não exibe o cadastro

Cenário: validação de horário da escala
  Dado o formulário de escala
  Quando o horário de fim é menor ou igual ao horário de início
  Então o sistema bloqueia o salvamento e exibe erro no campo de horário

Cenário: validação de consultas por hora
  Dado o formulário de escala
  Quando "consultas por hora" é menor ou igual a zero
  Então o sistema bloqueia o salvamento e exibe erro no campo

Cenário: validação de período
  Dado o formulário de escala
  Quando a data de fim do período é anterior à data de início
  Então o sistema bloqueia o salvamento e exibe erro no campo de período

Cenário: estado vazio
  Dado que não há nenhum médico cadastrado
  Quando o operador abre a tela Médicos & Escala
  Então o sistema exibe o estado vazio com a ação "Novo médico"

Cenário: ajuste manual é auditado (D-005)
  Dado um médico com estoque calculado
  Quando o operador aplica um ajuste manual de retornos/extras
  Então o sistema registra a alteração com trilha de auditoria (quem, quando, valor anterior/novo)

Cenário: salvar com sucesso
  Dado um médico e escala válidos
  Quando o operador salva
  Então o sistema confirma (toast) e o médico aparece na lista com seu status

# ⛔ PENDENTE (bloqueado por §8 🔴 — fórmula/granularidade):
Cenário: cálculo do estoque antes de salvar (D-005)
  Dado dias, horário, consultas/hora e período válidos
  Quando o operador preenche a escala
  Então o sistema exibe o estoque calculado ("≈ N vagas") no banner ANTES de salvar
  # N depende da fórmula confirmada (§8 🔴-1) e da granularidade (§8 🔴-2)
```

## 5. Definition of Done

- [ ] Todos os cenários **não-PENDENTE** da §4 passam como teste automatizado (xUnit na api, Vitest na web).
- [ ] Fórmula/granularidade confirmadas (§8 🔴 resolvidos) → cenário de cálculo de estoque vira teste e passa.
- [ ] Sem perguntas 🔴 pendentes.
- [ ] `validated_by` preenchido (humano valida → `specified`).
- [ ] Invariantes de estoque (D-005) cercadas de teste — **núcleo crítico à mão** (escrito/revisado por humano).

## 6. Fora de escopo  _(desta spec)_

- Disponibilização (simular/reservar/emitir) — consome este estoque, mas é a SPEC `disponibilizacao`.
- Remanejamento, dashboards, cobertura/PDF.
- Sync do médico vindo da TC (RO) — entra como **dependência**, não como cadastro desta tela (ver §7).
- Granularidade "horário concreto" caso a decisão (🔴-2) seja "contagem" — e vice-versa.

## 7. Dependências & Integrações

- **Especialidade ↔ Teleconsulta:** mapear especialidade com `internal_specialization_id` da TC
  (🟡 [`04-integration-teleconsulta.md`](../../docs/discovery/04-integration-teleconsulta.md)).
- **Médico via sync RO (D-052):** a 1ª entrega roda sobre **dados reais** (médicos via sync read-only).
  O cadastro desta tela e o sync precisam de uma regra de convivência (🟡 §8).
- **Estoque → Disponibilização (③):** o estoque calculado é o insumo da etapa de Alocação.

## 8. Perguntas abertas  _(NÃO INFERIR — bloqueiam `specified` enquanto 🔴)_

- 🔴 **(1) Fórmula exata da base calculada.** `(horas no dia × consultas/hora) × dias válidos no
  período`? Como tratar **intervalo (almoço)**, **duração fixa de consulta**, **feriados**? Parâmetros
  do edital (≈ **3 consultas/hora**, plantão mín. 4h) são **referência, não regra confirmada**
  ([`05-processo-manual-excel.md`](../../docs/discovery/05-processo-manual-excel.md) §5).
- 🔴 **(2) Granularidade do estoque.** Vaga = **contagem de capacidade** (um inteiro) OU **horário
  concreto** (slots datados)? O `03-open-questions.md` **sugere** começar como contagem — mas é
  sugestão, não confirmação. Define o modelo de dados.
- 🟡 **(3) Trilha de auditoria do ajuste manual:** quem pode ajustar, o que se registra, retenção (LGPD).
- 🟡 **(4) Convivência cadastro × sync RO:** o médico vem da TC (RO); o que esta tela cria/edita vs. o
  que é espelhado? Conflito de fonte da verdade.
- 🟡 **(5) Especialidade:** texto livre ou referência ao `internal_specialization_id` da TC?
- 🟢 **(6)** Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit Figma `24:2`).
