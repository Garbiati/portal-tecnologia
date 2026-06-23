---
id: SPEC-MEDICOS-ESCALA
title: Médicos & Escala (cadastro-dono do médico + escala fixa + estoque)
status: specified        # draft | specified | tested | implemented
owner: Alessandro
area: Oferta
clickup: ""
figma: "snTNGRUJO2GwoKpXTHCBjf"   # frame "Médicos & Escala"
validated_by: "Alessandro"
validated_at: "2026-06-23"
last_update: 2026-06-23
---

# Médicos & Escala

> **1ª entrega (D-052)** — Fase 1 do roadmap da diretoria: **escala médica + cadastro-dono do médico**.
> Etapa ① **Oferta** do pipeline ([`../../docs/discovery/01-domain-overview.md`](../../docs/discovery/01-domain-overview.md)).
> Recorte de UI (handoff de tela): [`./ui.md`](./ui.md). Modelo de domínio do contexto ② Médico+Escala+Estoque:
> [`../../docs/architecture/01-domain-model.md`](../../docs/architecture/01-domain-model.md).
>
> **Status `specified`** (validado por Alessandro em 2026-06-23): os 2 bloqueadores 🔴 foram
> confirmados — granularidade = **contagem** (D-111) e fórmula = **base pura** (D-112). Restam só
> 🟡 (não bloqueiam). Próximo passo: **TDD** (cenários §4 → testes → código).

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
- ✅ **D-005** — O **estoque é MISTO**: uma **base calculada** a partir da escala **+ ajuste manual**
  ("retornos/extras"), e o ajuste manual é **auditado**.
- ✅ **D-111** — **Granularidade = CONTAGEM (inteiro).** A vaga é uma contagem de capacidade por
  médico/especialidade/período — não horário concreto. — _Confirmado por Alessandro em 2026-06-23._
- ✅ **D-112** — **Fórmula = BASE PURA:** `estoque_base = (horário_fim − horário_início)[h] ×
  consultas_por_hora × dias_válidos_no_período`, sem descontar almoço/feriados. `dias_válidos` = nº de
  ocorrências dos dias da escala dentro de `[período_início, período_fim]`. — _Confirmado por Alessandro em 2026-06-23._
- ✅ **estoque_total = estoque_base + ajuste_manual** (D-005 + D-112).

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

Cenário: cálculo do estoque base antes de salvar (D-005, D-111, D-112)
  Dado uma escala com horário 08:00–12:00 (4h), 3 consultas por hora
    E os dias seg, qua, sex
    E o período de 01/07/2026 a 31/07/2026 (13 ocorrências desses dias)
  Quando o operador preenche a escala
  Então o sistema exibe o estoque base calculado de 156 vagas no banner ANTES de salvar
  # 4h × 3/h × 13 dias = 156 (contagem inteira — D-111/D-112)

Cenário: estoque total soma o ajuste manual (D-005)
  Dado um estoque base de 156 vagas
  Quando o operador aplica um ajuste manual de +10 (retornos/extras)
  Então o estoque total exibido é 166 vagas
    E o ajuste é registrado com trilha de auditoria
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

## 8. Perguntas abertas  _(NÃO INFERIR — perguntar)_

> ✅ **Resolvidas (desbloquearam o `specified`):** fórmula da base calculada → **D-112** (base pura);
> granularidade do estoque → **D-111** (contagem). Restam só 🟡, que **não bloqueiam** esta entrega.

- 🟡 **(3) Trilha de auditoria do ajuste manual:** quem pode ajustar, o que se registra, retenção (LGPD).
- 🟡 **(4) Convivência cadastro × sync RO:** o médico vem da TC (RO); o que esta tela cria/edita vs. o
  que é espelhado? Conflito de fonte da verdade. _(Escopo desta spec assume o médico existente; ver §6/§7.)_
- 🟡 **(5) Especialidade:** texto livre ou referência ao `internal_specialization_id` da TC?
- 🟢 **(6)** Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit Figma `24:2`).
