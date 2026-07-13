# Spec — Domínio CNES (base pública) + modelo da Unidade

> DDD2: esta doc é a realidade confirmada; o código é derivado. Decisões-mãe: **D-215** (unidades vêm da
> base pública do CNES, não da TC) e **D-216** (modelo da Unidade). "Reflete a realidade" — Alessandro.

## 1. Dois conceitos SEPARADOS (D-216)
- **`Cnes`** = a base PÚBLICA de estabelecimentos (referência/lookup). Uma coisa.
- **`Unidade`** = onde o atendimento acontece (entidade operacional do doctor-hub). Outra coisa.
- Uma Unidade **pode** referenciar um CNES (quando é estabelecimento de saúde físico) — **ou não** (escola, prisional, virtual…).

## 2. Domínio `Cnes` (isolado, read-mostly)
Tabela própria, populada da base pública (D-215), **atualizada por job mensal** (automatiza o que na TC é manual).
Campos (da base oficial): `codigo_cnes` (PK, 7 díg), `razao_social`, `nome_fantasia`, `tipo_estab` (código+descrição do CNES), `natureza`, `gestao` (M/E/D), `uf`, `codigo_municipio`, `municipio`, `cep`, `logradouro`+`numero`+`bairro`, `latitude`, `longitude`, `atualizado_em`. Escopo inicial: **UF ∈ {PI, AM, AL}**.
**Ingestão** (D-215): via **API Dados Abertos DEMAS** (`apidadosabertos.saude.gov.br`, filtra por UF/município — confirmar params no Swagger) ou **download DATASUS** (`arquivosBaseDados.jsp`, CSV nacional → filtrar UF). Só-leitura da fonte; nunca escreve na origem.

## 3. Domínio `Unidade` (operacional) — D-216
| Campo | Tipo | Regra |
|---|---|---|
| `Id` | Guid | |
| `Nome` | string | |
| `Tipo` | enum `TipoUnidade` | **SAUDE · ESCOLA · PRISIONAL · OUTROS** (contexto de atendimento) |
| `Natureza` | enum `NaturezaUnidade` | **PUBLICO · PRIVADO** (ortogonal ao tipo — clínica privada = SAUDE+PRIVADO) |
| `PreferencialAtendimento` | enum `Modalidade` | **PRESENCIAL · REMOTO** — **default overridável** da modalidade no agendamento |
| `Virtual` | bool | true = sem endereço físico, atendimento no app (ambulatório virtual); dispensa CNES/endereço |
| `CodigoCnes` | string? (FK→`Cnes`) | preenchido só quando **Tipo=SAUDE e não-Virtual**; traz o endereço da base |
| `Endereco` | derivado/manual | vem do `Cnes` (saúde física) ou manual; **irrelevante** se `Virtual` |
| `Ativo` | bool | soft-disable |

**Invariantes:**
- **(I) ✅ implementada (fatia 1):** `CodigoCnes` só quando `Tipo=SAUDE && !Virtual` — `Unidade.ProblemaInvariante()`, método puro cercado de teste. ⚠️ **TODO (fatia 3/7):** chamar `ProblemaInvariante()` em TODO write-path que cria/edita Unidade (ingestor + tela admin) — hoje unidade só nasce do seed, então a invariante ainda não é aplicada em runtime.
- **(II) ⏭️ diferida (fatia 5/6):** `Virtual ⇒ endereço irrelevante` — só faz sentido quando existir o campo `Endereco`.
- **(III) ✅ DECIDIDA (D-218, 2026-07-13) — unicidade GLOBAL entre unidades ativas:** a Unidade física (um CNES) é **COMPARTILHADA — UMA linha** vinculada a N clientes via `UnidadeClienteVinculo` (N:N, à la `DoctorVinculo`). Logo o `CodigoCnes` **não repete** entre unidades ativas ⇒ índice **único parcial** `UNIQUE(CodigoCnes) WHERE Ativo AND CodigoCnes NOT NULL` (unidades sem CNES não entram). Isso **reconcilia o D-207** (que sugeria unicidade por-cliente / "linhas distintas" — modelo anterior ao vínculo curado do D-216d): a multiplicidade agora vive no **vínculo**, não em linhas duplicadas.

## 4. Vínculo Unidade↔Cliente — EXPLÍCITO e **N:N** (D-216d + D-218)
A Unidade nasce da base pública; **quem é de qual cliente é curado** (admin/cliente seleciona), espelhando o `DoctorVinculo` (D-197). Nem todo CNES do estado é do cliente. **✅ N:N confirmado (D-218):** a Unidade é **compartilhada** — entidade **`UnidadeClienteVinculo`** (membership, à la `DoctorVinculo`/`PacienteTenantRef`), **não** `ClienteId` FK direto na Unidade. O `ClienteId` do agendamento segue **derivado** (via unidade + vínculo do operador); isolamento (D-206) inalterado.

## 4b. `Grupo` + gestão de unidades/grupos pelo cliente (D-219)
Espelha a hierarquia real da TC (`docs/discovery/08-healthcenter-unidades.md`): **`HealthCenter(cliente) › Grupo(opcional) › Unidade`**.
- **`Grupo`** (= `profile_tag_groups`): `Id`, `Nome`, `ClienteId`, `Ativo`. Agrupa unidades **dentro de um cliente**; **opcional** (unidade pode não ter grupo). A `Unidade` ganha `GrupoId?` (nullable).
- **CRUD nos dois níveis** (grupo E unidade): **listar · criar · editar · inativar** (soft, padrão D-143) **· excluir (hard) SÓ se nada vinculado** — unidade sem agendamento/vínculo; grupo sem unidade. **Invariante a cercar de teste:** excluir com vínculo → **bloqueado (fail-closed)**. Todo write-path chama `Unidade.ProblemaInvariante()` (resolve o TODO da fatia 1).
- **Papel — 🟡 PROVISÓRIO (D-219):** a gestão fica atrelada ao papel **`Demandas`** (plataforma, vê-tudo) por ora. Papel dedicado **"Gestor de Contrato"** (escopo = 1 cliente) é **direção futura**, não formaliza RBAC agora.

## 5. Impacto no agendamento (D-217)
- **Todo atendimento é EM uma Unidade** — o `Agendamento` passa a **referenciar a Unidade** (hoje `Unidade` é string solta → vira FK/relacionamento). "Todo paciente é atendido numa unidade."
- O `PreferencialAtendimento` da Unidade **pré-seleciona a modalidade** (presencial/remoto) ao criar o agendamento — **default overridável** caso a caso ⇒ `Agendamento` ganha `Modalidade`.
- **RNDS (D-217):** ao registrar o atendimento, sobe-se pro RNDS **em qual unidade** o paciente foi atendido → o **CNES da unidade** é obrigatório pra esse push (só p/ unidade de saúde física; refinar o push depois).

## 5b. Operador de Agendamento × Unidade = N:N (D-217)
Hoje o Operador é escopado a **1** unidade (claim `unidade` no token). Novo modelo:
- Vínculo **Operador↔Unidade** = **conjunto** de unidades (N:N) + flag **"ver todas"**.
- O operador **troca a "unidade atual"** num seletor (como o seletor de persona), agenda naquela; ou vê todas.
- **Isolamento preservado (D-206):** só vê/agenda nas SUAS unidades (ou todas, se marcado) — o `POST /agendamentos` valida a unidade contra o CONJUNTO do operador (não mais 1 claim).

## 5c. Estrutura da Unidade p/ capacidade/horário (D-217 — só estrutura agora)
A Unidade (física ou virtual) **é quem tem capacidade de atendimento + horário de funcionamento**. Agora só deixar a **estrutura** (campos/relacionamento) pronta — a lógica de capacidade/horário por unidade refina depois.

## 6. Fonte do CNES × carga inicial (D-215 + D-219 — revisto)
- **Fonte de verdade do CNES = base PÚBLICA** (DATASUS ou API oficial — **qual, decide na fatia 3**). Mantém o estabelecimento atualizado (job mensal). "Não podemos depender da Teleconsulta pra sempre."
- **`profile_tags` da TC = CARGA INICIAL (uma vez), NÃO fonte contínua** (D-219 **revisa o "sai" anterior**): faz o *bootstrap* de **quais** unidades já existem, de **qual cliente** (`health_center_id`), em **qual grupo** (`group_id`) e o **tipo** (`profile_tag_type`). Só pra "basear na realidade e começar as entregas"; depois o cliente cria as próprias.
- **Mapa `profile_tag_type` → (`TipoUnidade`, `NaturezaUnidade`)** (D-216): enum TC = 0 Undefined·1 Health·2 School·3 Prison·4 Admin·5 Municipality·6 Private. Sugestão (a confirmar): 1→Saúde+Público · 6→Saúde+Privado · 2→Escola · 3→Prisional · 4/5→Outros. **Não infere sem confirmar.**
- Pull contínuo da TC (D-212) segue com **doutor · paciente · cliente(HC)** (unidade **não** é fonte contínua).

## 7. Perguntas ainda abertas (não bloqueiam começar)
- **Quais `tipo_estab` do CNES contam como "atendimento"** (viram candidato a Unidade SAUDE)? Lista a confirmar (UBS/centro de saúde, hospital, policlínica, pronto-atendimento, consultório; excluir farmácia/laboratório/vigilância). — D-215 Q(a).
- ~~**Vínculo Unidade↔Cliente é 1:N ou N:N?**~~ → ✅ **N:N** (D-218; ver §4).
- **Params exatos da API DEMAS** (confirmar no Swagger) vs. optar pelo download DATASUS.

## 8. Fatias de construção (numa BRANCH; merge/deploy após validar)
Ordem por dependência + risco. Cada fatia: código + testes + gate, revisada antes da próxima.
1. ✅ **Modelo da `Unidade`** (feita, commit `33249ce`) — enums + campos + invariante I.
2. ✅ **Domínio `Cnes`** isolado (feita, commit `0d4aac8`) — entidade + migration + seed demo. Read-mostly via `DbSet` (sem repo — não é padrão da casa).
3. **Ingestor CNES + carga inicial** — (a) **fonte pública** (DATASUS **ou** API DEMAS — a decidir), filtro UF∈{PI,AM,AL} + tipos de atendimento, idempotente, job mensal, só-leitura, fonte fake nos testes; (b) **carga inicial** que lê `profile_tags`+`profile_tag_groups` da TC (pull RO existente, D-069/D-212) e semeia Unidades+Grupos+vínculo cliente (D-219), mapeando `profile_tag_type`→(Tipo,Natureza).
4. **`Grupo` + vínculos + N:N** — entidade `Grupo` (D-219) + `Unidade.GrupoId?`; **`UnidadeClienteVinculo` N:N** (D-218) + **índice único parcial** `UNIQUE(CodigoCnes) WHERE Ativo` (reset/reconcilia o seed do modelo 1:N antigo); **Operador↔Unidade N:N** (conjunto + "ver todas") ajustando o escopo do `POST /agendamentos`.
5. **`Agendamento` → `Unidade`** (referência) + **`Modalidade`** (default = preferencial, overridável). RNDS: exigir CNES da unidade de saúde (push depois).
6. **Estrutura de capacidade/horário na Unidade** (só campos/relacionamento; lógica depois).
7. **Gestão de unidades/grupos (telas + endpoints)** — CRUD grupo+unidade pelo cliente (D-219): listar/criar/editar/inativar/excluir-se-sem-vínculo; write-path chama `ProblemaInvariante()`. Admin cria Unidade a partir de um CNES; seletor de "unidade atual" do operador.

**Assuntos EM ABERTO (refinar depois — não bloqueiam a estrutura):** DATASUS vs API DEMAS (fatia 3); mapa `profile_tag_type`→(Tipo,Natureza); lista de `tipo_estab` do CNES que viram Unidade; capacidade/horário por unidade; push real pro RNDS; formalização do papel "Gestor de Contrato" client-scoped. _(1:N vs N:N: RESOLVIDO — N:N, D-218.)_

_Registrado 2026-07-13. Modelo confirmado pelo Alessandro (D-215/D-216/D-217/**D-218**/**D-219**). Fatias 1-2 feitas na branch `feat/cnes-unidade`. Meta: estrutura sólida do conceito de Unidade; refinar os abertos depois "e deixar perfeito"._
