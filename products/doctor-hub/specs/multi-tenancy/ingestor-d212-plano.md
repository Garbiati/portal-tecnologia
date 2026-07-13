# Ingestor D-212 — plano de implementação (espelho de cadastro TC → homod, pseudonimizado)

> Blueprint pra construir rápido quando os 2 secrets RO existirem. Decisão-mãe: **D-212**.
> Padrão que estende: **D-069** (`Integration/Teleconsulta/` — pull read-only, só-SELECT, off por default).
> Estado: **peça 1 pronta** (`PseudonimizadorPaciente`, 46 testes verdes, commitada). Resto = abaixo.

## Escopo (D-212, confirmado)
- 3 HealthCenters: **Piauí (SES-PI/C1), Amazonas (SES-AM/C2), Alagoas (SES-AL/C3)**.
- Pacientes: só **últimos 12 meses** (`health_center_patient_profiles.created_at`; pendência: cadastrado-no-HC vs teve-consulta `requisitions.created_at` — a confirmar).
- Doutores = identidade **REAL**; pacientes = **ANONIMIZADOS** (via `PseudonimizadorPaciente`, chave = `patient_profiles.external_id`/uuid, não-PII).
- **SEM** agendamentos/solicitações — a jornada é ao vivo.

## Mapa origem (TC) → destino (homod)
| Destino (homod) | Origem (TC) | Banco | Observação |
|---|---|---|---|
| `Cliente` (match C1/C2/C3 por UF; grava uuid em `ExternalId`) | `health_centers` (id,name,domain) + UF via `health_center_cep_coverage`→`health_center_allowed_states.state_uf` | CORE | casa por UF PI/AM/AL nos clientes existentes; NÃO cria novos |
| `Unidade` (`ExternalId`=uuid, `Cnes`) | `profile_tags` (id, name, public_name, `health_center_id`, `cnes_code`, `disable_scheduling`, deleted_at) | CORE | por HC dos 3 |
| `Doctor` (identidade real; upsert por `ExternalId`) | `doctor_profiles` (id, specialization, cpf, deleted_at) + nome via `users.person_id`→`persons.first_name/last_name` + `doctor_profile_licenses` (license=CRM, rqe) | CORE + **AUTH** (persons) | **único cross-bank**: nome vem do AUTH |
| `DoctorVinculo` (N:N doutor↔cliente) | `health_center_doctor_profiles` (doctor_id, health_center_id, status, disabled_at) | CORE | mapeia p/ Tenant.PortalId + ClienteId (do HC casado) |
| `PacienteCanonico` (EMPI, CPF **fake**) | `patient_profiles` (id, `external_id`, deleted_at) — **NÃO** ler cpf_number/name real | CORE | CPF/nome/nascimento via `PseudonimizadorPaciente(external_id)` |
| `PacienteTenantRef` (external_id REAL) | `health_center_patient_profiles` (patient_id, health_center_id, `created_at`, disabled_at) | CORE | `TenantSistema="TELECONSULTA_CORE"`, `ExternalPatientId`=patient_profiles.external_id (real, não-PII) |

## Peças a construir (fatias)
1. ✅ **`PseudonimizadorPaciente`** (feito).
2. **Config** — estender `SyncTeleconsultaOptions` (ou novo `SyncCadastroOptions`, seção `Sync:Cadastro`): `Enabled`, `CoreConnectionString`, `AuthConnectionString`, `UfsAlvo` (["PI","AM","AL"]), `PacientesDesdeMeses` (12). Off por default; strings via Secret Manager (nunca no código).
3. **DTOs** — `ClienteTc`, `UnidadeTc`, `DoctorTc` (já existe `DoutorTeleconsulta` — estender/reusar), `VinculoTc`, `PacienteTc` (só id/external_id/health_center_id/created_at — SEM PII).
4. **Fontes Dapper read-only** (só-SELECT, D-069) — uma por entidade; desligada sem connection string (retorna vazio). SQL valida contra o schema (offline por inspeção; só roda com secret):
   - **Clientes:** `SELECT hc.id, hc.name, s.state_uf FROM health_centers hc JOIN health_center_cep_coverage cov ON cov.health_center_id=hc.id JOIN health_center_allowed_states s ON s.health_center_cep_coverage_id=cov.id WHERE hc.deleted_at IS NULL AND s.state_uf = ANY(@ufs)`.
   - **Unidades:** `SELECT id, name, public_name, health_center_id, cnes_code FROM profile_tags WHERE health_center_id = ANY(@hcIds) AND deleted_at IS NULL`.
   - **Doutores:** CORE `SELECT dp.id, dp.specialization, hcdp.health_center_id, u.person_id FROM doctor_profiles dp JOIN health_center_doctor_profiles hcdp ON hcdp.doctor_id=dp.id JOIN users u ON u.doctor_profile_id=dp.id WHERE hcdp.health_center_id=ANY(@hcIds) AND dp.deleted_at IS NULL` + licenças `doctor_profile_licenses`; **AUTH** `SELECT id, first_name, last_name FROM persons WHERE id = ANY(@personIds)` → stitch em memória (nome real).
   - **Vínculos:** `SELECT doctor_id, health_center_id, status FROM health_center_doctor_profiles WHERE health_center_id=ANY(@hcIds) AND disabled_at IS NULL`.
   - **Pacientes:** `SELECT pp.external_id, hcpp.health_center_id FROM health_center_patient_profiles hcpp JOIN patient_profiles pp ON pp.id=hcpp.patient_id WHERE hcpp.health_center_id=ANY(@hcIds) AND hcpp.disabled_at IS NULL AND hcpp.created_at >= @desde AND pp.deleted_at IS NULL` — **nunca** SELECT em cpf_number/nome real.
5. **Serviço de upsert** (`CadastroSyncService`) — testável com fontes FAKE (sem banco TC). Ordem FK: (a) casar HC→Cliente por UF, gravar `Cliente.ExternalId`; (b) upsert `Unidade` (por ExternalId); (c) upsert `Doctor` (por ExternalId, nome real); (d) upsert `DoctorVinculo` (Tenant.PortalId + ClienteId casado); (e) upsert `PacienteCanonico` (CPF fake via pseudonimizador) + `PacienteTenantRef` (external_id real). **Colisão de CPF fake** (EMPI unique): se colidir, re-derivar com sufixo na chave OU pular + logar (a identidade real é o `PacienteTenantRef.ExternalId`, não o CPF). Idempotente (re-run não duplica).
6. **Runner + trigger** — `CadastroSyncRunner` (uma passada, ordem FK, watermark opcional) + background service opt-in (espelha `SyncDoutoresBackgroundService`), off por default.
7. **Fiação** — DI + envs no Cloud Run (`Sync__Cadastro__CoreConnectionString`/`AuthConnectionString` → secrets `teleconsulta-core-ro-connection`/`teleconsulta-auth-ro-connection`).

## Testes (offline)
- `PseudonimizadorPaciente` ✅. `CadastroSyncService` com fontes FAKE: casamento por UF, upsert idempotente, paciente entra no EMPI com CPF fake válido + ref com external_id real, vínculo no cliente certo, colisão de CPF tratada. As fontes Dapper (SQL) só validam de fato ao rodar com secret.

## Pendências do humano (antes de LIGAR)
- Provisionar `teleconsulta-core-ro-connection` + `teleconsulta-auth-ro-connection` (secrets no projeto `portal-tecnologia-500920`).
- Confirmar filtro "12 meses" (cadastrado-no-HC vs teve-consulta).
- Confirmar que nome REAL de doutor no homod é aceitável (semi-público; é o combinado em D-212).

_Registrado 2026-07-13 (madrugada, trabalho autônomo). Peça 1 (pseudonimizador) já no código._
