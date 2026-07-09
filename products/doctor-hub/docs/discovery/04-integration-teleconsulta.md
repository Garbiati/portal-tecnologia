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
  - ✅ **Decisão (2026-07-09):** reusar a key de **SOSPortal de produção** (não emitir nova); secret na GCP (Secret Manager), sem colar valor em lugar nenhum. A allowlist do `idbycpf` p/ `PartnerType.SOSPortal` ainda precisa ser confirmada pela equipe TC.

## 🧬 REGRA DA REALIDADE — como os pacientes existem no tenant da Portal (TC) (2026-07-09, ditada pelo Alessandro)

> Isto NÃO é regra do Doctor-Hub — é a **realidade factual** do estado atual dos pacientes na
> Teleconsulta (tenant Portal Telemedicina). O nosso desenho de integração tem que se adaptar a ela.

1. **Paciente pertence sempre a ≥1 CLIENTE** (HC). Pode pertencer a **2 ou mais** clientes ao mesmo
   tempo — ex.: um paciente do **Amazonas** e de **Povos da Floresta** (clientes públicos), que também
   podem ter um cliente **privado**. Ou seja, cardinalidade **paciente N:N cliente**.
2. **`PTM-Client-Domain` MUDA conforme o cliente.** Não é um domain fixo do sistema — é **por cliente**.
   Logo, resolver um paciente na TC é sempre **por (CPF, cliente/domain)**, nunca "o paciente global".
3. **Chave de identificação = CPF.** É o que amarra as contas de um mesmo humano entre clientes/domains.
4. **DÉBITO TÉCNICO conhecido da TC:** hoje um mesmo paciente pode ter **DUAS (ou mais) contas com
   e-mails diferentes** (duplicação de cadastro). Portanto, o mesmo CPF pode resolver para
   `patient_id` **diferentes** dependendo do cliente/domain (e até dentro do mesmo). **Futuro
   (planejado, sem data):** refatoração → **cadastro único** por paciente, com **vínculos** a clientes
   diferentes. Até lá, tratamos "CPF → possivelmente vários patient_id por domain" como o normal.
5. **Implicação pro Doctor-Hub:** o `TeleconsultaCore.ClientDomain` **NÃO pode ser config fixo** (como
   está hoje no lookup dormente D-185) — o domain tem que vir **do cliente do agendamento/vaga** em cada
   chamada. E a resolução de identidade precisa de uma camada de **normalização** que absorva essa
   duplicação e o N:N (ver o design de "integração de tenants legados" em andamento).
