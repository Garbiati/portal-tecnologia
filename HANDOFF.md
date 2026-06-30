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
- ✅ **OTP login (e-mail + SMS) — modo DEV: FEITO (I-003, 2026-06-29).** Fator **alternativo à senha**
  (passwordless opcional). Flow `browser-otp`: identificador → "tentar outra forma" entre **senha**,
  **código por e-mail** e **código por SMS** (6 díg · 5 min · 5 tentativas). Em DEV o **código vai só
  pro log** (`grep OTP-DEV` nos `docker logs portal-keycloak`). Spec:
  `services/portal-identity/specs/otp-login-dev/spec.md`. **Provado E2E** (senha/e-mail/SMS/código
  errado). **FALTA o envio real:** **SMTP** (e-mail) + **gateway de SMS pago** (Twilio/Zenvia…); o
  "Esqueceu a senha?" também depende do SMTP. ⚠️ Caminho da senha agora tem **2 telas** (identificador→senha).
- **GCP pessoal** (`alessandro@garbiati.com`, projeto **`portal-tecnologia`**, **R$1.727** de crédito, 90d até **28/09/2026**). Estratégia: **construir pessoal → repassar à empresa** (IaC/Terraform + segredos no Secret Manager; Twilio/SMTP em seu nome, swap no repasse). Você tem **CNPJ** (prestador) → dá pra buscar **Google for Startups (faixa Start)** self-serve.
  - 🟡 **Produção do Keycloak planejada (P-006) — IaC pronto, NÃO aplicado.** Esqueleto em `infrastructure/` (Terraform: Cloud Run + Cloud SQL + Secret Manager + Artifact Registry, região `southamerica-east1`) + `services/portal-identity/Dockerfile` (prod). **Ler `infrastructure/README.md`** antes de aplicar (passo-a-passo, custo, perguntas abertas). ⚠️ O `gcloud` da máquina está logado na conta/projeto da **EMPRESA** (`coronavirus-272213`) — **trocar p/ a pessoal** antes de qualquer apply. **Pré-condição:** OTP real (SMTP/SMS) antes de prod (hoje I-003 é só log).
- **IP/cessão**: código construído para a Portal, em repo pessoal → formalizar **cessão** no repasse (contador/advogado).
- **GitHub**: agora em `Garbiati/`. (P-005 previa renomear `PortalTelemedicina/portal-platform`; em vez disso criamos os repos novos no seu user.)
- **Migração física da pasta**: feita — este `~/portal-tecnologia` é o novo lar. A antiga `~/portal-platform` ainda existe (com os serviços desta sessão); pode apagar depois de confirmar que tudo roda daqui.

## 6) Visão (não esquecer)
`portal-tecnologia` = **nova plataforma greenfield** da empresa. **NÃO é big-bang rewrite**: ela absorve
Teleconsulta/Telediagnóstico **incrementalmente** (strangler-fig). `doctor-hub` + `portal-identity` são o 1º tijolo.

## 7) Regras que valem sempre (constituição — `CLAUDE.md`)
- **NÃO INFERIR REGRA DE NEGÓCIO. Na dúvida, perguntar** (Diretriz Suprema).
- **Zero segredo no código**; **LGPD** (CPF é PII; CNPJ de órgão público não é segredo).
- **SDD+TDD**; baseline **.NET 10 + EF/Dapper + Postgres** (api) · **React+Vite+TS+Tailwind+PWA** (web) · **Keycloak/OIDC** (identidade) · **GCP** (futuro).
- Rodar `scripts/install-hooks.sh` em todo clone novo (o `setup-clone.sh` já faz).
- **Tudo local; nada de deploy/produção sem decisão.** Commits sim; push para `Garbiati/` (seu user) ok.
