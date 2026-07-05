# HANDOFF — sessão 2026-06-29 (portal-tecnologia)

> Bridge desta sessão para continuar **deste diretório** (`~/portal-tecnologia`). A memória do
> Claude é por-caminho; como a pasta mudou (`portal-platform` → `portal-tecnologia`), este arquivo
> carrega o contexto. Leia-o no início da próxima sessão.

---

## 🌙 RELATÓRIO FINAL DA MADRUGADA 2026-07-05 (missão noturna — leia isto primeiro)

> Objetivo: "me entregue o sistema mais auto homologado possível… escala fácil de criar… valide
> todas as telas". Foco: **FIXA é certeza; FLEX congelada (D-151)**; regras "depois" NÃO inferidas.
> Placar da noite: **API 68 testes · Front 318 testes · CI verde · tudo deployado · E2E prod provado.**

### ✅ O que entrou EM PRODUÇÃO esta noite (CI verde + E2E real, com limpeza)
1. **Tipo de serviço** (D-150): catálogo extensível (teleatendimento, atendimento, plantão, laudo,
   exame) — `GET /api/tipos-servico` — + select no form + badge nos cards.
2. **Escala vinculada a PROJETO** (— pool geral — ou cliente). É o "alocar médico à necessidade do projeto".
3. **FIXA com horários POR DIA** ("seg 8–14 · ter 10–18"): INV-1/INV-4 validadas por dia no backend.
4. **⭐ Semanas do mês SEM atendimento** (D-152): chips 1ª–5ª — "na 2ª semana o doutor folga".
   **E2E provado em prod:** criei a escala EXATA do seu exemplo (seg 8–14, ter 10–18 por-dia, sem a
   2ª semana, teleatendimento, Piauí SD) → persistiu e apareceu certo no GET global.
5. **Plantão de reposição** (flag; Supervisor não assume; sem vínculo de paciente — aguarda regra).
6. **Indisponibilidade do médico** (CRUD real; desconta capacidade no painel).
7. **Painel de capacidade REAL** por especialidade × tipo × projeto, MÊS CORRENTE, com descontos.
8. **6 escalas FIXAS reais semeadas** p/ o painel mostrar números de verdade. Desfazer:
   `infrastructure/scripts/limpar-escalas-demo.sh`.

### 🔬 AUTO-HOMOLOGAÇÃO POR TELA (68 agentes: QA × UX × design em 14 telas + verificação adversarial)
Achados: **24 críticos confirmados · 114 médios · 70 cosméticos**. Status:
- **24 críticos → CORRIGIDOS e no ar** (+ os C1–C4/M-diversos da 1ª revisão). Destaques: criar
  escala dava "sucesso" com a API falhando (agora reverte + erro real); corrida que trocava o
  médico exibido por outro; lista "sem escala" falsa; `/api/me` sem token; disponibilização somava
  capacidade em dobro; `<Button>` aninhado em `<Link>`.
- **~15 médios baratos → CORRIGIDOS e no ar**: **jargão interno tirado da tela** (INV-1, D-103,
  D-148, D-123 — importante pra validação externa), teclado numérico no mobile, **bug de data em
  UTC** (default do período vinha 1 dia à frente no BR), scroll-lock com menu aberto, EmptyStates,
  login sem erro OIDC em inglês, alvos de toque 44px, filtro de especialidade real.
- **~99 médios + 70 cosméticos restantes → CATALOGADOS** em
  `scratchpad/homolog.json` (não versionado; peça que eu recupere quando quiser priorizar). São
  quase todos polimento (a11y, textos, paginação, máscara de CNPJ) — nenhum bloqueia a validação.

### 🔎 PESQUISA DE MERCADO (virou discovery oficial — base pra decidir a "escala fácil")
- **`docs/discovery/14-escalas-medicas-mercado.md`** — o padrão vencedor pro seu pedido:
  1) **regra semanal + override por data** (UM mecanismo cobre folga E extensão "segunda até 18h");
  2) **PREVIEW das próximas datas antes de salvar** (defesa nº1 contra recorrência errada — nem
  Google/Outlook resolvem "2ª semana" bem); 3) **IA como INTÉRPRETE** (você fala a disponibilidade,
  ela propõe a regra, você confirma — motor determinístico gera). **Ninguém no mercado médico faz
  isso** = nosso diferencial. Anti-padrões dos líderes (QGenda/Amion): automação que quebra em regra
  complexa, sem auditoria de escala, app mobile ruim.
- **`docs/discovery/15-agendamentos-cancelamentos-mercado.md`** — valida suas regras com evidência:
  psiquiatria/psicologia NÃO troca de médico (dropout OR 4,59; CFM 2.314 art.6º §2º = presencial a
  cada ≤180d com o assistente); doutor-de-plantão = modelo Teladoc; benchmark de "bump" 4,9%;
  **remarcação escolhida pelo paciente melhora adesão, imposta piora** → mensagem sempre com opções.
  Já tem as 4 mensagens-modelo PT-BR (incluindo a de "imprevisto, prioridade máxima").

### 🔴 PROVISÓRIOs / perguntas que dependem SÓ de você (nada inferido)
1. **"2ª semana do mês"** hoje = n-ésima ocorrência do dia (2ª segunda…). Confirmar? (o preview de
   datas — rec. da pesquisa — vai deixar isso à prova de erro; posso construir amanhã.)
2. **Quinzenal / algumas quintas do mês**: papel da FLEX (extensão pontual) — falta a conversa FLEX.
3. **Agendamentos/faltas** (discovery 13/15): fila da 1ª consulta, quem vincula no plantão de
   reposição, plantonista fixo×rodízio, atestado entra ou não na métrica do médico, psicologia(CFP)
   segue psiquiatria(CFM)? — tudo aguardando sua decisão p/ virar spec.
4. **Reserva de capacidade** dedicada×pool e **valores por TIPO DE SERVIÇO** (hoje valor é por
   especialidade — D-125): estender?
5. **Personas demo** ainda caem no fallback C1 (SES-PI desativado) — vincule-as a clientes reais
   pela tela de Usuários (2 min, pelo app) OU eu faço se você confirmar em quais projetos.

### 🧪 Estado dos gates (04h25)
API 68 testes ✓ · Front 318 testes ✓ · CI verde nos 2 repos ✓ · E2E prod (escala completa) ✓ ·
uptime checks + tripwire + rotina smoke de hora em hora ativos. Decisões novas: D-150/D-151/D-152.

---

## 🧪 HOMOLOGAÇÃO E2E — TODAS AS TELAS (2026-07-05)

Modelo D-153 ("pronto = testado contra infra real") estendido a todas as telas. Cada fluxo tem
harness E2E versionado em `infrastructure/scripts/homolog-<tela>-e2e.py` (login OIDC real + CRUD/
fluxo real contra API+Keycloak, afirmando persistência). Helper comum: `e2e_common.py`. Conta de
automação provisionável: `e2e-user.sh up|down` (fica fora do realm por padrão — só o Alessandro).

| Tela | Harness | Status |
|---|---|---|
| Usuários | homolog-usuarios-e2e.py | ✅ (achou I-009: vínculo descartado pelo Keycloak → corrigido) |
| Clientes & Projetos | homolog-clientes-e2e.py | ✅ (achou PUT/tipo legado → corrigido) |
| **Escala FIXA** (core) | homolog-escalas-e2e.py | ✅ por-dia+semana+tipo+projeto persistem; INV bloqueia; zero bug |
| Solicitações + De Acordo | homolog-solicitacoes-e2e.py | ✅ criar→reservar→aceite(D-116) persiste; zero bug |
| Assunção / Agendamentos | homolog-agendamentos-e2e.py | ✅ criar+validação LGPD das iniciais; zero bug |

**Achados PROVISÓRIOS (não bugs — decisão/design):** agendamentos sem DELETE + GET global sem
filtro por unidade (qualquer autenticado lê as iniciais — revisar escopo/RBAC); solicitações
POST/PATCH sem RBAC por papel (matriz papel×ação D-142 pendente). Nada bloqueia a apresentação.

**Rodar tudo:** `cd infrastructure/scripts && ./e2e-user.sh up && for h in usuarios clientes escalas solicitacoes agendamentos; do python3 homolog-$h-e2e.py; done && ./e2e-user.sh down`

---

---

## 🎬 DEMO DE SEGUNDA (2026-07-07, antes do meio-dia) — TUDO PRONTO (preparado 2026-07-04)

**Objetivo:** apresentação navegável p/ validação ("elas" criam usuários, logam, passeiam nas telas).

### URLs e logins
- **App:** `https://doctorhub.app.br` · **IdP:** `https://id.portaltecnologia.app.br` · **API:** `https://api.portaltecnologia.app.br/health`
- **Seu admin:** CPF `35922911813` · senha `PortalIdP@2026` — **temporária (I-007): no próximo login o Keycloak obriga a trocar** (defina uma só sua). Ou entre por OTP e-mail.
- **Personas de demo criadas em PROD** (senha de todas: `102030@302010`; aceitam login por username/CPF/telefone):
  | login | papel | jornada |
  |---|---|---|
  | `mariana` (CPF 044.876.219-30) | demandas | Início/Pendências, Médicos, Escala, Solicitações… |
  | `aldair` (CPF 233.490.661-05) | regulacao | Minhas Solicitações, De Acordo |
  | `eronildes` (CPF 825.640.173-06) | gestor (**rótulo: Supervisor**, D-144) | Assunção de Vagas |
  | `admin-dh` (CPF 318.224.905-11) | admin | Administração, Usuários |

### Roteiro sugerido
1. **Login** (mostrar CPF + "tentar outra forma" = código por e-mail). 2. **Admin → Usuários**: criar
um usuário REAL na hora (e-mail verdadeiro) → convite chega por e-mail (SendGrid, from
`nao-responda@doctorhub.app.br`) → pessoa define senha e loga. 3. **Jornadas** com as personas acima.
4. **Médicos**: em PROD há **4.523 médicos REAIS da Teleconsulta** (busca funciona — ex. "Abel").

### 🧪 HOMOLOGAÇÃO (sábado à noite — ondas do 100%, D-145): o que testar
Tudo abaixo agora PERSISTE em prod (recarregue e confira que ficou):
1. **Escala** (Demandas): /escala → escolher médico REAL → criar FIXA (início ≥ amanhã!) e FLEX;
   tentar FLEX em cima da FIXA → deve BLOQUEAR (INV-1); arquivar/reativar; badge "com escala" na lista.
2. **Solicitações** (Regulação/aldair): Minhas Solicitações → Nova solicitação → recarregar (persistiu);
   De Acordo → "Dou meu de acordo" → recarregar (aceite persiste).
3. **Assunção** (Supervisor/eronildes): assumir vaga (paciente por INICIAIS) → recarregar (badge
   "assumida" volta do banco). TC = stub por decisão (enviadoTc=false).
4. **Auditoria** (Demandas): tela lista a trilha REAL (quem = usuário do token).
5. **Inbox/Home**: os 6 UC-* da fixture agora vêm do banco (+ teste E2E cancelado à vista).
⚠️ PROVISÓRIO (regra não decidida — não é bug): transições finas por papel; vagas da assunção
derivadas; painel/contratação/cobertura numérica seguem da fixture; sobrepor sem persistência.

### O que foi preparado (2026-07-04, Alessandro offline)
- ✅ **Seed de médicos em PROD**: 4.523 doutores reais carregados via código de seed rodando LOCAL
  contra o banco de prod (cloud-sql-proxy). ⚠️ **LGPD:** `doctors-demo.json` é **gitignored e
  local-only** (dados reais!) — restaurado de `~/portal-platform` p/ `services/doctor-hub-api/src/DoctorHub.Api/Data/Seeds/`;
  NUNCA commitar; a imagem de CI não o contém (por design).
- ✅ **Personas criadas** no realm prod (acima) — login da mariana validado E2E (CPF formatado → token com role).
- ✅ **min-instances=1** nos 3 serviços até a demo (sem cold start). **REVERTER depois** (custo):
  `gcloud run services update {portal-identity,doctor-hub-api,doctor-hub-web} --region=southamerica-east1 --min-instances=0`
  (ou próximo `terraform apply` já reverte — o TF tem min=0).
- ✅ Rótulo **Supervisor** (D-144) deployado; 202 testes verdes; CI verde nos 2 repos.
- ✅ TLS do LB agora alcançável também deste ambiente (era propagação).
- ℹ️ Telas ainda com dado FIXTURE (ok p/ validação): Solicitações, Clientes & HCs, Contratação,
  Escala (a tela existe; backend de escala é a Fatia 1, pós-demo). SMS aguarda Sender ID `PortalTech`.
- ℹ️ Se alguém abrir o app e vier versão velha: é o service worker do PWA — recarregar a página resolve.

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
  - 🟢🚀 **PRODUÇÃO DO IdP (P-006) — NO AR em `https://id.portaltecnologia.app.br`** (2026-07-01).
    Projeto GCP pessoal **`portal-tecnologia-500920`** (billing on; budget R$150/mês c/ alertas).
    **Cloud Run** (Keycloak 26, `min=0`, sidecar **Cloud SQL Auth Proxy** em localhost:5432) + **Cloud SQL**
    Postgres (edition **ENTERPRISE**, db-f1-micro) + **Secret Manager** + **Artifact Registry**, tudo em
    `southamerica-east1`. **Domínio via Load Balancer HTTPS** (domain mapping NÃO existe em SP → erro 501)
    + **cert gerenciado** (IP `136.68.142.130`, registro A `id` no registro.br). **E-mail: SendGrid**
    (não Gmail/Zoho — `garbiati.com` é Zoho, sem SMTP Gmail; SendGrid é transacional/free/parceiro GCP),
    enviando como **`nao-responda@doctorhub.app.br`** (domínio autenticado no SendGrid, CNAMEs no registro.br).
    **Realm importado** por `infrastructure/scripts/importar-realm-prod.sh` (⚠️ `start --optimized` IGNORA
    `--import-realm` → import é passo de deploy via Admin API, idempotente). **Admin = Alessandro**
    (username = CPF `35922911813`, logou por senha e por OTP-email). Segredos no Secret Manager:
    `portal-identity-{db,admin,admin-client}-password` (gerados) + `-smtp-password` (=API key SendGrid) +
    `-twilio-token`. Runbook: `infrastructure/README.md §4`.
    - ⚠️ **Gotcha gcloud/ADC:** a conta ativa/ADC volta pra da EMPRESA sozinha. Antes de qualquer `terraform`/`gcloud`:
      `gcloud config set account alessandro@garbiati.com` + `export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)`.
    - ⚠️ **Meu ambiente não completa TLS pro IP do LB** (bloqueio de rede) — validar sempre pelo navegador do Alessandro.
    - ⏳ **SMS — Sender ID `PortalTech` SUBMETIDO na Twilio em 2026-07-01** (BR/DOMESTIC/TRANSACTIONAL, brand=yes,
      1000/mês). Modelo=plataforma (1 Sender ID p/ todos os produtos; por-produto é aditivo depois via mapa
      `client_id→sender` no authenticator). Docs enviados: Authorization Term assinado (gov.br) + Contrato Social
      (JUCESP) + Cartão CNPJ (apoio). **Aguardando aprovação** (Twilio+operadoras, dias–2sem; acompanhar em
      e-mail/Zendesk/aba "Global registrations"). Se pedirem prova da marca: CNAE 63.19-4-00 "Portais…" no Cartão CNPJ.
      **QUANDO APROVAR:** `twilio_from="PortalTech"` no tfvars → `terraform apply` → testar SMS (token já no Secret
      Manager; `TwilioSms` usa o `from` verbatim, aceita alfanumérico — nada a mudar no código). Conta Twilio no
      CNPJ da **Garbiati** (LTDA de Osasco/SP; nº pessoal é só destinatário de teste). **Domínios:** `portaltecnologia.app.br`
      = plataforma (IdP `id.`, API `api.` depois); `doctorhub.app.br` = site.
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
