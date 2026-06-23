# Integração com a Teleconsulta — contrato DESCOBERTO (factual)

> Fonte: exploração read-only do repo `/home/alessandro/ptm/teleconsulta` em 2026-06-14.
> Isto é o que o CÓDIGO mostra — não inferência. Detalhes finos (defaults, 200 vs 201) devem
> ser reconfirmados contra `specs/PRD-002-substituicao-absens/technical/api-contracts.md` na hora de construir.

## 🔭 Visão geral da Teleconsulta
- **Monorepo SDD**: ~26 microserviços em `/services` + um diretório de specs em `/specs` (PRD-xxx).
  ⚠️ **A Teleconsulta JÁ usa Spec-Driven Development.** Nossa metodologia bate com a da empresa.
- Stack predominante: **C# / .NET 10 + PostgreSQL (EF Core)**; também Python (Poetry), TS/Node (admin), Ruby (mobile).
- 🚨 **Existe um diretório `/services/saude-digital-demandas/` no monorepo — VAZIO.** Forte sinal de
  que o novo sistema pode ter sido pensado para viver DENTRO do monorepo. (Decisão a confirmar — ver 🔴 abaixo.)

## ✅ Como inserir um agendamento na TC (o que a #1 das perguntas pedia)
Endpoint: **`POST /integration/appointment`** (controller `IntegrationController.Appointment.cs`).
Auth: header **`X-API-KEY`** validado por `[PartnerApiKey(...)]` contra um enum `PartnerType`
(ex.: RegulaHub, SOSPlantao). Para nós, provavelmente seria **um novo PartnerType**.
Idempotência: campo `external_id` é UNIQUE (retry seguro).

Payload (DTO `CreateExternalAppointmentViewModel`) — campos obrigatórios em **negrito**:
- **`patient_id`** (GUID) — obtido antes via `GET /integration/patient/idbycpf?cpf=...` (ou por CNS)
- **`external_id`** — chave única (ex.: `regulation_code-confirmation_key`)
- **`start_date`** / **`end_date`** — ISO 8601 com offset local
- **`specialty`** (texto, validado contra tabela `ExternalSpecialization`) — `internal_specialization_id` (int) é recomendado
- **`preference_of_service`** — "ONLINE" | "PRESENCIAL"
- `group_id` (GUID do HC/ProfileTag — recomendado sempre enviar; mapeável por CNES via `GET /integration/profile-tags/by-cnes`)
- `preference_of_doctor_id` (GUID, opcional; se der 409, repetir sem ele)
- `regulation_code`, `confirmation_key` (auditoria), `source`, `status` (default Pending)

Endpoints de apoio: lookup de paciente por CPF/CNS; checar existência por `external_id`; listar agendamentos ativos (dedup).

## 🧩 O que isso revela sobre o DOMÍNIO do nosso sistema
1. **Nosso "agendamento" final tem schema parcialmente DITADO pela TC**: paciente + especialidade +
   janela (start/end) + HC (`group_id`) + médico preferido (opcional). Isso de-risca nossa modelagem de saída.
2. **HC ≈ `ProfileTag`/`group_id` na TC**, identificável por **CNES**. Nosso "Health Center" provavelmente casa com isso.
3. **Paciente precisa EXISTIR na TC** (lookup por CPF/CNS retorna `patient_id`). Isso reconcilia com
   "o paciente entra aqui": provavelmente cadastramos/identificamos o paciente e resolvemos o `patient_id` da TC. (a confirmar)
4. **A TC NÃO valida agenda/slot do médico na integração** — o agendamento entra como `Pending` e o
   *matching* de médico acontece depois (serviço `ptm-matching-api`). 🤔 Isso levanta a pergunta de
   fronteira: a alocação de médico é nossa (novo sistema) ou da TC? Há sobreposição potencial.
5. Sem FHIR/RNDS na v1 da TC — integração é por **API-key de parceiro**, síncrona (sem fila/evento).

## ✅ Resolvido (ver `docs/decisions/decisions-log.md`)
- ✅ **Onde vive (D-002):** repo SEPARADO, integra como parceiro via `X-API-KEY`. Liberdade de stack.
- ✅ **Quem aloca o médico (D-003):** a alocação é NOSSA — enviamos `preference_of_doctor_id`; a TC
  respeita `external_appointments`. Sem sobreposição com `ptm-matching-api`.

## 🔴 Ainda em aberto
- 🟡 Mapeamento de especialidades (texto/`internal_specialization_id`) entre os dois sistemas.
- 🟡 Como resolvemos `patient_id` da TC (lookup por CPF/CNS; e se o paciente não existe lá? criamos?).
- 🟡 Precisamos de um novo `PartnerType` + `X-API-KEY` emitida pela equipe da TC (tarefa para a equipe TC).
