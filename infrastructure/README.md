# infrastructure/ — Produção da plataforma (IaC)

> ⚠️ **NÃO APLICAR sem decisão aprovada.** Este diretório é o **plano + esqueleto de IaC** para subir
> o **portal-identity (Keycloak)** em produção no **GCP pessoal** (estratégia: construir pessoal →
> repassar à empresa com cessão de IP). Decisão: **P-006** (`../docs/decisions/platform-decisions.md`).
> Nada vai para o ar até você rodar os passos abaixo conscientemente. Constituição: *nada de
> deploy/produção sem decisão registrada*.

## 1. Arquitetura alvo (1ª fatia: só identidade)

```
            Internet (HTTPS)
                  │
        ┌─────────▼──────────┐     min=max=1 instância
        │  Cloud Run          │     (cache Infinispan simples)
        │  portal-identity    │     imagem: Keycloak 26 + providers + tema
        │  (Keycloak)         │     kc.sh start --optimized
        └─────────┬──────────┘
                  │ socket /cloudsql/<conn> (SocketFactory, sem IP público)
        ┌─────────▼──────────┐
        │  Cloud SQL          │     PostgreSQL 16 (persistente; backup + PITR)
        │  portal-identity-pg │
        └────────────────────┘
   Secret Manager: senha do DB + senha admin (geradas pelo Terraform)
   Artifact Registry: a imagem de prod do Keycloak
```

Estende o baseline da plataforma (P-001/P-003): **.NET/React/GCP — Cloud Run + Cloud SQL + Secret
Manager**. Doctor-Hub (api/web) entra **depois**, em fatias próprias (strangler-fig — não big-bang).

## 2. O que muda do DEV (gap a fechar)

| DEV (docker-compose) | PROD (este IaC) |
|---|---|
| `start-dev` + **H2 em memória** | `start --optimized` + **Cloud SQL** |
| realm **re-importado a cada boot** | realm importado **uma vez** (ver §6) |
| `network_mode: host` | Cloud Run (HTTPS + `KC_HOSTNAME` + proxy headers) |
| seed users + **senha DEV** no JSON | **realm de prod LIMPO** (sem seeds, sem PII no git) — LGPD |
| admin via `.env` | **Secret Manager** |
| provider/tema por **volume** | **embutidos na imagem** (`kc.sh build`) |
| **OTP modo DEV** (código no log) | **SMTP/SMS reais** (I-003 pendente — ver §9) |

## 3. Pré-requisitos (uma vez)

1. **gcloud no projeto pessoal** (hoje a máquina está logada na conta da EMPRESA — trocar!):
   ```bash
   gcloud auth login                 # conta pessoal: alessandro@garbiati.com
   gcloud config set project portal-tecnologia
   gcloud auth application-default login   # credencial p/ o Terraform
   ```
2. **Billing ativo** no projeto pessoal (crédito R$1.727 até 28/09/2026).
3. **Terraform >= 1.6** e **Docker** instalados.
4. (Recomendado) **bucket de state** privado+versionado e migrar o backend (ver §7).

## 4. Passo-a-passo do deploy (quando aprovado)

```bash
# (a) build + push da imagem de prod do Keycloak (contexto = o repo portal-identity)
cd ../services/portal-identity
gcloud auth configure-docker southamerica-east1-docker.pkg.dev
docker build -t southamerica-east1-docker.pkg.dev/portal-tecnologia/portal-identity/keycloak:1.0.0 .
# (o repo do Artifact Registry é criado pelo Terraform no passo b; rode o `terraform apply` p/ os
#  recursos-base ANTES do push, ou crie o repo primeiro com -target=google_artifact_registry_repository.images)
docker push southamerica-east1-docker.pkg.dev/portal-tecnologia/portal-identity/keycloak:1.0.0

# (b) provisiona a infra
cd ../../infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars   # preencha project_id, keycloak_image
terraform init
terraform apply        # 1º apply: cria SQL, secrets, AR, Cloud Run (hostname ainda vazio)

# (c) pega a URL e fixa o hostname (Keycloak exige KC_HOSTNAME coerente)
terraform output keycloak_url
#  → coloque o host em terraform.tfvars (keycloak_hostname) e:
terraform apply

# (d) importa o realm de PRODUÇÃO (ver §6) e faz o smoke test (§8)
```

> Ordem de imagem × infra: o repositório do Artifact Registry é um recurso do Terraform. Para o 1º
> push, crie só ele antes (`terraform apply -target=google_artifact_registry_repository.images`),
> faça o push, e então o `apply` completo. Está anotado no passo (a).

## 5. Segredos

- **Gerados pelo Terraform** e guardados no **Secret Manager**: senha do Cloud SQL e senha do admin
  bootstrap. Leia a do admin com:
  ```bash
  gcloud secrets versions access latest --secret=portal-identity-admin-password
  ```
- **Nunca** há segredo no git nem no `terraform.tfvars` (só identificadores). O `tfstate` **contém**
  segredos (senha gerada) → fica fora do git e, idealmente, em bucket privado (§7).
- **SMTP/SMS** (envio real do OTP) entram como **novos secrets** quando a fatia I-003-real começar.

## 6. Realm de produção (LIMPO)

O `realms/portal-realm.json` do DEV **não serve** para prod (tem seed users com senha DEV e
redirect URIs `localhost`). Estratégia de prod:
- Derivar um **realm de prod** com: clients (`doctor-hub-web`/`doctor-hub-api`), client roles, flows
  (`browser-otp`, providers CPF/telefone+OTP), tema `portal`, `sslRequired: all`, **sem usuários**,
  redirect/webOrigins/`KC_HOSTNAME` apontando para o **domínio de prod**.
- **Importar uma vez** (não a cada boot): via `kc.sh import` num job, ou Admin API após o 1º boot.
  Usuários reais são criados depois (Admin API / console) — **LGPD**: realm de prod ≠ realm de dev.
- ➡️ Este arquivo de realm-prod **ainda não foi commitado** de propósito: depende do **hostname**
  definido no §4(c) e é regra sensível (não inferir). Vira uma sub-fatia do deploy.

## 7. Estado do Terraform (state)

Comece local; migre para **GCS** assim que possível (o state tem segredos):
```bash
gsutil mb -l southamerica-east1 -b on gs://portal-tecnologia-tfstate
gsutil versioning set on gs://portal-tecnologia-tfstate
# descomente o backend "gcs" em versions.tf e rode: terraform init -migrate-state
```

## 8. Smoke test (pós-deploy)

- `GET https://<host>/health/ready` → 200.
- `GET https://<host>/realms/portal/.well-known/openid-configuration` → JSON.
- Login E2E (como no DEV): identificador → senha; e "tentar outra forma" → código (com **SMTP/SMS
  real**, não log).

## 9. Perguntas abertas / pré-condições (NÃO INFERIR)

- 🔴 **OTP real antes de prod:** produção não pode depender de "código no log". Plugar **SMTP** +
  **gateway SMS** (I-003-real) é pré-condição p/ o caminho de código. Senha funciona sem isso.
- 🟡 **Domínio próprio** (ex.: `id.portal…`) vs URL `*.run.app`: define `KC_HOSTNAME`, redirect URIs
  e o realm de prod. Começar com `*.run.app` e migrar depois é aceitável.
- 🟡 **IP/cessão:** infra/segredos em nome pessoal; formalizar a cessão no repasse à empresa.
- 🟢 **HA:** hoje `min=max=1` (cache simples). Escalar exige cache distribuído (Infinispan) + Cloud
  SQL `REGIONAL`. Só quando o tráfego justificar.
- 🟢 **Backup/retention** do Cloud SQL: ajustar política conforme exigência.

## 10. Reversão

`terraform destroy` remove tudo **exceto** o Cloud SQL (tem `deletion_protection = true` — desligar
manualmente antes, de propósito, para não dropar o banco de identidade por engano).
