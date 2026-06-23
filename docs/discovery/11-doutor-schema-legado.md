# 11 — Schema do Doutor no legado (Teleconsulta) — introspecção verificada

> **Fonte:** consulta read-only à produção via `teleconsulta/scripts/db/query-prod-ro.sh`
> (proxies core `54322` / auth `54323`, lease RO do Vault). **Sem PII de paciente.**
> **Data da introspecção:** 2026-06-15. Estes são **fatos do schema**, não regras de negócio.

---

## 1. Onde o doutor mora hoje (2 bancos separados)

A identidade do doutor está **fragmentada em dois bancos** que NÃO se cruzam por SQL
(são instâncias separadas). A chave que os une é o **`doctor_profiles.id` (uuid)** —
**verificado**: o mesmo uuid existe nos dois lados.

### Banco AUTH (`covid-prod-auth`) — identidade / login
ASP.NET Identity. Cadeia de join:

```
AspNetUsers (email, phone_number, user_name)
   └─ user_profile_id → user_profiles
                          ├─ person_id        → persons (first_name, last_name)
                          └─ doctor_profile_id → doctor_profiles (só id + timestamps)
```

- `AspNetUsers`: email, phone_number, password_hash, etc.
- `persons`: first_name, last_name.
- `doctor_profiles` (auth): **magro** — só `id`, timestamps, `deleted_at`.

### Banco CORE (`covid-prod-2020040701`) — dados profissionais
- `doctor_profiles` (core): `id` (= mesmo uuid do auth), `specialization` (int → enum),
  `license` (CRM, varchar), `cpf`, `personal_data_fill_required`, `deleted_at`.
- `doctor_specialization_enums`: tabela-enum **0..31** (32 valores). Coincide com o
  `DoctorSpecializationType` do código C#. (lista em [10-especialidades-por-hc](10-especialidades-por-hc.md))
- `doctor_status_enums`: `0=Away`, `1=Active`.
- Outras: `doctor_profile_licenses`, `doctor_profile_tags`, `doctor_ratings`,
  `doctor_signatures`, `health_center_doctor_profiles`.

---

## 2. Qualidade dos dados — onde cada campo REALMENTE mora

> ⚠️ **Correção (2026-06-15):** uma 1ª medição olhou as tabelas ERRADAS
> (`auth.persons` p/ nome → 3%; `core.doctor_profiles.license` p/ CRM → 2%). As fontes
> corretas estão abaixo. **O nome existe para 100% dos ativos** (confirmado pelo Alessandro).

As fontes **corretas** (médicos **ativos**, `deleted_at IS NULL`, ~4.526):

| Campo | Cobertura | Fonte correta |
|---|---|---|
| `id` (→ `external_id`) | **100%** | `core.doctor_profiles.id` |
| **nome** (first + last) | **100%** ✅ | `core.users` → `core.persons` (first_name/last_name) |
| **CRM** (`license`) | **96%** (4.341) | `core.doctor_profile_licenses.license` (por estado, c/ `state_id`) |
| `specialization` | 100% | `core.doctor_profiles.specialization` (86% = default `GeneralPhysician`) |
| nascimento | ~77% (3.504) | `core.persons.date_birth` |
| `cpf` | ~30% (1.363) | `core.doctor_profiles.cpf` |
| **email** | ~100% | `auth.AspNetUsers` (via `auth.user_profiles.doctor_profile_id`) |
| RQE | **0%** | não preenchido em lugar nenhum → **nasce no nosso sistema** |

**Conclusão factual (revisada):** o legado **tem** identidade utilizável — nome (100%),
CRM (96%) e especialidade (100%). O pull pode ser feito **quase todo no CORE** (um banco);
só o **email** vem do AUTH. O que falta de fato é **RQE (0%)** e **CPF (70% vazio)** —
exatamente os campos que o cadastro-dono nosso vai **preencher/evoluir**.

> Cadeia de nome no CORE: `doctor_profiles ← users.doctor_profile_id`,
> `users.person_id → persons(first_name,last_name,date_birth,gender,avatar_url)`.
> (Espelha a cadeia do AUTH, mas no CORE a `persons` está 100% preenchida.)

> Distribuição de especialização: `GeneralPhysician` 3.895, `Cardiologist` 97,
> `Orthopedist` 69, `Psychologist` 67, `Dermatologist` 65… (cauda longa).

---

## 3. Telediagnóstico — NÃO está neste banco

Procurado: colunas `modal*/type/product` em tabelas de doutor e tabelas
`telediag*/exam*/report*/laudo*` → **0 resultados** no core da Teleconsulta.
Não há, neste banco, marca de modalidade que separe "doutor de teleconsulta" de
"doutor de telediagnóstico". **Telediagnóstico é outro sistema/base** (sem acesso aqui).
→ Como representar o doutor de telediagnóstico é **pergunta aberta** (não inferir).

---

## 4. O que isto implica para o ETL / snapshot (D-054)

- **Chave do snapshot:** `doctor_profiles.id` (uuid) → vira nosso `external_id`.
- **Montagem (2 queries, junção do nosso lado):**
  1. CORE: `id, license(CRM), specialization, cpf` (ativos).
  2. AUTH: `id, email, nome(persons)` via cadeia user_profiles.
  - Juntar por `id` no nosso ETL (não dá JOIN cross-DB).
- O snapshot serve para **identificar e correlacionar** doutores existentes (por email/id),
  **não** como cadastro pronto — porque o cadastro do legado é incompleto.

---

## 5. Por que sermos "donos do cadastro" (justificativa revisada)

O legado **tem** identidade utilizável (nome 100%, CRM 96%, esp 100%) — então o motivo
de sermos a fonte **não** é "o legado é vazio". É **ownership/ciclo de vida**: o Alessandro
quer que o médico **nasça aqui**, com os campos que o legado **não** tem (RQE, valores
fixo/adicional, contato completo) e que facilitam **faturamento** e **provisionamento**
para os destinos (TC e/ou Telediagnóstico). O `external_id` amarra cada médico nosso ao
registro do destino. Ver D-055/D-056 no `decisions-log.md`.

## 6. Estratégia de carga (D-056): SYNC contínuo até a virada de chave

Enquanto o cadastro/edição/exclusão **ainda** existir na Teleconsulta, rodamos um
**job de importação recorrente** (upsert por `external_id`) que mantém nossa base
espelhando os **ativos** da TC. **Quando virar a chave**, o CRUD passa a ser **só aqui**
e o job para (a direção se inverte: nós→TC via API). Tudo isto é **leitura** da TC
(RO, sancionado); nada escreve na TC. Caveats operacionais do RO: lease Vault 24h +
proxies caem em reboot → o job depende do acesso estar de pé (ver `scripts/db/prod-up.sh`).
