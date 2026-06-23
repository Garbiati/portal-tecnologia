---
id: UI-ASSUNCAO
title: Assunção de Vagas
status: draft
area: Assunção / Agendamento → Teleconsulta
last_update: 2026-06-14
---

# UI-spec — Assunção de Vagas

> Etapas ④ Assunção + ⑤ Agendamento do pipeline (`01-domain-overview.md`). Tela Figma de fluxo:
> **Assunção de Vagas** (`docs/design/figma-prototipo.md`), papel **Gestor · <cidade>**.
> ⚠️ **Caso mobile prioritário** (D-015 / §7 design-system: Gestor é o caso mais provável de mobile).

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** hoje não há ponto em que o gestor local efetive a vaga e amarre paciente + médico
  preferencial; "Sem médico" e a associação de paciente ficam implícitos no hub/Excel
  (`05-processo-manual-excel.md`; `01-domain-overview.md` ⑤).
- **De quem:** **Gestor local de unidade/HC** (~1 por cidade, D-008).
- **Evidência:** D-009 (paciente associado ao assumir), D-011, D-012.
- **Sucesso = quando:** o Gestor assume os slots emitidos para sua unidade, **seleciona o paciente**
  (lista vinda da TC por HC) e **define o doutor preferencial**, gerando o agendamento que vai à
  Teleconsulta.

## 2. Layout
**Shell:** `.sidebar` (nav "Assunção" `.nav-item--active`) + `.topbar` (**Gestor · <cidade>**).
No mobile: top app bar + hamburger/`.drawer`.

Seções:
1. **Cabeçalho** — título + filtro de período/especialidade (`.chip` / `.select`).
2. **Lista de vagas emitidas** (`.table` no desktop / **cards empilhados** no mobile) — para a
   unidade do Gestor: Especialidade · Data/janela · Status (`.badge`: emitida / assumida) ·
   ação `.btn--primary` ("Assumir").
3. **Painel "Assumir vaga"** (`.drawer` no desktop, **bottom-sheet** no mobile):
   - **Selecionar paciente** (`.select`/search com `.input`) — lista vinda da **TC por HC** (D-012).
   - **Doutor preferencial** (`.select`) — em retorno, pré-preenchido com o último doutor (D-011);
     senão o Gestor escolhe. Nota: pode haver fallback de especialidade na TC.
   - Resumo do agendamento (médico + paciente + especialidade + HC) + `.btn--primary` ("Confirmar assunção").

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| vaga.especialidade | texto/ref | vaga emitida na Disponibilização (③) |
| vaga.janela (data/hora) | datetime/intervalo | Disponibilização / agendamento |
| vaga.hc_id | ref | unidade do Gestor (escopo, D-008) |
| paciente | ref (`patient_id` TC) | **lista vem da Teleconsulta por health center** (D-012); `patient_id` já resolvido |
| doutor_preferencial | ref (`preference_of_doctor_id`) | retorno = último doutor (D-011); senão escolha do Gestor |
| agendamento | composto | médico + paciente + especialidade + HC → enviado à TC (`POST /integration/appointment`, `04-integration-teleconsulta.md`) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** lista de vagas emitidas da unidade.
- **Vazio:** `.empty-state` — "Nenhuma vaga emitida para sua unidade ainda" (texto-exemplo do §6 design-system).
- **Loading:** `.skeleton` na lista; spinner no `.btn--loading` ao confirmar; carregamento da lista
  de pacientes da TC com skeleton/spinner.
- **Erro:** `.error-state` 403/500; erro ao confirmar (paciente não selecionado; preferencial
  indisponível → mensagem de fallback de especialidade, D-011); falha na inserção na TC (retry seguro
  por `external_id` UNIQUE — `04-integration-teleconsulta.md`).
- **Sucesso:** `.toast` "Vaga assumida / agendamento enviado à Teleconsulta".

## 5. Comportamento responsivo (D-015 — Gestor é o caso mobile prioritário)
- **≥ lg:** lista (esquerda) + painel de assunção em `.drawer` (direita).
- **md–lg:** `.sidebar` em rail; 1 coluna.
- **< md (mobile — jornada priorizada):** top app bar + `.drawer`; **vagas em cards empilhados**;
  ação "Assumir" abre **bottom-sheet**; `.select` de paciente e doutor com `font-size:16px` e alvos
  ≥44px; nada de hover-only.

## 6. Regras de negócio
- **D-008** — Quem assume é o **Gestor local** (escopo da sua unidade/HC). Só Gestor faz login aqui.
- **D-009** — O **paciente é associado à vaga NO MOMENTO em que o Gestor assume** (ele seleciona ali).
- **D-012** — A **lista de pacientes vem da Teleconsulta** (endpoint por health center); o
  `patient_id` da TC já vem resolvido (reduz exposição LGPD).
- **D-011** — **Médico preferencial:** em retorno, o último doutor vira preferencial; senão o Gestor
  escolhe. O preferencial pode estar indisponível → atendimento por **outro doutor da mesma
  especialidade** (fallback).
- **D-003** — alocação é nossa: enviamos `preference_of_doctor_id`; a TC respeita.
- **D-010** — Doutor e paciente são **dados**, não usuários.
- Agendamento final vai à TC via `POST /integration/appointment` (idempotente por `external_id`,
  `04-integration-teleconsulta.md`).

## 7. Critérios de aceite (EARS)
- QUANDO o Gestor abre a tela, O SISTEMA DEVE listar apenas as vagas emitidas para a sua unidade (D-008).
- QUANDO o Gestor aciona "Assumir" em uma vaga, O SISTEMA DEVE abrir o painel de seleção de paciente e doutor preferencial.
- QUANDO o Gestor abre a seleção de paciente, O SISTEMA DEVE carregar a lista de pacientes da Teleconsulta para aquele health center (D-012).
- QUANDO a vaga é um retorno, O SISTEMA DEVE pré-preencher o doutor preferencial com o último doutor que atendeu (D-011).
- QUANDO o doutor preferencial está indisponível, O SISTEMA DEVE permitir atendimento por outro doutor da mesma especialidade (fallback, D-011).
- QUANDO o Gestor tenta confirmar sem selecionar paciente, O SISTEMA DEVE bloquear a confirmação e exibir erro.
- QUANDO a assunção é confirmada, O SISTEMA DEVE montar o agendamento (médico + paciente + especialidade + HC) e enviá-lo à Teleconsulta (D-009, `04-integration-teleconsulta.md`).
- QUANDO não há vagas emitidas para a unidade, O SISTEMA DEVE exibir o estado vazio.
- QUANDO o envio à Teleconsulta conclui, O SISTEMA DEVE exibir um toast de sucesso.

## 8. Perguntas abertas
- 🟡 **Origem/escopo exato da lista de pacientes** do Gestor ao assumir (D-012 diz "por health
  center"; endpoint exato a localizar no repo da TC — `03-open-questions.md`).
- 🟡 Como o sistema decide que uma vaga é "retorno" (para pré-preencher o último doutor, D-011).
- 🟡 Resolução de `patient_id` quando o paciente não existe na TC (criar? bloquear?) — `04-integration-teleconsulta.md`.
- 🟡 Mensagem/UX do fallback de especialidade quando o preferencial dá 409 na TC.
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
