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
- **(III) 🔴 PERGUNTA ABERTA — NÃO inferir (revisor-engenharia pegou conflito com D-207):** um `CodigoCnes` pode repetir entre Unidades? **D-207 já decidiu que "CNES NÃO é único por-linha" (o mesmo CNES sob clientes distintos, IDs distintos)** — a identidade por-linha é `Codigo`. Então a ideia de "1 Unidade ativa por CNES" **contradiz D-207 e fica em aberto**: unicidade do CNES é por-linha (não — D-207 atual), por-cliente, ou global entre unidades ativas? Decide o índice do banco e o dedup. **Confirmar com o humano antes da fatia 2/4.**

## 4. Vínculo Unidade↔Cliente — EXPLÍCITO (D-216d)
A Unidade nasce da base pública; **quem é de qual cliente é curado** (admin/cliente seleciona), espelhando o `DoctorVinculo` (D-197). Nem todo CNES do estado é do cliente. (Reusar/estender o padrão de membership; entidade `UnidadeClienteVinculo` OU o `Cliente` na própria Unidade se for 1:N — a confirmar 1:N vs N:N.)

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

## 6. Revê o D-212
A linha "**unidades ← `profile_tags` da TC**" do D-212 **sai** — unidade agora nasce do CNES público. O pull da TC (D-212) fica só com **doutor · paciente · cliente(HC)**.

## 7. Perguntas ainda abertas (não bloqueiam começar)
- **Quais `tipo_estab` do CNES contam como "atendimento"** (viram candidato a Unidade SAUDE)? Lista a confirmar (UBS/centro de saúde, hospital, policlínica, pronto-atendimento, consultório; excluir farmácia/laboratório/vigilância). — D-215 Q(a).
- **Vínculo Unidade↔Cliente é 1:N ou N:N?** (uma unidade pode servir mais de um cliente?)
- **Params exatos da API DEMAS** (confirmar no Swagger) vs. optar pelo download DATASUS.

## 8. Fatias de construção (numa BRANCH; merge/deploy após validar)
Ordem por dependência + risco. Cada fatia: código + testes + gate, revisada antes da próxima.
1. **Modelo da `Unidade`** — enums `TipoUnidade`/`NaturezaUnidade`/`Modalidade` + campos (Tipo/Natureza/PreferencialAtendimento/Virtual/CodigoCnes) + migration. Invariantes I–III.
2. **Domínio `Cnes`** (isolado) — entidade + migration + repo read-mostly.
3. **Ingestor CNES** — fonte pública (API DEMAS ou download DATASUS), filtro UF∈{PI,AM,AL} + tipos de atendimento, idempotente, job mensal. Só-leitura. Testado com fonte fake.
4. **Vínculo Unidade↔Cliente** explícito (curado) + **Operador↔Unidade N:N** (conjunto + "ver todas") — o modelo de membership (D-217). Ajusta o escopo do `POST /agendamentos` (valida contra o conjunto de unidades do operador, não 1 claim).
5. **`Agendamento` → `Unidade`** (referência) + **`Modalidade`** (default = preferencial da unidade, overridável no assumir vaga). RNDS: exigir CNES da unidade de saúde (push depois).
6. **Estrutura de capacidade/horário na Unidade** (só campos/relacionamento; lógica depois).
7. **Telas** — admin cria Unidade a partir de um CNES + vincula ao cliente; seletor de "unidade atual" do operador.

**Assuntos EM ABERTO (refinar depois — não bloqueiam a estrutura):** lista de `tipo_estab` do CNES que viram Unidade; capacidade/horário por unidade; push real pro RNDS; params exatos da API DEMAS vs download; 1:N vs N:N no Unidade↔Cliente.

_Registrado 2026-07-13. Modelo confirmado pelo Alessandro (D-215/D-216/D-217). Meta: estrutura sólida do conceito de Unidade; refinar os abertos depois "e deixar perfeito"._
