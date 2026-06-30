# HANDOFF — sessão 2026-06-29 (portal-tecnologia)

> Bridge desta sessão para continuar **deste diretório** (`~/portal-tecnologia`). A memória do
> Claude é por-caminho; como a pasta mudou (`portal-platform` → `portal-tecnologia`), este arquivo
> carrega o contexto. Leia-o no início da próxima sessão.

---

## 0) Onde estamos / como rodar
Polyrepo: o umbrella (este repo) + 3 services em `services/` (repos git independentes, gitignored).

```bash
make up                              # Postgres (docker) + API .NET (:5092) + Front Vite (:5174)
make -C services/portal-identity up  # Keycloak (:8089) + builda o provider de login CPF/telefone
make status                          # estado dos 4 serviços
make down                            # derruba a stack (preserva o volume do Postgres)
```
- **Postgres**: docker, volume `doctor-hub-api_dbdata` (persiste). Porta host **5440** (`network_mode: host` — o NAT do Docker é instável nesta máquina).
- **API**: processo host **:5092**, valida JWT do Keycloak (RBAC).
- **Front**: Vite **:5174** → login real via Keycloak.
- **Keycloak**: container `portal-keycloak`, **:8089** (realm `portal`), health :9000. **Efêmero** (`start-dev`/H2) — re-importa `services/portal-identity/realms/portal-realm.json` a cada boot.

> ⚠️ **Após reiniciar o Keycloak**, rode `bash services/portal-identity/scripts/aplicar-admin.local.sh`
> para re-aplicar seus dados reais de admin (são efêmeros, ficam só no Keycloak rodando — não no git).

## 1) Login / credenciais (DEV)
- **Onde testar:** front `http://localhost:5174` (botão "Entrar" → Keycloak) ou a tela de conta
  `http://localhost:8089/realms/portal/account`. Console admin Keycloak: `http://localhost:8089/admin`.
- **Senha de todos os seed users:** `102030@302010`. Entra por **username, e-mail, CPF ou telefone**.
- Detalhe completo (perfis, CPFs, etc.): `services/portal-identity/CREDENCIAIS-DEV.txt` (gitignored).
- **Admin = você** (Alessandro, dados reais) — aplicado via `services/portal-identity/scripts/aplicar-admin.local.sh`; valores em `CREDENCIAIS-DEV.txt` (ambos **gitignored**, fora do git por LGPD).

## 2) O que foi construído nesta sessão
- **`make up/down/status`** + `scripts/up.sh|down.sh|install-hooks.sh|setup-clone.sh` (health-check, group-kill via setsid).
- **Renomeação de perfis** (D-139): *Gestor Geral→Regulação*, *Gestor Regional→Gestor*.
- **`portal-identity`** = IdP da empresa (Keycloak/OIDC, **P-003**): realm único `portal`; produto = client; papéis = **client roles**. Doctor-Hub: `doctor-hub-web` (público, PKCE) + `doctor-hub-api` (bearer-only, roles `admin/demandas/regulacao/gestor`). 4 seed users.
- **API valida JWT + RBAC** (D-142): FallbackPolicy=autenticado, `/health` anônimo, `Auth/KeycloakAuth.cs`, ContentRoot ancorado no assembly (senão não lê o appsettings), TestAuthHandler, 31 testes.
- **Login por CPF ou telefone** (authenticator Java customizado, **I-002**): `services/portal-identity/providers/login-cpf-telefone` (build: `make build-provider`).
- **Front loga via Keycloak (slice 2b)**: `AuthGate` + `oidc.ts` (Auth Code + PKCE); papel do token → persona; **removidos login fake + Seletor**; admin → tela placeholder; `api.ts` manda Bearer. 197 testes.
- **Tema de login** com a identidade Doctor-Hub (navy + logo + PT-BR): `services/portal-identity/themes/portal/login`.
- **Guard-rail de segredos**: gitleaks no pre-commit (`scripts/hooks/` + `install-hooks.sh`); allowlist dos CPFs/CNPJs **fictícios** de demo (não são segredos).
- **Renomeação do umbrella** `portal-platform → portal-tecnologia` (**P-005**).
- **Repos no seu GitHub** (`Garbiati/`): `portal-tecnologia`, `doctor-hub-api`, `doctor-hub-web`, `portal-identity` (branch `main`). Este diretório é clone fresco do `Garbiati/portal-tecnologia`.

## 3) Decisões registradas
- **Plataforma** (`docs/decisions/platform-decisions.md`): **P-003** (IdP Keycloak, realm único), **P-004** (repos próprios moram em `services/<repo>`), **P-005** (rename → portal-tecnologia).
- **Doctor-Hub** (`products/doctor-hub/docs/decisions/decisions-log.md`): **D-139** (perfis), **D-140/D-141** (Keycloak nasce/extrai), **D-142** (API JWT+RBAC).
- **Identidade** (`services/portal-identity/docs/decisions/identity-decisions.md`): **I-001** (Keycloak), **I-002** (login CPF/telefone), **I-003** (OTP login modo DEV).

## 4) Segredos
- 📦 **`~/portal-tecnologia-segredos.local.tar.gz`** = bundle dos `.env` + `CREDENCIAIS-DEV.txt` + `aplicar-admin.local.sh` (tem **CPF real + senhas**). **NUNCA commitar.** Para outra máquina: copie por scp/pendrive e rode `scripts/setup-clone.sh`.
- Regra dura: zero segredo no git (o hook gitleaks bloqueia). Prod = GCP Secret Manager.

## 5) PENDENTE (fios em aberto)
- ✅ **OTP login (e-mail + SMS): FEITO, com ENVIO REAL (I-003 + I-005).** Fator **alternativo à senha**
  (passwordless opcional). Flow `browser-otp`: identificador → "tentar outra forma" entre **senha**,
  **código por e-mail** e **código por SMS** (6 díg · 5 min · 5 tentativas). **E-mail** via SMTP do
  realm (`${SMTP_*}` do `.env`); **SMS** via **Twilio** (`TWILIO_*`). Segredos só no `.env`
  (`.env.example` tem o contrato) / Secret Manager em prod. **"Esqueceu a senha?"** destravado pelo
  SMTP. `OTP_DEV_LOG_CODE=true` loga o código (mascarado) em DEV. **Provado E2E**: e-mail (via Mailpit)
  + reset de senha chegam e logam; SMS roda com erro amigável sem creds. **Falta você:** preencher
  `.env` com SMTP/Twilio reais e validar pela aplicação. ⚠️ Caminho da senha tem **2 telas**
  (identificador→senha). Spec: `services/portal-identity/specs/otp-login-dev/spec.md`.
- **GCP pessoal** (`alessandro@garbiati.com`, projeto **`portal-tecnologia`**, **R$1.727** de crédito, 90d até **28/09/2026**). Estratégia: **construir pessoal → repassar à empresa** (IaC/Terraform + segredos no Secret Manager; Twilio/SMTP em seu nome, swap no repasse). Você tem **CNPJ** (prestador) → dá pra buscar **Google for Startups (faixa Start)** self-serve.
  - 🟢 **Produção do IdP (P-006) — TUDO CONFIGURADO, falta só você rodar o deploy (auth pessoal).**
    Escopo escolhido: **só o Keycloak (IdP)** p/ validação interna. Pronto: `realms-prod/` (gerado, sem
    seeds), `Dockerfile` (bake realm + `--import-realm` idempotente), **Terraform** finalizado
    (`infrastructure/terraform`, `terraform validate` ok: Cloud Run + Cloud SQL + Secret Manager +
    Artifact Registry, SMTP Gmail + Twilio por secret), scripts `criar-admin-prod.sh` + `smoke-test-prod.sh`.
    **Runbook completo em `infrastructure/README.md` §4** (passo-a-passo). terraform instalado em `~/.local/bin`.
    ⚠️ **Você roda:** `gcloud auth login` (conta pessoal — hoje está na da EMPRESA) + criar os 2 secrets
    manuais (senha de app Gmail + Twilio token). Depois o resto (apply/build/push/criar admin) pode ser conduzido.
    Decisões: **você = 1º admin via convite**; **SMTP = Gmail (senha de app)**. **Domínios (2):**
    **`portaltecnologia.app.br`** = plataforma (IdP/APIs por subdomínio) → IdP em **`id.portaltecnologia.app.br`**,
    API depois em `api.`; **`doctorhub.app.br`** = o **site** (front Doctor-Hub). Terraform já tem domain
    mapping + output dos registros DNS (cadastrar no registro.br após verificar `portaltecnologia.app.br` no Google).
- **IP/cessão**: código construído para a Portal, em repo pessoal → formalizar **cessão** no repasse (contador/advogado).
- **GitHub**: agora em `Garbiati/`. (P-005 previa renomear `PortalTelemedicina/portal-platform`; em vez disso criamos os repos novos no seu user.)
- **Migração física da pasta**: feita — este `~/portal-tecnologia` é o novo lar. A antiga `~/portal-platform` ainda existe (com os serviços desta sessão); pode apagar depois de confirmar que tudo roda daqui.

- ✅ **Área Admin + CRUD de usuários (D-143): FEITO e provado E2E (no navegador).** O admin loga e cai
  na **Início (Admin)** (KPIs por papel) + tela **Usuários**: listar/criar/editar/ativar-desativar/
  reenviar convite — **todos os papéis**, multi-papel, convite por e-mail. Arquitetura `front →
  doctor-hub-api (/api/admin/users, só papel admin) → Keycloak Admin API` via service account
  `doctor-hub-admin` (secret no `.env`/Secret Manager). **Multi-papel** → seletor de jornada (login +
  topbar "Trocar jornada"). Spec: `products/doctor-hub/specs/admin-gestao-usuarios/spec.md`. Testes:
  API 41 + front 202 verdes. Pendente futuro: **escopo** (vínculo Regulação/Gestor ↔ secretaria/HC =
  SPEC-001, em aberto).

## 6) Visão (não esquecer)
`portal-tecnologia` = **nova plataforma greenfield** da empresa. **NÃO é big-bang rewrite**: ela absorve
Teleconsulta/Telediagnóstico **incrementalmente** (strangler-fig). `doctor-hub` + `portal-identity` são o 1º tijolo.

## 7) Regras que valem sempre (constituição — `CLAUDE.md`)
- **NÃO INFERIR REGRA DE NEGÓCIO. Na dúvida, perguntar** (Diretriz Suprema).
- **Zero segredo no código**; **LGPD** (CPF é PII; CNPJ de órgão público não é segredo).
- **SDD+TDD**; baseline **.NET 10 + EF/Dapper + Postgres** (api) · **React+Vite+TS+Tailwind+PWA** (web) · **Keycloak/OIDC** (identidade) · **GCP** (futuro).
- Rodar `scripts/install-hooks.sh` em todo clone novo (o `setup-clone.sh` já faz).
- **Tudo local; nada de deploy/produção sem decisão.** Commits sim; push para `Garbiati/` (seu user) ok.
