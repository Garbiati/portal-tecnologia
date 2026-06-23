---
title: Arquitetura da Escala Médica (capacidade, timeline, rastreabilidade, produtividade)
status: draft
date: 2026-06-14
fonte: feedback do Alessandro (2026-06-14) sobre a tela Médicos & Escala
---

# Arquitetura da Escala (o que a tela atual NÃO mostra, mas o modelo PRECISA suportar)

> A tela atual (cadastro livre + 1 escala simples) está rasa. O modelo precisa ser robusto desde já —
> mesmo que a UI da Entrega 1 mostre só o básico — para **vender as entregas futuras** (rastreabilidade
> e produtividade médica). Regras abaixo são do Alessandro; o que falta confirmar está marcado 🔴/🟡.

## 1. Médico NÃO é cadastro livre — vem da Teleconsulta
- O fluxo correto: **buscar o profissional existente** (na base da Teleconsulta) → selecionar → **criar a escala**.
- ✅ **Endpoint CONFIRMADO no código da TC** (explore 2026-06-14): **`GET /integration/doctor?search=<nome>&specialityId=<int>&offset=&limit=`**,
  auth `X-API-KEY` (`[PartnerApiKey(PartnerType.SOSPortal)]` — precisaremos de **novo PartnerType + key**).
  Retorna `Array<DoctorShortDto>`. Entidade `DoctorProfile`: CPF, `Specialization` (enum DoctorSpecializationType 0..32),
  Licenses (CRM/RQE por estado), Tags→CNES, HealthCenters (M:N, com Status). Arquivos: `IntegrationController.Doctor.cs:20`,
  `DoctorShortDto.cs`, `DoctorProfile.cs`.
- ⚠️ **Dois problemas práticos (dependência da equipe TC):**
  1. O DTO público hoje volta **incompleto** (só `DoctorId, FirstName, LastName, HealthCenterId`); **CPF/CRM/RQE/CNS/especialidade voltam null** (bug/incompletude no SELECT). Há um método admin completo (`AdminGetDoctorFilterAsync`), mas não exposto na integração.
  2. **Não existe** busca por chave única (`/integration/doctor/idbycpf` ou `/bycrm`) — só por nome+especialidade+paginação.
  → Para a Entrega futura que usa isso, **pedir à TC**: expandir o DTO e/ou criar lookup por CPF/CRM. Na Entrega 1 (base), a tela mostra a busca; os dados completos dependem desse ajuste.

## 1b. 🚨 A Teleconsulta JÁ TEM um modelo de escala (decisão de fronteira)
- O explore achou no código da TC: **`ScheduleGroup`** (template de escala, `TemplateName`, `EffectiveFrom`, vínculo
  `HealthCenterDoctorProfileId`) + **`AvailabilityRule`** (tipo semanal/diário, `StartingFrom`, `WorkingHours` início/fim/intervalo,
  `Days[]`) + consulta de slots livres (`AdminGetDoctorAvailabilityAsync`). **NÃO é exposto via integração** (a TC gere internamente).
- ⇒ Isso **sobrepõe** a nossa "Médicos & Escala". ✅ **DECISÃO D-026 (Alessandro, 2026-06-14): a escala é NOSSA/própria.**
  Gerimos a escala no novo sistema (ela gera o estoque); da TC só **buscamos o profissional** (`GET /integration/doctor`).
  Não lemos/escrevemos a ScheduleGroup/AvailabilityRule da TC. Aceita-se a duplicação do conceito. A Médicos & Escala v2 está correta.

## 2. Escala = disponibilidade recorrente, com PRESETS
- A escala é fixa/recorrente. Deve ter **modelos/presets**: **meio período**, **período integral**, **madrugada**,
  e **personalizado** (o operador define o range). Presets aceleram o cadastro.
- Campos por bloco: dias da semana, hora início, hora fim, consultas/hora.

## 3. Um médico tem VÁRIAS escalas — que NUNCA se sobrepõem
- Um médico pode ter **múltiplos blocos/escalas**; o sistema **deve impedir sobreposição de horário** (validação).
- Exemplos (do Alessandro):
  - **Dr. A:** 08–12 e 13–17.
  - **Dr. B:** 08–11 e 12–17.
  - **Dr. C:** 08–11 e 12–17 **+ uma 2ª escala 22:00 → 02:00 do dia seguinte** (vira a meia-noite).
- ⇒ O modelo trata **blocos de horário** (que podem cruzar a meia-noite) e valida overlap entre todos os blocos
  ativos do médico.

## 4. Vigência e estados — uma TIMELINE, não um registro estático
- Escala pode ter **ou não** data de fim. A ideia é estar **sempre atualizada**: **ativar / inativar**, **total ou
  parcialmente** (um bloco específico, um dia, um período).
- Sabe-se a data de **início**, mas pode haver **várias datas início/fim** ao longo do tempo (timeline de vigências).
- As **horas também mudam** ao longo do tempo.
- ⇒ Modelar como **versões/vigências** (efetivo de–até) por bloco, com estado (ativa/inativa), preservando histórico.

## 5. Rastreabilidade da escala (feature a mostrar)
- Precisamos de **relatório/log/timeline** do médico: toda mudança de escala (quem alterou, quando, o quê,
  ativou/inativou, mudou horário/vigência). É a "história da disponibilidade do médico".

## 6. Produtividade médica — FUTURO, mas o modelo já nasce pronto
> Não entra na UI da Entrega 1, mas o modelo de dados da escala deve **comportar** isto (para vender depois):
- **Previsto vs realizado:** combinado 08–17 com 1h almoço, 5 consultas/hora → previsto 40 atendimentos/dia.
  O médico atendeu conforme a escala? É produtivo?
- **Validade do atendimento:** houve **videochamada**? houve **transcrição de áudio** do atendimento?
- **Auditoria por IA médica:** um modelo treinado para medicina avalia a transcrição → **bom ou mau atendimento**.
- **Dores da empresa que isto resolve:** medir produtividade médica, previsibilidade de alocação, e a falta de
  visão dos recursos/médicos alocados.

## Perguntas abertas (não inferir)
- 🔴 Endpoint de busca de profissional na TC (item 1).
- 🟡 Granularidade do bloco que cruza a meia-noite (um bloco 22–02 ou dois?). Provável: um bloco com fim < início.
- 🟡 "Inativação parcial" — granularidade exata (bloco? dia específico? intervalo de datas?).
- 🟡 Fonte do "realizado" (atendimentos/videochamada/transcrição): vem da TC? de qual evento/endpoint? (futuro)
