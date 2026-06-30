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

## 4. Runbook do deploy — IdP-only (D-143; executar nesta ordem)

> Escopo: **só o Keycloak (IdP)**. Validadores testam login (senha/CPF/telefone/OTP e-mail+SMS),
> reset de senha, tema e o **account console** contra a produção. terraform já instalado? senão:
> `curl -fsSL -o tf.zip https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip && unzip tf.zip -d ~/.local/bin`.
> `REGIAO=southamerica-east1`, `PROJ=portal-tecnologia`, `AR=$REGIAO-docker.pkg.dev/$PROJ/portal-identity`.

**0) Autenticar na conta PESSOAL** (você roda — é interativo):
```bash
gcloud auth login                                   # alessandro@garbiati.com
gcloud config set project portal-tecnologia
gcloud auth application-default login                # credencial p/ o Terraform
gcloud services enable secretmanager.googleapis.com  # p/ criar os secrets manuais a seguir
```

**1) Pré-requisitos do Gmail SMTP:** ative a **verificação em 2 etapas** na sua conta Google e gere
uma **Senha de app** (Conta Google → Segurança → Senhas de app) — 16 caracteres.

**2) Criar os 2 secrets MANUAIS** (valores nunca vão pro git/Terraform):
```bash
printf '%s' 'SUA_SENHA_DE_APP_GMAIL' | gcloud secrets create portal-identity-smtp-password --data-file=-
printf '%s' 'SEU_TWILIO_AUTH_TOKEN'  | gcloud secrets create portal-identity-twilio-token  --data-file=-
```

**3) Variáveis (sem segredos):**
```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
#  edite: project_id, smtp_from (seu gmail), twilio_account_sid, twilio_from (+E.164),
#         keycloak_image = "<AR>/keycloak:1.0.0"
~/.local/bin/terraform init
```

**4) Criar só o Artifact Registry (p/ o push da imagem):**
```bash
~/.local/bin/terraform apply -target=google_artifact_registry_repository.images
```

**5) Build + push da imagem (contexto = repo portal-identity; já embute realm-prod + providers + tema):**
```bash
cd ../../services/portal-identity
gcloud auth configure-docker $REGIAO-docker.pkg.dev
docker build -t $AR/keycloak:1.0.0 .
docker push $AR/keycloak:1.0.0
```

**6) Provisionar tudo (Cloud SQL + secrets gerados + Cloud Run):**
```bash
cd ../../infrastructure/terraform
~/.local/bin/terraform apply
KC_URL=$(~/.local/bin/terraform output -raw keycloak_url); echo "$KC_URL"
```

**7) Domínio próprio `id.portaltecnologia.app.br`** (recomendado — URL e TLS reais):

> Esquema de domínios: **`portaltecnologia.app.br`** = plataforma (IdP/APIs por subdomínio →
> `id.` p/ o IdP, `api.` p/ a API depois); **`doctorhub.app.br`** = o **site** (front Doctor-Hub).
```bash
# (a) verifique a posse do domínio da PLATAFORMA no Google (abre o navegador; TXT de verificação):
gcloud domains verify portaltecnologia.app.br   # ou no Search Console (TXT em portaltecnologia.app.br)
# (b) já está no tfvars: keycloak_domain="id.portaltecnologia.app.br". Aplique p/ criar o domain mapping:
~/.local/bin/terraform apply
# (c) pegue os registros DNS e cadastre-os no registro.br p/ o host id.portaltecnologia.app.br:
~/.local/bin/terraform output dns_records_dominio
#     (normalmente um CNAME id → ghs.googlehosted.com, ou A/AAAA — use exatamente o que vier)
```
Depois aguarde a propagação do DNS + o **certificado TLS gerenciado** (pode levar de minutos a ~1h).
A `KC_HOSTNAME` já fica `https://id.portaltecnologia.app.br` (do `keycloak_domain`). O site Doctor-Hub
(`doctorhub.app.br`) é configurado quando o front for deployado (já consta como `front_base_url`).

> ⚠️ **Domain mapping** do Cloud Run pode não estar disponível em toda região; se o `apply` recusar em
> `southamerica-east1`, a alternativa é um **Load Balancer + cert gerenciado** (te passo o ajuste). Sem
> domínio, dá pra validar já pela URL `*.run.app` (output `keycloak_url`).

**8) Criar o 1º admin (você) + convite, e validar:**
```bash
cd ../..   # raiz do repo
KC_URL="$KC_URL" ADMIN_NOME="Alessandro Garbiati" ADMIN_EMAIL="voce@gmail.com" \
  ADMIN_CPF=00000000000 ADMIN_TELEFONE=11999999999 \
  bash infrastructure/scripts/criar-admin-prod.sh
KC_URL="$KC_URL" bash infrastructure/scripts/smoke-test-prod.sh
```
Abra o e-mail do convite → defina a senha → entre em `$KC_URL/realms/portal/account`. Daí você cadastra
os validadores (pela tela de Usuários quando o app subir, ou pelo console admin do Keycloak).

> **Imagem × infra:** o repo do Artifact Registry é recurso do Terraform → por isso o passo 4
> (`-target`) cria só ele antes do push; o passo 6 faz o resto.

## 5. Segredos (Secret Manager)

| Secret | Origem |
|---|---|
| `portal-identity-db-password` | **gerado pelo Terraform** (random) |
| `portal-identity-admin-password` (admin bootstrap do Keycloak) | **gerado pelo Terraform** (random) — leia: `gcloud secrets versions access latest --secret=portal-identity-admin-password` |
| `portal-identity-admin-client-secret` (service account) | **gerado pelo Terraform** (random) |
| `portal-identity-smtp-password` (senha de app do Gmail) | **MANUAL** (você cria — §4 passo 2) |
| `portal-identity-twilio-token` (Twilio auth token) | **MANUAL** (você cria — §4 passo 2) |

- **Nunca** há segredo no git nem no `terraform.tfvars` (só identificadores: smtp_from, twilio_sid…).
- O `tfstate` **contém** as senhas geradas → fora do git e, idealmente, em bucket GCS privado (§7).

## 6. Realm de produção (LIMPO) — gerado

`realms-prod/portal-realm.json` é **gerado** do realm DEV por `scripts/gerar-realm-prod.py` (no repo
`portal-identity`): remove os usuários-semente humanos (LGPD — sem senha DEV no git), mantém o
service account, fixa `sslRequired: external` e parametriza as URLs do front por `${FRONT_BASE_URL}`.
Clients/roles/flows (`browser-otp` + CPF/telefone + OTP) e o tema `portal` vêm do dev.
- A **imagem** embute esse realm e sobe com `--import-realm` → **idempotente** em DB persistente
  (cria no 1º boot, ignora nos seguintes; usuários criados em runtime **persistem**).
- O **1º admin** (você) é criado **após** o deploy por `infrastructure/scripts/criar-admin-prod.sh`
  (via admin bootstrap) + convite por e-mail. Demais usuários: pela tela/console.
- Regenerar após mudar o realm dev: `python3 scripts/gerar-realm-prod.py` e rebuild da imagem.

## 7. Estado do Terraform (state)

Comece local; migre para **GCS** assim que possível (o state tem segredos):
```bash
gsutil mb -l southamerica-east1 -b on gs://portal-tecnologia-tfstate
gsutil versioning set on gs://portal-tecnologia-tfstate
# descomente o backend "gcs" em versions.tf e rode: terraform init -migrate-state
```

## 8. Smoke test (pós-deploy)

`KC_URL=https://...run.app bash infrastructure/scripts/smoke-test-prod.sh` (health/ready, discovery do
realm, account console). Depois, valide na mão: abra `$KC_URL/realms/portal/account` → login por
CPF/telefone → "Tente outra forma" → código por **e-mail** (chega de verdade) e por **SMS** (Twilio).

## 9. Pré-condições / notas (NÃO INFERIR)

- ✅ **OTP real (SMTP + Twilio)** já implementado (I-005) — esta config liga os dois em prod.
- 🟡 **Domínio próprio** (ex.: `id.portal…`) vs URL `*.run.app`: começar com `*.run.app` (hostname
  -strict=false) e migrar depois é aceitável (§4 passo 7).
- 🟡 **IP/cessão:** infra/segredos em nome pessoal; formalizar a cessão no repasse à empresa.
- 🟢 **HA:** hoje `min=max=1` (cache simples). Escalar exige cache distribuído (Infinispan) + Cloud
  SQL `REGIONAL`. Só quando o tráfego justificar.
- 🟢 **Backup/retention** do Cloud SQL: ajustar política conforme exigência.

## 10. Reversão

`terraform destroy` remove tudo **exceto** o Cloud SQL (tem `deletion_protection = true` — desligar
manualmente antes, de propósito, para não dropar o banco de identidade por engano).
