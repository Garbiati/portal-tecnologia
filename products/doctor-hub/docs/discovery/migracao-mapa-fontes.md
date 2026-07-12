# Mapa de fontes — migração de continuidade (onde cada dado vive)

> Discovery pra a spec de migração/ingestão. **Três fontes distintas** (o ponto que corrige a leitura ingênua):
> 1. **Teleconsulta / ptm-core-api** (legado da Portal) — paciente, médico, cliente/HC, unidade, especialidade.
> 2. **Empresa TERCEIRA de agendamento** (externa, via API) — **o HISTÓRICO de escalas e agendamentos**. Não há código aqui; precisa da API deles.
> 3. **Doctor-Hub** (o sistema novo) — o DESTINO. As tabelas `escalas`/`agendamentos` existem mas hoje só têm dado de demo; a operação real vive na fonte 2.
> LGPD: só estrutura/tabela aqui — nada de dado real.

## Fonte 1 — Teleconsulta / ptm-core-api (acessível em `workspace/`)
Tem **2 bancos**: **AUTH** (Identity/Keycloak) e **CORE** (negócio).

| Domínio | Tabela(s) na TC | Campos-chave | Gotcha importante |
|---|---|---|---|
| **Paciente** | CORE `patient_profiles`, `health_center_patient_profiles` | `Id` (uuid), `CpfNumber`, `NationalHealthCard` (CNS), `ExternalId` | **CPF SEM unicidade** → mesmo CPF vira N `patient_id` por cliente/domain (o débito que o EMPI/D-191 absorve) |
| **Médico** | CORE `doctor_profiles` (+ `doctor_profile_licenses`) · AUTH `AspNetUsers`→`user_profiles`→`persons` | `Id` (uuid, chave cross-DB), `License` (CRM+estado), `Specialization` (int enum), CPF | **Identidade partida em 2 bancos** não-joináveis; **qualidade: Nome 100%, CRM 96%, CPF só ~30%, RQE 0%** (RQE nasce no DH) |
| **Cliente (Health Center)** | CORE `health_centers` (+ `health_center_specialties`) | `Id` (uuid), `Name`/`NormalizedName` (UNIQUE), **`Domain`** (o PTM-Client-Domain) | TC não tem UF formal — estado vem do `Name`/`Domain` + CNES das unidades |
| **Unidade** | CORE `profile_tags` (+ groups/type) | `Id` (uuid), `Name`, **`CNESCode`** (UNIQUE), `HealthCenterId` (FK), `ProfileTagType` | Mapeio unidade↔ProfileTag **por CNES** (endpoint `/integration/profile-tags/by-cnes`) |
| **Especialidade** | CORE `specialties`, `doctor_specialization_enums` | `Id` (uuid), `Name` (UNIQUE), **`LegacySpecialtyId`/`InternalSpecializationId`** (int 0–32, UNIQUE), `CBO` | **Casar por `InternalSpecializationId` (int), NUNCA por texto** (o nome não é confiável) |

**Write-back (pull+ack, D-196):** a TC tem `ExternalAppointment` — endpoint que **RECEBE** agendamentos de parceiros (POST). É o alvo natural pra devolver os agendamentos confirmados à TC. (A TC não gera escala/agendamento pra fora; ela recebe.)

## Fonte 2 — **SOS Gestor** (empresa terceira incumbente, via API) — **FALTA a doc da API** (D-209)
- **O HISTÓRICO de escalas e agendamentos dos doutores** vive no **SOS Gestor** (não no Absens — correção D-209). Deram **acesso via API**. **Não há schema/código nos repos locais.**
- Precisa da doc da API deles: endpoints (escala, agendamento, deltas), campos (como chamam id de médico/paciente/agendamento/status/vaga/unidade), auth, paginação/rate-limit, e o **contrato** (contratado × real).
- **Fonte crítica da migração de continuidade** — é o fornecedor que pode cortar o acesso.

## Fonte 4 — **SISReg III** (regulador do SUS-AM, governo) — via `regula-hub`/`regula-sisreg`
- A **DEMANDA** (agendamentos que **já vêm agendados** do governo). Cliente-âncora: **Saúde AM Digital**.
- Ingerida pelos sistemas internos **`ptm-regula-sisreg`** (raspagem CSV + ficha, pool de credenciais, reCAPTCHA) → **`ptm-regula-hub`** (orquestrador .NET que converte pro formato Saúde AM e faz push). PRD-002 "Substituição do Absens".
- **Absens** = raspador antigo do SISReg (quebrou no reCAPTCHA) — substituído pelos regula-*.
- Esses sistemas **fazem bypass do SOS Gestor** (que não conseguiu adequar pra integrar com SISReg/Absens).

## Fonte 3 — Doctor-Hub (destino)
- `escalas`, `agendamentos`, `agendamento_outbox`, `pacientes_canonicos`/`pacientes_tenant_refs` (EMPI), `doctors`, `clientes`, `unidades`, `especialidades`, `doctor_vinculos`. Já modelado (fundação na branch).
- O histórico da fonte 2 é ingerido para cá (agendamentos); paciente/médico/cliente/unidade da fonte 1 hidratam o EMPI + cadastros.

## Chaves de correlação (pra o EMPI/matching)
- **Paciente:** CPF (mas cuidado: na TC não é único → resolver por (CPF, cliente/domain)). CNS como identificador adicional.
- **Médico:** `doctor_profiles.id` (uuid) da TC = `Doctor.ExternalId` no DH. CPF só ~30% → **não dá pra casar médico só por CPF**; usar o id da TC.
- **Cliente:** `health_centers.id` (TC) = `Cliente.ExternalId` (DH).
- **Unidade:** **CNES** (TC `CNESCode` ↔ DH `Unidade.Cnes`).
- **Especialidade:** `InternalSpecializationId` (int).

## Implicações pra a migração
- **Homolog = anonimizado / Produção = real** (Opção A, duas ingestões).
- **Paciente:** pseudonimizar CPF/nome no homolog; real (criptografado) em prod.
- **Médico:** o sync TC→DH já existe (RO); a migração reusa. CPF esparso → id da TC é a chave.
- **Escala/Agendamento (histórico):** ingerir da **API da empresa terceira** — one-shot + delta até o corte; snapshot seguro CEDO (de-risking do fornecedor).
- **Vínculos doutor↔cliente:** provavelmente **derivados** dos agendamentos/escalas históricos (quem atendeu qual cliente) — a fonte 2 informa isso.
