# Especialidades por Health Center — relação na Teleconsulta

> Verificado em 2026-06-15. Nível de MODELO lido dos arquivos da TC; **dados reais por estado obtidos
> via consulta READ-ONLY ao core DB de produção** pelo caminho sancionado do repo da Teleconsulta
> (`scripts/db/query-prod-ro.sh` — Vault RO + cloud-sql-proxy; só agregação, sem PII). 2026-06-15.
> _(Nota de processo: o script é do repo `teleconsulta`, não do `saude-digital-demandas`.)_

## O que ESTÁ confirmado (do código da TC)

### 1. Existe tabela canônica de especialidade × HC
`Entities/Models/HealthCenterSpecialty.cs`:
- `HealthCenterId` (Guid) + `SpecialtyId` (Guid) + `IsActive` (bool, default true).
- Índice único `(HealthCenterId, SpecialtyId)`; FKs para `HealthCenter` e `Specialty`.
- ✅ Ou seja: **"quais especialidades um health_center oferece" é um conceito de 1ª classe na TC** —
  não precisa ser inferido agregando appointments; há uma tabela própria (`health_center_specialties`).

### 2. Chave canônica da especialidade
`Entities/Models/ExternalAppointment.cs`:
- `InternalSpecializationId` (int) → **chave estável** da especialidade.
- `Specialty` (string) → texto livre, **não-confiável** (não usar para casar).
- `PatientId` (Guid, FK) → o vínculo ao health_center passa **pelo paciente**
  (não há FK direta de appointment → health_center). `TagId` (Guid?) é nullable.

### 3. Tabela de especialidades
`Entities/Models/Specialty.cs` (id, name, etc.). É a referência canônica de especialidades da TC.

## Impacto no nosso sistema (a decidir — NÃO inferir)
- 🟡 **Fonte das especialidades por estado**: usar a tabela `health_center_specialties` da TC
  (canônica, com `IsActive`) em vez de uma lista global. Isso faria a tela de Solicitação mostrar
  **só as especialidades habilitadas** para aquele estado.
- 🟡 **Mapear especialidades por `InternalSpecializationId`** (não por texto) — refina o 🟡 antigo
  "mapeamento de especialidades com a TC".
- 🟡 Hoje o protótipo tem só 5 especialidades genéricas; o catálogo real da TC é maior. Expandir o
  seed e ligar HC→especialidades quando tivermos a fonte de dados.

## Especialidades reais por estado (prod, RO, 2026-06-15)
Query: `DISTINCT internal_specialization_id` em `external_appointment`, ligada ao HC via
`patient_id → health_center_patient_profiles → health_centers`, agrupada por `hc.name`. IDs mapeados
pelo enum `DoctorSpecializationType` (`Core/Enums/DoctorSpecializationType.cs`).

| HC (nosso id) | nome na TC | spec ids (DoctorSpecializationType) |
|---|---|---|
| hc-piaui | Piauí | 3,5,7,8,10,12,13,16,17,19,21,22,25,27 |
| hc-amazonas | Saúde AMDigital | 3,5,7,8,10,11,12,13,16,17,18,19,21,22,25,27,29,30,31,32 |
| hc-alagoas | Alagoas | 3,5,7,8,10,11,12,15,16,17,19,21,22,25,27,28,29,31,32 |
| hc-iasep-para | IASEP-PARA | 3,5,7,8,10,12,16,17,19,21,25,27 |
| hc-amapa | AMAPÁ SAÚDE | (só 3 — 2 atendimentos; praticamente vazio) |

Enum (id → especialidade): 0 Infectologista*(sentinela/legado)* · 3 Cardiologista · 5 Dermatologista ·
7 Psicólogo · 8 Psiquiatra · 10 Endocrinologista · 11 Gastroenterologista · 12 Ginecologista ·
13 Obstetra · 15 Nefrologista · 16 Neurologista · 17 Nutricionista · 18 Oftalmologista ·
19 Ortopedista · 21 Pediatra · 22 Psiquiatra Infantil · 25 Urologista · 27 Neurologista Infantil ·
28 Psicólogo Infantil · 29 Geriatra · 30 Hepatologista · 31 Alergologista · 32 Endocrinologista Infantil.

> O **id 0** aparece com 59 idênticos em PI e AM → tratado como sentinela, não demanda real. HCs de
> teste (`HC Teste`, `test_dev`) ignorados. Esta é a oferta HISTÓRICA realizada (de appointments), não
> necessariamente o catálogo habilitado — mas serve bem para popular "especialidades por estado".

## Próximo passo (a wirar no app)
- Expandir o catálogo `ESPECIALIDADES` (hoje 5 genéricas) para o conjunto real, usando o
  `InternalSpecializationId` como **id canônico** (alinha com a TC).
- Adicionar a relação **HC → especialidades** (a tabela acima) e filtrar a tela de Solicitação para
  mostrar **só as especialidades do estado** selecionado.
