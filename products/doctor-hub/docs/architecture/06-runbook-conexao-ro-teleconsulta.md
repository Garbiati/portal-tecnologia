---
title: Runbook — conexão READ-ONLY do Doctor-Hub ao banco da Teleconsulta
status: living
date: 2026-07-15
rastreabilidade: D-069, D-225, D-226, D-227
público: time de infra da Portal Telemedicina
---

# 06 — Runbook: ligar o Doctor-Hub ao banco da Teleconsulta (READ-ONLY)

> **Para quem tem acesso ao GCP da Teleconsulta** (infra da Portal). O Doctor-Hub roda no Cloud Run
> do projeto `portal-tecnologia-500920`; a Teleconsulta é **outro projeto/GCP**. Este runbook liga os
> dois **read-only** (D-069) pra a sync refletir a TC no homolog. **Nada aqui roda na máquina do
> Alessandro** — são ações no GCP da Portal + no Terraform do Doctor-Hub.

## Conceito (por que funciona entre GCPs diferentes)
O **Cloud SQL Auth Proxy** conecta numa instância pelo `connection name` (`projeto:regiao:instancia`)
e autentica por um **service account** com `roles/cloudsql.client` **naquele projeto**. IAM é
cross-project — um SA do `portal-tecnologia-500920` pode receber papel no projeto da Teleconsulta
(mesmo em outra org/billing). **Não precisa VPC peering nem IP público.**

## Valores que preciso de vocês (preencher os `<...>`)
- `<TC_PROJECT>` — id do projeto GCP da Teleconsulta.
- `<TC_CONN>` = `<TC_PROJECT>:<TC_REGION>:<TC_INSTANCE>` — connection name da instância Cloud SQL da TC.
- `<TC_DB>` — nome do database (ex.: `teleconsulta_core`).
- `<HUB_RUNTIME_SA>` — o service account de RUNTIME do Cloud Run do doctor-hub-api (o que o serviço
  USA em runtime; confirmar no console do Cloud Run → doctor-hub-api → Security). *(O deploy usa
  `github-deployer@portal-tecnologia-500920.iam.gserviceaccount.com`, mas o de RUNTIME pode ser outro.)*

## Passo 1 — usuário Postgres READ-ONLY dedicado (no banco da TC)
Least-privilege (D-069): SELECT SÓ nas tabelas que a sync lê. Rodar no banco da Teleconsulta:
```sql
CREATE ROLE doctorhub_ro LOGIN PASSWORD '<senha-forte>';
GRANT CONNECT ON DATABASE <TC_DB> TO doctorhub_ro;
GRANT USAGE ON SCHEMA public TO doctorhub_ro;
-- só as tabelas usadas pela reflexão (clientes/unidades/grupos/pacientes/doutores):
GRANT SELECT ON
  health_centers, health_center_cep_coverage, health_center_allowed_states,
  profile_tags, profile_tag_groups,
  patient_profiles, health_center_patient_profiles,
  doctor_profiles, health_center_doctor_profiles, users, people, doctor_profile_licenses
TO doctorhub_ro;
-- (ajustar a lista aos nomes reais; nada de INSERT/UPDATE/DELETE)
```
Guardar a senha (vai pro Secret Manager no passo 4).

## Passo 2 — grant cross-project (no projeto da TC)
Dar ao SA de runtime do doctor-hub o papel de cliente Cloud SQL **no projeto da TC**:
```bash
gcloud projects add-iam-policy-binding <TC_PROJECT> \
  --member="serviceAccount:<HUB_RUNTIME_SA>" \
  --role="roles/cloudsql.client"
```

## Passo 3 — anexar a instância TC ao Cloud Run do doctor-hub (Terraform)
No Terraform do doctor-hub-api, adicionar `<TC_CONN>` às instâncias Cloud SQL do serviço (junto da
instância própria que já existe). No `gcloud run services update` equivale a:
```
--add-cloudsql-instances=<HUB_OWN_CONN>,<TC_CONN>
```
Isso faz o proxy expor a TC no socket `/cloudsql/<TC_CONN>` dentro do container.

## Passo 4 — connection string RO no Secret Manager
Criar um secret (ex.: `sync-teleconsulta-ro-dsn`) com a connection string **Npgsql** via socket do
proxy. A base é:
```
Host=/cloudsql/<TC_CONN>;Username=doctorhub_ro;Database=<TC_DB>
```
…e acrescentar o **parâmetro de senha do Npgsql** com a senha do `doctorhub_ro` do passo 1. **A DSN
completa (com a senha) fica SÓ no Secret Manager** — nunca em doc/repo/código.
E ligar a sync (env do Cloud Run, apontando pro secret):
```
Sync__Teleconsulta__Enabled=true
Sync__Teleconsulta__TeleconsultaConnectionString=<secret sync-teleconsulta-ro-dsn>
Sync__Teleconsulta__Ufs=PI,AM,AL     # opcional; vazio = todas
```

## Passo 5 — o resto é comigo (Claude/Alessandro)
Com os passos 1-4 prontos:
1. **Valido as queries** PROVISÓRIAS (cliente/unidade-grupo/paciente/doutor) contra o schema real da TC (SELECTs read-only) — ajusto nomes de coluna/join se divergir.
2. **Deploy** dos commits (cliente + unidade/grupo + paciente + endpoint refletir-tudo).
3. `POST /api/admin/carga-teleconsulta/refletir-tudo` → reflete a TC ponta-a-ponta (cliente→unidade→paciente).
4. Homologação.

## ⚡ Atalho (primeira carga SEM tocar o Cloud Run)
Se quiserem homologar antes de montar o cross-project no Cloud Run: rodar o **cloud-sql-proxy local**
(ou um **Cloud Run Job** one-shot) com o SA + `<TC_CONN>` + o banco de homolog do doctor-hub, e
disparar o `/refletir-tudo` a partir dali. A sync é idempotente — depois monta-se o caminho de
produção (passos 3-4) com calma.

## Segurança (não relaxar — D-069 / baseline)
- **Só SELECT** na TC; o role `doctorhub_ro` não tem escrita.
- Senha/DSN **só no Secret Manager**, nunca no código/repo.
- A sync nasce **desligada** (`Enabled=false`); só liga com o secret configurado.
- Escrita na TC (push, direção Hub→TC) é **outro fluxo**, guardado à parte (ver `05-sync-bidirecional.md` §4) — este runbook é só a leitura.
