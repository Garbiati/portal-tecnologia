---
id: SPEC-MULTI-TENANCY
title: Multi-tenancy e visibilidade de dados — identidade compartilhada, acesso escopado e configurável
status: draft            # draft | specified | tested | implemented
owner: Alessandro
area: Acesso
clickup: ""
figma: ""
validated_by: ""         # preenchido quando humano confirma (status: specified)
validated_at: ""
last_update: 2026-07-11
---

# Multi-tenancy e visibilidade de dados

> **Fundação de tenancy do Doctor-Hub.** Consolida D-197 (fundação) · D-198 (plataforma compartilhada
> por vínculo) · D-199 (hierarquia + N:N) · D-200 (identidade ≠ acesso) · D-201 (visibilidade
> configurável + fila unificada). Generaliza o EMPI (D-191). **É pré-requisito** de SPEC-AGENDAMENTO-
> RESILIENTE (o pull+ack escopa por aqui) e do SALDO (D-190).
> **Rascunho — construção é DEPOIS da demo de segunda.** Os cenários da seção 4 são os **guardrails de
> regressão** (viram teste antes do código). Enquanto houver 🔴 na seção 8, não vira `specified`.

## 1. Problema / Dor  _(Definition of Success)_

- **Dor:** a plataforma quer ser uma **base compartilhada de médicos e pacientes** (as mesmas pessoas
  atendem/são atendidas em vários tenants), mas **vazar dado de um tenant para outro é o pior risco**
  (LGPD, saúde). Hoje não há discriminador de tenant nas linhas, `Unidade` é string, e a visibilidade
  não é modelada — não dá pra abrir o compartilhamento com segurança.
- **De quem:** o médico (que atende N tenants), o paciente (que está em N tenants), e o negócio (que só
  pode compartilhar dado se conseguir provar isolamento).
- **Sucesso = quando:** a mesma pessoa opera/existe em vários tenants **sem nunca** ver, por acidente,
  dado de um tenant a que não tem acesso — e visibilidade cruzada legítima **só** acontece quando
  **explicitamente concedida**.

## 2. Função  _(o "o quê")_

- **Identidade compartilhada:** `Médico` e `Paciente` são **entidades de plataforma** com **ID único de
  sistema** (golden record — EMPI/D-191). Uma pessoa = um registro canônico.
- **Hierarquia de tenancy:** `Tenant` (plataforma white-label) › `Cliente` (HC/governo) › `Unidade`.
- **Vínculo (membership) N:N:** a pessoa canônica se liga à hierarquia por **vínculos**, em **qualquer
  nível** (N tenants, N clientes, N unidades). O vínculo diz **onde ela PODE atuar**.
- **Acesso ≠ identidade:** o golden record resolve "é a mesma pessoa"; **o acesso é sempre escopado** e
  **configurável** (default-deny + grants). Ser a mesma pessoa **não** é ponte de acesso.
- **Fila unificada:** o médico atende as unidades vinculadas **sem trocar de contexto** (um paciente de
  uma unidade pode cair com um médico de outra, se disponível e permitido).

## 3. Regras de negócio  _(somente CONFIRMADAS)_

- ✅ **Médico e Paciente são de plataforma, com ID único (golden record).** — _D-198/D-191_
- ✅ **Hierarquia `Tenant › Cliente › Unidade`; vínculo N:N em qualquer nível.** — _D-199_
- ✅ **Identidade compartilhada NÃO concede acesso.** A pessoa é a mesma em N tenants, mas isso, por si
  só, não deixa ver dado de nenhum. — _D-200_
- ✅ **Default-deny.** Por padrão não se vê nada fora do escopo permitido. — _D-201_
- ✅ **Visibilidade cruzada só por GRANT explícito, auditável e por propósito** (ex.: privado com
  permissão do SUS vê o SUS como complemento do diagnóstico; SUS-puro nunca vê o privado). — _D-201_
- ✅ **Contenção de escopo:** o dado tem um dono na hierarquia; um vínculo/grant cobre o dono se o
  contém (vínculo no Cliente cobre suas Unidades; no Tenant cobre tudo abaixo; só na Unidade cobre só
  ela). — _D-199_
- ✅ **Fila unificada entre unidades vinculadas** (sem troca de contexto), respeitando a visibilidade. — _D-201_
- ✅ **Dois eixos de permissão distintos:** RBAC de **ação** (`capabilities.yml`/D-187 — "pode fazer X")
  × **visibilidade de dado** ("pode ver o registro Y"). — _D-201_
- ✅ **Discriminador de tenant explícito por linha** (ex.: `Agendamento.ClienteId`), carimbado na
  criação — não derivado por join na hora da query. — _D-197_
- ✅ **Vaga só é agendável a um cliente se o doutor estiver VINCULADO àquele cliente** (gate de
  elegibilidade, ANTES do saldo). Um agendamento é sempre de um cliente, para um paciente daquele
  cliente, com um doutor vinculado — consistência tri-vínculo. — _D-202_
- ✅ **Dois gates de capacidade distintos:** VÍNCULO (elegibilidade, D-202) × SALDO (`min(pool,teto)`,
  D-190). Vínculo primeiro; saldo é fase própria posterior. — _D-202_

## 4. Critérios de aceite  _(os GUARDRAILS DE REGRESSÃO — viram teste antes do código)_

```gherkin
Cenário: default-deny — sem vínculo, não vê
  Dado um médico SEM vínculo com o tenant "T-B"
  Quando ele consulta agendamentos
  Então nenhum agendamento de "T-B" aparece

Cenário: identidade compartilhada não vaza entre tenants
  Dado que a MESMA pessoa (mesmo golden record) atua em "T-A" e "T-B"
  E ela está operando dados de "T-A"
  Então nenhum dado de "T-B" aparece por ser "a mesma pessoa"

Cenário: fila unificada dentro do escopo vinculado
  Dado um médico vinculado às unidades "U1" e "U2"
  Quando ele abre a fila
  Então vê a fila unificada de "U1" e "U2"
  E não vê a fila de "U3" (não vinculada)

Cenário: paciente de uma unidade cai com médico de outra vinculada
  Dado um paciente com solicitação na unidade "U1"
  E um médico disponível vinculado a "U1" e "U2"
  Então o médico pode assumir o atendimento desse paciente

Cenário: vaga só aparece para o cliente se o doutor está vinculado (D-202)
  Dado o Doutor A e o Doutor B, ambos cardiologistas
  E o cliente "Piauí" com apenas o Doutor A vinculado
  E o Doutor B com vagas disponíveis
  E o "Piauí" com saldo positivo de cardiologia
  Quando o "Piauí" busca vagas de cardiologia para agendar
  Então vê as vagas do Doutor A
  E NÃO vê as vagas do Doutor B (não vinculado) — nem com saldo positivo
  Quando o Doutor B é vinculado ao "Piauí"
  Então as vagas do Doutor B passam a aparecer para o "Piauí"

Cenário: vínculo é gate ANTES do saldo
  Dado um doutor NÃO vinculado ao cliente
  Então nenhuma vaga dele é agendável para o cliente
  Independentemente de o cliente ter saldo de capacidade

Cenário: grant explícito abre visibilidade cruzada (assimétrico)
  Dado um médico do PRIVADO com grant para ver o SUS de um paciente (complemento de diagnóstico)
  Quando ele abre o registro desse paciente
  Então vê os dados do SUS daquele paciente
  E um médico só do SUS NUNCA vê os dados do privado desse paciente

Cenário: contenção de escopo (hierarquia)
  Dado um médico com vínculo no Cliente "C1"
  Então ele alcança dados de todas as Unidades de "C1"
  E um médico com vínculo só na Unidade "U1" alcança só "U1"

Cenário: discriminador obrigatório — query sem tenant permitido é fail-closed
  Dada uma consulta cujo escopo de tenant não pôde ser resolvido
  Então o resultado é vazio (nunca "todos") — falha fechada

Cenário: todo acesso cruzado é auditável
  Quando um grant é usado para ver dado de outro escopo
  Então o acesso é registrado na trilha de auditoria (quem, o quê, quando, propósito)
```

## 5. Definition of Done

- [ ] Todos os cenários da seção 4 passam como teste automatizado (xUnit) — são os guardrails de regressão
- [ ] `Unidade` é entidade (`ClienteId` FK); `Agendamento` (e demais linhas tenant-owned) têm discriminador
- [ ] Isolamento na camada baixa (EF Core global query filter por escopo permitido)
- [ ] Vínculos N:N (à la EMPI) para Médico (e Paciente); política de visibilidade (grants) separada do RBAC de ação
- [ ] Trilha de auditoria de todo acesso cruzado
- [ ] Sem 🔴 pendente; validado por humano

## 6. Fora de escopo

- **Provisionamento de credencial de cliente** (service account/API key) — onboarding (humano), ver D-196.
- **Endpoints pull+ack** — vivem em SPEC-AGENDAMENTO-RESILIENTE; dependem desta fundação.
- **Saldo (pool × teto)** — D-190; usa a hierarquia daqui mas é spec própria.

## 7. Dependências & Integrações

- **EMPI (D-191)** — o padrão canônico+ref que esta spec generaliza ao médico.
- **RBAC de ação (D-187, `capabilities.yml`)** — coexiste; a visibilidade de dado é um eixo separado.
- **SPEC-AGENDAMENTO-RESILIENTE / SALDO (D-190)** — consomem esta fundação.

## 8. Perguntas abertas  _(NÃO INFERIR — perguntar; discovery da fase)_

- ✅ **RESOLVIDO (D-204) — Modelo do grant:** HÍBRIDO — política de elegibilidade (quem pode pedir) +
  acesso por relação de cuidado (break-glass, só para paciente atendido, por propósito) + auditoria.
- ✅ **RESOLVIDO no DESIGN (D-205) — Base legal LGPD:** projetar para suportar as DUAS bases (sempre
  cuidado+propósito+auditoria; registrar consentimento quando aplicável; política configurável decide o
  que é obrigatório). Modelo permite acordo/consentimento por par de tenants e/ou por paciente
  (controladores distintos SUS × privado).
- 🔴 **PENDENTE do DPO/jurídico (processo, não bloqueia o design):** validar a base legal final,
  necessidade de acordo entre controladores e de RIPD — ANTES de produção.
- 🟡 **Granularidade da política** (tenant/cliente/paciente/tipo-de-dado); quem concede/revoga
  elegibilidade + expiração. _(design — dá pra fechar sem jurídico)_
- ✅ **RESOLVIDO (D-203) — Cascata de vínculo:** sim, cascata com estreitamento opcional (vínculo no
  Cliente cobre suas Unidades; pode restringir a específicas).
- ✅ **RESOLVIDO (D-203) — Pool × dedicada:** pool (sem `ClienteId`) = disponível aos clientes vinculados
  do doutor; dedicada (com `ClienteId`) = reservada àquele cliente.
- ✅ **RESOLVIDO (D-203) — Migração:** recomeçar do seed (recadastrar unidades como entidades); revisitar
  com mapear+backfill se um dia houver dado real.
- 🟡 **Quem concede/revoga grant** e como se audita; expiração do grant.
- 🟡 **Login do papel Doutor** (hoje não loga) — como entra no contexto e enxerga a fila unificada.
- 🟢 **Migração do legado:** `Agendamento.Unidade` (string) → `UnidadeId`; agendamentos existentes.

### 8b. Decisões de ROLLOUT (achados dos revisores no Lote 4 — decidir ANTES do merge à prod, pós-demo)
- 🔴 **Consistência claim `unidade` ↔ Unidade cadastrada:** a claim `unidade` do Gestor no Keycloak é
  texto livre; com o fail-closed do Lote 4, uma unidade não cadastrada trava o Gestor (403 ao criar,
  lista vazia ao ler). No seed está resolvido (as 10 unidades dos 5 clientes existem). **Para prod real:**
  ou (a) as unidades reais são todas cadastradas e as claims batem os `Codigo`, ou (b) o cadastro de
  usuário valida a claim contra a tabela `Unidade`. Decisão do Alessandro.
- 🔴 **Backfill dos agendamentos legado (`ClienteId` null):** a coluna `ClienteId` nasceu no Lote 2 sem
  backfill — agendamentos criados antes (ou por vê-tudo sem unidade/solicitação) ficam `ClienteId` null
  e **somem para papéis escopados** quando o filtro sobe (só vê-tudo os vê). Antes do merge à prod:
  **backfill** (derivar de Unidade/Solicitação) OU aceitar o reset (coerente com "recomeçar do seed",
  D-203, se o dado é de demo). Decisão do Alessandro.
- 🟡 **Regulação no GET /agendamentos** (pré-existente, não é regressão do Lote 4): o GET filtra só pela
  claim `unidade`; Regulação (escopada por `clienteId`, sem `unidade`) nunca vê agendamento por ali.
  Confirmar se Regulação deve enxergar agendamentos e por qual eixo.
