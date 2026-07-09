# Design (proposta) — Normalização de identidade de PACIENTE de tenants legados

> **Status:** PROPOSTA (síntese de um painel de 3 lentes de arquitetura, 2026-07-09). NÃO decidida.
> Base factual: [`../discovery/04-integration-teleconsulta.md`](../discovery/04-integration-teleconsulta.md) §"REGRA DA REALIDADE" · D-069 (sync médico via banco) · D-185 (lookup por CPF, dormente).
> Objetivo (Alessandro): abstração que integre bases de usuários de tenants legados heterogêneos,
> adaptável a qualquer cadastro, normalizando identidades externas — resiliente e fácil de manter.

## 🎯 Recomendação consensual (as 3 lentes concordaram)

**On-demand + camada canônica de identidade — NÃO sync-jobs de paciente.**
- **Mecanismo = on-demand** (o `idbycpf` que já existe): resolver o paciente no **momento do agendamento**, por `(CPF, cliente)`. A TC **não tem endpoint de listar/exportar** paciente — não dá pra "sincronizar tudo" via API; e replicar a base inteira via banco (como no médico, D-069) é **desproporcional** (LGPD/minimização: paciente é referência pontual, não roster nuclear como o médico) e **não resolve** o débito de contas duplicadas, só o herda desatualizado.
- **Camada canônica magra** guarda só o **resultado da resolução** que o próprio fluxo provocou (nunca um espelho de pacientes): absorve o **N:N cliente** e o **débito de duplicação** como *dado*, não escondido.
- **Sem jobs periódicos, sem cache de longa duração de PII.**

## 🧬 Modelo canônico (Lente B)

```
PessoaCanonica 1─N ExternalPatientRef N─1 TenantSistema
                          └─N─1 Cliente(HC)
Cliente N─1 ClienteTenantDomain N─1 TenantSistema
```
- **PessoaCanonica** — pessoa física; **PK sintética (uuid)**, CPF como chave de negócio `UNIQUE` (PK sintética facilita o *merge* futuro do "cadastro único" da TC e um eventual CNS).
- **TenantSistema** — catálogo de sistemas de origem (`TELECONSULTA_CORE`) = "o tipo de adapter".
- **ClienteTenantDomain** — **substitui a config fixa** `TeleconsultaCoreOptions.ClientDomain`: por `(Cliente, Tenant)` → qual `PTM-Client-Domain` usar. (Hoje `Cliente.ExternalId` = health_center.id da TC, **≠** o domain string — gap confirmado.)
- **ExternalPatientRef** — `(pessoa, tenant, cliente, external_patient_id)`. **SEM** UNIQUE em `(pessoa, tenant, cliente)` → é aqui que o débito (mesmo CPF → N patient_id no mesmo domain) fica **representado**. UNIQUE em `(tenant, cliente, external_patient_id)` (um id externo → uma pessoa).
- **"Dormente" deixa de ser flag global** → vira "não há `ClienteTenantDomain` cadastrado p/ este cliente".
- **Cadastro único futuro da TC = merge de dados** (marca refs órfãs `duplicado_absorvido`), **sem migration de schema** (é o caso N=1 do mesmo modelo).

**Ports:** `IIdentityResolver` (orquestra, tenant-agnóstico) · `IExternalDirectoryAdapter` (1 por tenant — isola a heterogeneidade; onboarding de tenant = escrever 1 adapter + dados) · `IClienteTenantDomainResolver` (troca a config fixa). O `ITeleconsultaCoreClient` atual vira detalhe atrás do `TeleconsultaCoreDirectoryAdapter` (que recebe `domain` por chamada, não fixo).

## 🛡️ Resiliência + LGPD (Lente C)

- 🔴 **`ClientDomain` fixo é o gap mais urgente** — contradiz a regra da realidade; refatorar p/ por-cliente antes de expandir.
- 🔴 **Falta retry + circuit breaker** no lookup (GET idempotente → retry seguro; breaker p/ não martelar a TC caída; hoje é 8s de timeout cru por tentativa). Adicionar **throttle de saída** (rate-limit desconhecido, key compartilhada com SOSPortal prod).
- 🔴 **Multi-cliente:** o domain vem **sempre do contexto de negócio** (cliente da vaga), **nunca** "pra trás" do CPF; **nunca** fan-out automático em N domains "pra achar o paciente".
- 🟡 **CPF sujo:** normalizar (já faz); **"não encontrado" ≠ "não existe"** — não deixar a regra de negócio decidir "então cria" sozinha.
- **LGPD:** CPF/patient_id **nunca em log** (já ok, D-185); `pessoa_canonica.cpf`/`external_patient_ref` são **mais sensíveis que doutor** (D-098) → RBAC mais restrito; **nunca revelar a um Gestor que um paciente do cliente A também está no cliente B** (vazamento de vínculo entre clientes público/privado).

## ❓ Perguntas abertas (decisão de produto / TC — NÃO inferir)

**Produto (Alessandro):**
1. **Desempate de duplicata:** quando o CPF tem N patient_id, qual usar no agendamento? (mais recente? mais histórico? perguntar ao operador?)
2. **"Não encontrado" na TC:** criar cadastro (write na prod TC), bloquear, ou outro? (já 🟡 aberta; register adiado no D-185.)
3. **LGPD:** guardar CPF em claro vs hash na camada canônica? retenção? base legal? nível de RBAC de `pessoa_canonica`/`external_patient_ref`?
4. **Fonte do `PTM-Client-Domain` por cliente:** onde/quem cadastra o domain de cada cliente? (hoje inexiste no modelo.)
5. Existe paciente **só com CNS** (sem CPF)? Um cliente pode ter **>1 domain** no mesmo tenant?
6. Existe caso de uso real de **"descobrir em quais clientes um CPF está"**? (senão, não construir fan-out.)

**Equipe TC:** o `idbycpf` é **determinístico** (mesma conta sempre p/ mesmo CPF+domain)? **rate limit** da key SOSPortal (compartilhada?)? existe **staging**? a allowlist do `idbycpf` aceita **`PartnerType.SOSPortal`**?

## 🪜 Faseamento sugerido
- **Fase 0 (destrava já, sem depender das perguntas):** trocar `ClientDomain` fixo → resolvido **por cliente** (mesmo que via uma tabela/config simples de `cliente→domain`) + **retry/circuit-breaker/throttle** no lookup existente. Torna o lookup dormente *correto* p/ multi-cliente.
- **Fase 1 (após respostas de produto):** camada canônica (`pessoa_canonica` + `external_patient_ref` + ports/adapters), desempate de duplicata, RBAC/retenção.
