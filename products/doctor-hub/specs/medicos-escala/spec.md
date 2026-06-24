---
id: SPEC-MEDICOS-ESCALA
title: Médicos & Escala (cadastro do médico + escalas FIXA/FLEX + estoque)
status: specified        # draft | specified | tested | implemented
owner: Alessandro
area: Oferta
clickup: ""
figma: "snTNGRUJO2GwoKpXTHCBjf"   # frame "Escala" (id 2:2)
validated_by: "Alessandro"
validated_at: "2026-06-24"
last_update: 2026-06-24
---

# Médicos & Escala

> **1ª entrega (D-052)** — Fase 1: **cadastro do médico + escalas**. Etapa ① **Oferta** do pipeline
> ([`../../docs/discovery/01-domain-overview.md`](../../docs/discovery/01-domain-overview.md)).
> Handoff de UI: [`./ui.md`](./ui.md). Modelo de domínio: [`../../docs/architecture/01-domain-model.md`](../../docs/architecture/01-domain-model.md).
>
> **v2 (2026-06-24)** — expandido para **multi-escala FIXA/FLEX** (D-120..D-123), validado por Alessandro.
> Substitui o modelo de "uma escala fixa por médico". A escala efetiva do médico = **FIXA + Σ FLEX**.

## 1. Problema / Dor  _(Definition of Success)_

- **Dor:** a capacidade do médico só é vista **por consequência** ("Sem médico / horário ocupado"
  aparece depois que o slot estourou — `05-processo-manual-excel.md` §6; 712 casos "Sem médico").
- **De quem:** **Admin/Demandas** (operador que cadastra a oferta).
- **Sucesso = quando:** ao cadastrar **médico + escalas**, o sistema mostra a **capacidade consolidada
  ANTES** (estoque de vagas por especialidade/período) e alimenta a Disponibilização (③). A escala dá a
  **visão estratégica da nossa capacidade**; a produtividade real é medida depois pelos atendimentos.

## 2. Modelo de domínio

- **Médico** (DADO, não usuário — D-010): nome, CRM, **especialidades** (1..N que ele é habilitado a
  atender, ex.: Clínica geral + Cardiologia), status ativo/inativo.
- **Escala** (0..N por médico): pertence a **uma especialidade do médico**, tem **tipo FIXA ou FLEX**,
  **dias** da semana, **1..N blocos de horário** no dia, **consultas/hora** (≡ minutos/atendimento) e
  **vigência**. A escala é a unidade de oferta.
- **Escala efetiva do médico = FIXA + Σ FLEX** — a soma é a oferta real (precisa da **visão consolidada**).

### Cardinalidade (D-120)
No máximo **1 FIXA ativa** por médico numa data + **0..N FLEX**. Combinações válidas:
`1 fixa` (ideal) · `1 fixa + N flex` · `0 fixa + N flex` · `0 fixa + 1 flex` (médico temporário).

## 3. Tipos de escala (D-120/D-121)

| | **FIXA** | **FLEX** |
|---|---|---|
| Significado | Contrato **CLT** — a oferta permanente do médico | Capacidade **temporária**: hora extra, plantão, cobrir gap de contratação ou falta de um doutor |
| Vigência | **data início**, **sem data de fim** (permanente) | **período com início e fim** (curto/concreto) |
| Granularidade | por **dia** (data) | por **hora** (data+hora — ex.: "4h hoje à noite, 19–23h") |
| Imutável? | **Sim** — não se edita; para alterar, **encerra a atual** (põe data-fim) e **cria uma nova** (effective-dating) | Pode criar/excluir conforme regras §6 |
| Estoque | conta de forma contínua | conta **só dentro da vigência** (soma à fixa — D-122) |

> Médico **temporário** = só FLEX (sem fixa), com período de quando inicia/termina.

### Troca de FIXA (effective-dating — D-121)
A FIXA não é editada; cria-se uma nova:
- **Default:** a atual recebe **data-fim = hoje**; a nova **início = amanhã** (D+1) — sem gap, sem overlap.
- **Editável:** pode-se programar a troca para o **futuro** (ex.: encerrar a fixa na próxima semana e a nova
  iniciar logo após), e **pode haver intervalo** (uma semana, um mês) entre as escalas.
- **Invariante:** a nova FIXA **nunca retroage** — início **≥ amanhã**.

## 4. Invariantes  _(núcleo crítico à mão — cercar de teste)_

- **INV-1 (sem sobreposição, D-121):** nenhum par de escalas do **mesmo médico** ocupa o **mesmo slot**
  (dia + faixa de horário) quando suas **vigências se cruzam** — vale **entre quaisquer escalas** (fixa×flex,
  flex×flex, **inclusive de especialidades diferentes**: o médico não está em dois lugares ao mesmo tempo).
  - Ex.: fixa Seg–Sex 08–18 ⇒ FLEX só cabe **fim de semana ou após as 18h**.
  - Duas FLEX "Ter 21–23h" em **datas diferentes** (dia 01 e dia 07) **não** conflitam.
  - O médico pode ser **Clínica geral no sábado** e **Cardiologista no domingo** — desde que não haja
    cardio **e** clínica no **mesmo slot**.
- **INV-2 (1 fixa ativa):** vigências de FIXA do médico não se sobrepõem.
- **INV-3 (não-retroação da FIXA):** nova FIXA início ≥ amanhã.
- **INV-4 (blocos):** dentro de uma escala, os blocos não se sobrepõem e cada bloco tem fim > início.
- **INV-5 (especialidade):** `escala.especialidade ∈ medico.especialidades`.
- **INV-6 (vigência):** fim ≥ início (FLEX por hora; FIXA por data, fim opcional).

## 5. Cálculo de estoque (estende D-005/D-111/D-112)

Granularidade = **CONTAGEM inteira** (D-111). Base pura, sem descontar almoço/feriado (D-112).

```
estoque(médico, especialidade, período) =
  Σ  [ escalas vigentes dessa especialidade no período ]
       Σ [ blocos ] ( horas_do_bloco × consultas_por_hora )  ×  dias_válidos( dias ∩ período ∩ vigência )
```
- **FLEX conta só dentro da sua vigência**; FIXA conta de forma contínua no período.
- **Estoque efetivo do médico** = soma sobre especialidades.
- **Sem limite de horas/dia** por doutor nesta entrega (🟡 revisitar — alguns fazem almoço, outros não).

## 6. Operações (criar / editar / excluir) — D-122/D-123

- **Criar FIXA:** se já há FIXA ativa, encerra a atual (§3 effective-dating) e cria a nova.
- **Criar FLEX:** a qualquer momento (início ≥ próxima hora), respeitando **INV-1** (sem-overlap).
- **Excluir escala:**
  - se o **início está no FUTURO** (ainda não começou) → **exclui direto**.
  - se a escala **já iniciou** → **exige senha de gestão** (botão "Excluir" com ícone de **cadeado** →
    modal pede a senha → senha correta libera a exclusão). _Ex.: criei uma FLEX para daqui 1h, o doutor
    não apareceu, já passaram 2h → preciso excluir a escala criada mas não usada._
- **Senha de gestão (D-123):** funcionalidade do perfil **Demandas Médicas** (não é admin) para
  exclusões/alterações sensíveis. **Senha FIXA por enquanto** (constante de protótipo; auth real depois).
- **Auditoria (D-123):** **toda** operação é auditável — **quem** fez **o quê**, **com quem** (médico/escala) e
  **quando** — **principalmente** quando a senha de gestão é solicitada (registra quem informou e o resultado).

## 7. UX  _(detalhe em [`./ui.md`](./ui.md))_

A escala vive **dentro do cadastro/perfil do médico** (menos telas). Perfil = dados do médico +
**Escalas** (cards FIXA/FLEX por especialidade, com vigência/dias/blocos) + **visão consolidada** (semana
efetiva = fixa+flex) + ações criar/excluir. **Responsivo, didático** (explica FIXA×FLEX inline) e **elegante**.

## 8. Regras confirmadas  _(D-xxx no decisions-log)_

- ✅ **D-010** Doutor é DADO, não usuário. · ✅ **D-008** cadastro é do papel Admin/Demandas.
- ✅ **D-005** estoque misto (base calculada + ajuste manual auditado). · ✅ **D-111** contagem · ✅ **D-112** base pura.
- ✅ **D-120** escala multi-tipo: **1 FIXA + N FLEX**; efetiva = fixa+flex.
- ✅ **D-121** FIXA permanente/imutável via **effective-dating** (encerra+nova ≥ amanhã); **sem-overlap** cross-especialidade.
- ✅ **D-122** FLEX por hora soma capacidade na sua vigência; granularidades (fixa=dia, flex=hora); 1..N blocos/dia.
- ✅ **D-123** excluir: livre se futura, **senha de gestão** (fixa, perfil Demandas) se já iniciada; **tudo auditável**.

## 9. Critérios de aceite  _(Gherkin — fonte do teste; TDD)_

```gherkin
Cenário: escala efetiva é a soma de fixa + flex (D-120)
  Dado um médico com 1 escala FIXA e 1 escala FLEX vigentes no período
  Quando o operador vê a capacidade do médico
  Então a visão consolidada mostra a soma das vagas (fixa + flex)

Cenário: sem sobreposição entre escalas do mesmo médico (INV-1)
  Dado um médico com FIXA Seg–Sex 08:00–18:00
  Quando o operador tenta criar uma FLEX em Ter 14:00–16:00 (vigência cruzando)
  Então o sistema bloqueia por conflito de horário
  E permite a mesma FLEX no sábado ou após as 18:00

Cenário: duas FLEX no mesmo horário em datas diferentes não conflitam (INV-1)
  Dado uma FLEX em Ter 21:00–23:00 no dia 01
  Quando o operador cria outra FLEX em Ter 21:00–23:00 no dia 07
  Então o sistema permite (vigências não se cruzam)

Cenário: trocar a FIXA via effective-dating (D-121)
  Dado um médico com uma FIXA ativa sem data de fim
  Quando o operador cria uma nova FIXA
  Então a FIXA atual recebe data-fim (default hoje) e a nova inicia em data ≥ amanhã (default amanhã)
  E o operador pode programar a troca para o futuro, com ou sem intervalo entre elas

Cenário: nova FIXA não retroage (INV-3)
  Quando o operador define o início da nova FIXA para hoje ou no passado
  Então o sistema bloqueia (início deve ser ≥ amanhã)

Cenário: especialidade da escala deve ser do médico (INV-5)
  Quando o operador cria uma escala para uma especialidade que o médico não atende
  Então o sistema não permite

Cenário: validação de horário/bloco (INV-4)
  Quando um bloco tem fim ≤ início (ou blocos se sobrepõem na mesma escala)
  Então o sistema bloqueia o salvamento e exibe erro no campo

Cenário: excluir escala futura é livre (D-123)
  Dado uma escala cujo início está no futuro
  Quando o operador exclui
  Então o sistema exclui sem pedir senha

Cenário: excluir escala já iniciada exige senha de gestão e é auditado (D-123)
  Dado uma FLEX que já começou (início no passado)
  Quando o operador clica em "Excluir" (ícone de cadeado)
  Então o sistema abre um modal pedindo a senha de gestão
  E só exclui se a senha estiver correta
  E registra na auditoria quem solicitou, o resultado e quando

Cenário: cálculo do estoque multi-escala/bloco (D-111/D-112/D-122)
  Dado uma FIXA Ter/Qui com blocos 08:00–12:00 e 13:00–17:00 (8h), 3 consultas/hora
  Quando o operador vê o estoque da semana
  Então o sistema calcula 8h × 3/h × (nº de Ter/Qui no período) como contagem inteira
  E soma a capacidade das FLEX vigentes no período
```

## 10. Fora de escopo / perguntas abertas

- 🟡 **Limite de horas/dia por doutor** — não há nesta entrega (revisitar).
- 🟡 **Mapeamento de especialidade com a TC** (`internal_specialization_id`).
- 🟡 **Convivência cadastro × sync RO** do médico (D-052).
- 🟢 **Linha do tempo** (histórico de vigências) e **Arquivar** — placeholders por ora.
- Disponibilização/Remanejamento/dashboards — specs próprias (consomem este estoque).
