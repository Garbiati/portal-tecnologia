# readme-portal.md — PROMPT DE ARRANQUE (leia isto primeiro)

> **Para o Claude:** você está retomando o projeto **portal-tecnologia**. Este arquivo te orienta.
> A pasta é nova (`~/portal-tecnologia`), então sua memória aqui começa vazia — o contexto vive
> **neste arquivo + nos docs do repo**, não na memória.

## 0) FAÇA ISTO PRIMEIRO (nesta ordem)
1. Leia **este arquivo** inteiro.
2. Leia **`CLAUDE.md`** (a constituição da empresa — regras que você DEVE seguir).
3. Leia **`HANDOFF.md`** (registro detalhado da última sessão: tudo que foi feito + fios em aberto).
4. Rode **`make status`** para ver o estado real dos serviços antes de afirmar qualquer coisa.
5. Se for mexer no Doctor-Hub, leia `products/doctor-hub/docs/decisions/decisions-log.md`;
   se for identidade/Keycloak, `services/portal-identity/docs/decisions/identity-decisions.md`.
6. **Verifique antes de afirmar** — este arquivo é um retrato no tempo; confira contra o código atual.

## 1) O projeto em 30 segundos
**portal-tecnologia** = a **nova plataforma de tecnologia** da Portal Telemedicina (empresa de
telemedicina/saúde pública no Brasil). É um **guarda-chuva polyrepo**: governança aqui (raiz) +
produtos/serviços em `services/<repo>` (repos git independentes, gitignored).
- **Visão:** plataforma **greenfield** que vai **absorver os produtos legados** (Teleconsulta,
  Telediagnóstico) **incrementalmente** (strangler-fig) — **NUNCA** reescrita big-bang.
- **1º tijolo já construído:** `doctor-hub` (gestão de capacidade médica) + `portal-identity`
  (Keycloak/OIDC — identidade única da empresa).
- **Dono/contexto:** Alessandro está construindo no GCP/GitHub **pessoal** (`Garbiati/…`,
  `alessandro@garbiati.com`) para depois **repassar à empresa** (formalizar cessão de IP no repasse).

## 2) Repos (polyrepo) e como rodar
Este umbrella + 3 services em `services/` (cada um seu git, remote em `Garbiati/<nome>`):
`doctor-hub-api` (.NET 10) · `doctor-hub-web` (React/Vite) · `portal-identity` (Keycloak).
```bash
make up                              # Postgres(docker :5440) + API(:5092) + Front Vite(:5174)
make -C services/portal-identity up  # Keycloak(:8089, realm 'portal') + builda o provider de CPF/telefone
make status                          # estado dos 4 serviços
```
> Keycloak é **efêmero** (start-dev/H2): re-importa `services/portal-identity/realms/portal-realm.json`
> a cada boot. **Depois de subir o Keycloak**, rode `bash services/portal-identity/scripts/aplicar-admin.local.sh`
> para re-aplicar os dados reais de admin (Alessandro) — eles ficam só no Keycloak rodando, não no git.

## 3) Login / credenciais
- Front `http://localhost:5174` → "Entrar" → tela do Keycloak (tema Doctor-Hub, PT-BR).
- Entra por **username, e-mail, CPF ou telefone**; senha dos seed users: `102030@302010`.
- Detalhes e valores: **`services/portal-identity/CREDENCIAIS-DEV.txt`** (gitignored).

## 4) O que já está pronto (resumo — detalhe no HANDOFF.md)
Auth real ponta-a-ponta: Keycloak/OIDC (realm único `portal`, produto=client, papéis=client roles
`admin/demandas/regulacao/gestor`); **API valida JWT + RBAC**; **front loga via OIDC+PKCE** (login fake
e Seletor foram removidos; admin cai numa tela placeholder); **login por CPF ou telefone** (authenticator
Java customizado); **tema de login** com a identidade Doctor-Hub. Guard-rail **gitleaks** no pre-commit.
Decisões: **P-003/P-004/P-005** (plataforma), **D-139..D-142** (doctor-hub), **I-001/I-002** (identidade).

## 5) Fios em aberto (prováveis próximos passos)
- **OTP login (e-mail + SMS)** — escolhido "os dois", **não começado**. Plano: 1 authenticator de
  código (Java SPI) + flow "senha OU código" em **modo DEV** (código no log) → depois plugar **SMTP**
  (e-mail) e **gateway de SMS pago** (Twilio/Zenvia…). O "Esqueceu a senha?" também depende de SMTP.
- **GCP pessoal** (projeto `portal-tecnologia`, R$1.727 de crédito até 28/09/2026) → IaC/Terraform +
  Secret Manager; integrações lendo segredos por nome (swap fácil no repasse à empresa).
- Pergunte ao Alessandro por onde seguir antes de assumir.

## 6) REGRAS (não negociáveis — herdadas de CLAUDE.md)
- **NÃO INFERIR REGRA DE NEGÓCIO. Na dúvida, PERGUNTAR.** (Diretriz Suprema.)
- **Zero segredo no git** — `.env`/CREDENCIAIS/`*.local.sh` são gitignored; o hook gitleaks bloqueia.
  Em clone novo rode `scripts/install-hooks.sh` (o `setup-clone.sh` já faz). **LGPD:** CPF é PII
  (nunca no git); CNPJ de órgão público não é segredo.
- **Tudo local.** Commits sim; **push só para `Garbiati/`** (user do Alessandro) e **só quando ele pedir**.
  **Nada de deploy/produção** sem decisão registrada.
- **SDD+TDD**; lotes pequenos, CI/testes verdes; toda decisão confirmada vira registro (P-xxx plataforma / D-xxx produto / I-xxx identidade).
- Reescrita = **incremental (strangler-fig)**, jamais big-bang (é healthcare em produção).

## 7) Como começar a responder
Depois de ler os arquivos e rodar `make status`, dê um **resumo curto do estado atual** + **proponha o
próximo passo** (provavelmente o OTP em modo DEV) e **pergunte** ao Alessandro se segue por aí.
Não comece tarefa grande sem confirmar.
