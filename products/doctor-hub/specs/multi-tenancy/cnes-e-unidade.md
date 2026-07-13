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

**Invariantes:** (i) `CodigoCnes` só quando `Tipo=SAUDE && !Virtual`; (ii) `Virtual ⇒ endereço irrelevante` (e normalmente `PreferencialAtendimento=REMOTO`); (iii) um `CodigoCnes` pode ter no máx. 1 Unidade ativa (evita duplicar o estabelecimento).

## 4. Vínculo Unidade↔Cliente — EXPLÍCITO (D-216d)
A Unidade nasce da base pública; **quem é de qual cliente é curado** (admin/cliente seleciona), espelhando o `DoctorVinculo` (D-197). Nem todo CNES do estado é do cliente. (Reusar/estender o padrão de membership; entidade `UnidadeClienteVinculo` OU o `Cliente` na própria Unidade se for 1:N — a confirmar 1:N vs N:N.)

## 5. Impacto no agendamento
O `PreferencialAtendimento` da Unidade **pré-seleciona a modalidade** (presencial/remoto) ao criar o agendamento — overridável caso a caso. ⇒ `Agendamento` ganha `Modalidade` (default = a da unidade). *(Requisito novo: registrar no fluxo de assumir vaga.)*

## 6. Revê o D-212
A linha "**unidades ← `profile_tags` da TC**" do D-212 **sai** — unidade agora nasce do CNES público. O pull da TC (D-212) fica só com **doutor · paciente · cliente(HC)**.

## 7. Perguntas ainda abertas (não bloqueiam começar)
- **Quais `tipo_estab` do CNES contam como "atendimento"** (viram candidato a Unidade SAUDE)? Lista a confirmar (UBS/centro de saúde, hospital, policlínica, pronto-atendimento, consultório; excluir farmácia/laboratório/vigilância). — D-215 Q(a).
- **Vínculo Unidade↔Cliente é 1:N ou N:N?** (uma unidade pode servir mais de um cliente?)
- **Params exatos da API DEMAS** (confirmar no Swagger) vs. optar pelo download DATASUS.

## 8. Fatias de construção
1. **Enums + entidade `Unidade` estendida** (Tipo/Natureza/PreferencialAtendimento/Virtual/CodigoCnes) + migration.
2. **Domínio `Cnes`** (entidade + migration + repo read-mostly).
3. **Ingestor CNES** (fonte pública, filtro UF+tipo, job mensal, idempotente) — só-leitura.
4. **Vínculo Unidade↔Cliente** explícito + tela de admin (criar Unidade a partir de um CNES / vincular ao cliente).
5. **`Modalidade` no Agendamento** (default = preferencial da unidade, overridável no assumir vaga).
6. Testes por fatia (invariantes I-III + ingestão com fonte fake).

_Registrado 2026-07-13. Modelo confirmado pelo Alessandro (D-215/D-216)._
