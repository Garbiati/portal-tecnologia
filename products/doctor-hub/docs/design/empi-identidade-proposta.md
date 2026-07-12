# EMPI / Identidade — proposta (golden record + proveniência + external_id simples/composto)

> **Status:** PROPOSTA (reação do Alessandro pendente → vira D-xxx). Estende D-191 (EMPI paciente).
> Responde à direção do Alessandro (2026-07-12): golden record é do Doctor Hub, **sem perder o
> registro-fonte** (de qual tenant/cliente/unidade veio), e mantendo o **external_id de cada origem**
> (na Teleconsulta é `patient_id`; em outros clientes pode ser **chave composta**). Vale p/ paciente E médico.
> Pesquisa que embasa: FHIR Identifier (HL7/RNDS), MPI/EMPI survivorship, IHE PIX. Fontes no fim.

## O que a pesquisa confirmou (padrões consolidados)
1. **FHIR Identifier = `system` + `value`** (+ `use`, `type`, `assigner`). O `system` é uma URI que diz
   **QUEM atribui / em que namespace** o id vive; o `value` é o id naquele sistema. É o padrão universal
   pra "a mesma pessoa tem ids diferentes em sistemas diferentes" — e **resolve chave simples × composta
   sem casos especiais** (basta a URI do system + o value serializado). A RNDS/DATASUS usa exatamente FHIR
   R4 com **CNS** como identificador primário do paciente.
2. **MPI mantém o REGISTRO-FONTE como recebido** — separado do golden record. Boa prática: "manter a
   identidade de origem: o registro do paciente exatamente como veio do sistema fonte". Proveniência via
   `source_system` (isolamento lógico por fonte). É exatamente o "sem perder o registro-fonte" do Alessandro.
3. **Survivorship:** o golden record é derivado das fontes por regras (valor mais recente / fonte
   preferida), auditável — não "o mais antigo vence".
4. **PIX (IHE ITI-104):** o padrão de cross-reference de identificadores de paciente entre sistemas.

## A proposta — 4 camadas (o "idea" do Alessandro mapeia 1:1 nisto)

### 1. Golden record canônico — DO DOCTOR HUB
`PacienteCanonico` (já existe, D-191): `Id` (uuid = **EMPI id, nosso**), `Cpf` UNIQUE (chave de ouro),
biográfico por **survivorship**. Idem `Doctor` canônico (já é compartilhado). **A identidade-mestre é nossa.**

### 2. Vínculo com PROVENIÊNCIA (de onde veio) — refina `PacienteTenantRef`
Um vínculo por **origem** carregando a proveniência completa: `PacienteId` (→ canônico) · **`TenantId`** ·
**`ClienteId`** · **`UnidadeId?`** (o "de qual tenant/cliente/unidade") · **`SistemaOrigem`** (ex.:
`TELECONSULTA_CORE`) · status/`DisabledAt`. É o que responde "não perder de qual cliente/unidade/tenant".

### 3. Identificadores externos (o external_id, SIMPLES ou COMPOSTO) — FHIR Identifier
Uma **coleção** de identificadores por vínculo (não um único string): `IdentificadorExterno` =
`(VinculoId, System, Value, Tipo, Principal)`.
- **`System`** (URI): quem atribui — ex.: `urn:doctorhub:cliente:{C}:sistema:teleconsulta:patient`, ou um
  system nacional `https://saude.gov.br/fhir/sid/cns` (CNS), `.../cpf` (CPF).
- **`Value`**: o id naquele system. **Chave simples** (Teleconsulta → `patient_id` no value). **Chave
  composta** → duas saídas, escolha na discovery: (a) o value guarda a serialização canônica da chave
  (ex.: `"UBS99|MATR123"`), **ou** (b) várias linhas de identificador (uma por parte) + um `Tipo`
  distinguindo. Recomendo (a) por padrão + (b) só quando o cliente precisar casar por parte.
- Absorve **CNS/CPF nacionais** + o id local de cada cliente, no mesmo modelo. (D-191 já previa "CNS como coleção".)

### 4. Registro-fonte (o dado como recebido) — traceabilidade/survivorship
`RegistroFonte` por vínculo: os campos-chave **como vieram** da origem (+ `RecebidoEm`) — nunca sobrescrito.
O golden record é derivado disto; a origem fica intacta pra auditoria e re-survivorship. (Boa prática MPI.)

## Write-back / devolver com ACK (o ponto do Alessandro)
Ao devolver um agendamento/registro ao cliente (pull+ack, D-196): resolvemos o vínculo de **(paciente,
cliente-alvo)** e mandamos de volta **o(s) `IdentificadorExterno` que AQUELE sistema espera** (o `system`
+ `value` dele). O cliente reconhece **o próprio id** — nunca expomos CPF/nome (LGPD): o external_id é a chave.
Ex.: Teleconsulta recebe de volta o `patient_id` dela; um cliente de chave composta recebe a chave dele.

## Médico: mesma forma, dois eixos que NÃO se confundem
- **Identidade** do médico: `Doctor` canônico + vínculo-de-identidade (proveniência + `IdentificadorExterno`,
  ex.: CRM, ou o `provider_id` do sistema de origem) — para write-back.
- **Acesso/escopo** do médico: `DoctorVinculo` (Lote 3 — em quais tenant/cliente/unidade ele PODE atuar).
São **complementares**: um diz "o id do médico em cada sistema", o outro "onde ele pode agir". Podem
compartilhar o par (doctor, cliente) como chave, mas modelam coisas diferentes.

## Perguntas abertas (discovery, antes de virar D-xxx)
- 🔴 **Chave composta:** serialização única no `value` (a) × múltiplos identificadores (b) — por cliente?
- 🟡 **Survivorship:** quais campos, qual fonte preferida, quem revisa match incerto (governança MPI).
- 🟡 **CNS/CPF:** modelar como `IdentificadorExterno` de system nacional (RNDS) desde já?
- 🟡 **Matching:** CPF exato (determinístico) é suficiente, ou precisa de match probabilístico (nome+nascimento)?
- 🟢 **Registro-fonte:** guardar JSON cru ou só campos-chave normalizados?

## Fontes
- [Using FHIR Identifiers — HL7 Confluence](https://confluence.hl7.org/display/PA/Using+FHIR+Identifiers)
- [IHE PIXm ITI-104 (Patient Identifier Cross-referencing)](https://profiles.ihe.net/ITI/PIXm/ITI-104.html)
- [Patient Identifiers in HL7/IHE Profiles (Appendix E)](https://profiles.ihe.net/ITI/TF/Volume2/ch-E.html)
- [MPI survivorship & matching (CapMinds)](https://www.capminds.com/blog/mpi-survivorship-rules-and-probabilistic-matching-strategies-for-enterprise-patient-identity-resolution/)
- [RNDS — FHIR R4 / CNS (DATASUS)](https://rnds-fhir.saude.gov.br/)
