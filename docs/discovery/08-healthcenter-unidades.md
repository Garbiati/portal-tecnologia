# HealthCenter & Unidades (profile_tags) — modelo verificado na Teleconsulta

> Verificado em 2026-06-15 lendo o repo da TC (`/home/alessandro/ptm/teleconsulta`).
> NÃO é inferência — é o modelo de dados que **já existe** na Teleconsulta. Confirma a **D-041**.
> Fonte: `services/ptm-core-api/CoreApi/...` (caminhos abaixo).

## Hierarquia

```
HealthCenter  (= um CLIENTE = um ESTADO; ex.: Piauí, Amazonas)
├── ProfileTagGroup        (grupo de unidades dentro do HC — opcional)
│   └── ProfileTag         (UNIDADE de saúde; tem cnes_code UNIQUE)
│       ├── PatientProfileTag   (N:N paciente ↔ unidade)
│       ├── DoctorProfileTag    (N:N médico ↔ unidade)
│       └── cnes_code → gov_estabelecimentos (endereço, UF, município, coords)
└── (admins, doctors, patients, sessions, requisitions… do HC)
```

Uma unidade (`ProfileTag`) **pertence a exatamente um** HealthCenter (nunca a dois estados).

## `health_centers` (= cliente/estado)
`Entities/Models/HealthCenter.cs` · migration `20260525182550_InitialCreate.cs:305`
- `id` (uuid, PK), `name` (varchar64, UNIQUE), `normalized_name` (UNIQUE),
  `logo_url`, `allow_measurement`, `has_vaccine_module`, `patient_can_schedule`,
  `domain` (varchar80), timestamps.
- ⚠️ **Não há coluna de UF** no HC — o estado é identificado pelo `name`/`domain` e
  materializado via o CNES das suas unidades. (Ponto a confirmar se precisarmos de UF formal.)

## `profile_tags` (= UNIDADE de saúde)
`Entities/Models/Tags/ProfileTag.cs` · migration `:1097`
- `id` (uuid, PK), `name`, `normalized_name`, `public_name` (varchar50),
  `health_center_id` (FK → health_centers), `group_id` (FK → profile_tag_groups, nullable),
  `disable_scheduling` (bool), `disable_live_queue` (bool), `public` (bool, def true),
  `disable_access` (bool), **`cnes_code` (varchar200, UNIQUE INDEX)**,
  `profile_tag_type` (int enum), timestamps.
- **Enum `ProfileTagType`** (`Core/Enums/ProfileTagType.cs`): 0 Undefined · 1 Health · 2 School ·
  3 Prison · 4 Admin · 5 Municipality · 6 Private.

## `profile_tag_groups`
`Entities/Models/Tags/ProfileTagGroup.cs` · migration `:847`
- `id`, `name`, `normalized_name`, `health_center_id` (FK), timestamps.

## `patient_profile_tags` (N:N paciente ↔ unidade)
`Entities/Models/Tags/PatientProfileTag.cs` · migration `:1730`
- `id`, `patient_id` (FK → patient_profiles, CASCADE), `tag_id` (FK → profile_tags, CASCADE),
  `default` (bool — a tag/unidade padrão do paciente), timestamps.

## CNES — presencial × remoto
- `profile_tags.cnes_code` (UNIQUE) liga à tabela `gov_estabelecimentos` (`CO_CNES`),
  que tem endereço, `CO_ESTADO_GESTOR`, `CO_MUNICIPIO_GESTOR`, lat/long.
  (`Entities/Models/CNES/GovEstabelecimento.cs`; join em `Repositories/Data/ProfileTagRepository.cs:41`)
- **Não há campo explícito presencial/remoto.** A diferença é por uso:
  - **Remoto**: usa um **CNES virtual** configurado por HC (`DefaultRemoteCNESConfig`) — o
    "núcleo de telessaúde do estado" (`ProfileTagService.cs:644`).
  - **Presencial**: o CNES real do estabelecimento (endereço em `gov_estabelecimentos`).

## Endpoints úteis (p/ a integração futura)
- `GET /integration/profile-tags/by-cnes` — resolve a unidade pelo CNES (auth **PartnerApiKey**,
  header `PTM-Client-Domain`). **É a porta que o nosso sistema usaria** (casa com a D-002).
  (`IntegrationController.ProfileTags.cs:22`)
- `GET /profiles/tags` / `…/paged` — lista unidades do HC autenticado.
- `GET /profiles/tags/cnes?siglaestado=&municipio=` — lista CNES por estado/município.

## Impacto no nosso modelo (protótipo)
- Renomear no protótipo: nosso **"Cliente"** → **HealthCenter** (estado); nosso **"HC/unidade"**
  → **Unidade (ProfileTag)** com `cnes_code` e `profile_tag_type`.
- O **Gestor** (D-038) gere uma **Unidade (ProfileTag)** e enxerga o pool do seu **HealthCenter**.
- O **Solicitante** atua no nível do **HealthCenter** (estado).
- Pacientes vêm por **Unidade** (`patient_profile_tags`) — refina D-012 (era "por health center";
  na verdade é por **unidade/profile_tag** dentro do HC).
