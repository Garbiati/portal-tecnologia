# portal-platform — Constituição da Plataforma Portal Telemedicina

> **Repo oficial de governança da empresa (Portal Telemedicina).** Guarda-chuva acima de **todos os
> repos** da empresa: carrega **governança de IA, LGPD/segurança, padrões, agents/skills e o catálogo
> de todos os repositórios** — **não** código de app. Todo agente de IA e todo humano DEVE ler e
> seguir esta constituição **antes de qualquer ação**.
>
> **Modelo:** polyrepo. Cada produto/serviço é **seu próprio repo git** (independente). O que é
> **comum** vive aqui; o que é **específico** vive em cada repo. A linkagem oficial entre o guarda-chuva
> e os repos é o **manifest** ([`repos.yml`](repos.yml)) + o **catálogo** — **não** submodules.

## 🏗️ Estrutura

```
portal-platform/
├── CLAUDE.md · README.md · Makefile      ← constituição da empresa + entry point
├── repos.yml                              ← MANIFEST: catálogo de todos os repos (fonte da verdade)
├── docs/                ← GOVERNANÇA TRANSVERSAL (vale p/ todos os repos)
│   ├── method/            SDD + TDD + AI-coding
│   ├── security/          baseline de segurança & LGPD
│   ├── architecture/      arquitetura DA PLATAFORMA (como ela serve produtos)
│   └── decisions/         ADR de PLATAFORMA (P-001…)
├── specs/               ← metodologia SDD (ciclo de vida + template)
├── products/           ← produtos cuja governança/specs são HOSPEDADAS aqui (ex.: doctor-hub)
│   ├── README.md          registry de produtos hospedados
│   ├── _template/         scaffold p/ onboard um produto novo
│   └── doctor-hub/        docs/ + specs/ + design/ + CLAUDE.md
├── infrastructure/     ← docker-compose + envs (compartilhado)
├── scripts/            ← utilitários (workspace.sh: clona/atualiza repos do manifest)
├── .claude/rules/      ← regras globais aplicadas pela máquina (SDD, security)
├── workspace/  (gitignored)  ← clones locais dos repos da empresa (via `make workspace`) — só DEV
└── services/   (gitignored)  ← código local do doctor-hub (api/web), repos próprios
```

**Hierarquia de `CLAUDE.md`:** raiz (empresa) → produto (`products/<p>/CLAUDE.md`) → repo de código
(cada `services/<repo>/CLAUDE.md` aponta de volta para cá). Cada nível só acrescenta o que é seu.

**Catálogo de repos:** `repos.yml` lista **todos** os repos da empresa (url, tipo, dono, stack,
status, onde ficam os docs). Alguns têm os **docs hospedados aqui** (ex.: doctor-hub em `products/`);
outros mantêm docs **no próprio repo** (ex.: `teleconsulta`) e só constam no catálogo. `make workspace`
clona/atualiza os que têm remote num `workspace/` gitignored para visão local.

---

## 🧭 Diretriz Suprema (Prime Directive) — vale para todo repo

**NÃO INFERIR REGRA DE NEGÓCIO. NA DÚVIDA, PERGUNTAR.**

1. Nenhuma regra de negócio é inventada, deduzida ou "preenchida por bom senso". Se não está escrita
   na discovery do produto (`products/<p>/docs/discovery/`) ou numa spec aprovada, **não existe ainda**.
2. Toda suposição vira **pergunta aberta**, não decisão silenciosa no código.
3. Toda decisão confirmada pelo humano vira **registro** (ADR de plataforma `P-xxx` se transversal;
   decisions-log do produto `D-xxx` se específica).
4. Lidamos com **dado sensível (LGPD)** e, em saúde pública, **dinheiro público** — o custo de uma
   regra errada é alto. Prefira perguntar duas vezes a assumir uma vez.

Se um agente perceber que está prestes a "achar" algo sobre o negócio: **pare e pergunte.**

---

## 🔬 Método de trabalho (igual para todos os repos)

- **Double Diamond / Design Thinking**: entender o PROBLEMA antes da solução.
- **SDD (Spec-Driven Development)**: nada é codificado sem spec aprovada. A spec **é** o sistema;
  o código é derivado. Ciclo de vida: [`specs/README.md`](specs/README.md).
- **TDD**: nada é codificado sem teste antes. Cada invariante médica/financeira cercada de teste.
- Detalhe: [`docs/method/`](docs/README.md) — `spec-first-hook.md` (enforcement), `ai-coding-sdd-report.md` (pesquisa).

---

## ⚠️ Princípios de risco (1 dev + IA em healthcare) — `docs/method/ai-coding-sdd-report.md`

1. **Lacuna de superconfiança (risco nº 1).** A spec e os testes são a ÚNICA verdade de campo.
2. **Segurança inegociável.** Baseline: [`docs/security/security-baseline.md`](docs/security/security-baseline.md).
3. **Núcleo crítico à mão.** Invariantes médicas/financeiras revisadas por humano e cercadas de teste.
4. **Lotes pequenos.** Mudanças pequenas, testadas, frequentes.

---

## 🔒 Segurança & LGPD (não relaxar nunca) — `docs/security/security-baseline.md`

- **Zero segredo no código** (`.mcp.json`, `appsettings`, settings). Dev: `.env` + `dotnet user-secrets`.
  Prod: **GCP Secret Manager**. `gitleaks` + pre-commit barram vazamento.
- **LGPD**: nunca expor dado de paciente em log/resposta; demo só com iniciais. Least-privilege/RBAC.
- **Verificar todo pacote sugerido por IA** antes de adicionar.
- **Sync com a Teleconsulta = via banco**: PULL read-only; PUSH só via credencial dedicada + allowlist
  tabela:colunas + dry-run + `--apply` + log; nunca DELETE/DROP/TRUNCATE; UPDATE com WHERE por `external_id`.

---

## 🤖 Governança de IA (como agentes operam nesta empresa)

- **`.claude/rules/`** = regras aplicadas pela máquina (security, SDD). **`.claude/agents/`** e
  **`.claude/skills/`** (quando criados) = agents/skills compartilhados entre repos.
- **Hierarquia de contexto**: o `CLAUDE.md` de um repo herda esta constituição. Não duplicar regra —
  apontar para cá.
- **Padrão de modelo/MCP**: ver `docs/method/`. Zero segredo em `.mcp.json`.

---

## ➕ Como adicionar um repo/produto ao catálogo

1. Registre o repo em [`repos.yml`](repos.yml) (url, tipo, dono, stack, status, docs).
2. Se a governança/specs serão **hospedadas aqui**: copie [`products/_template/`](products/_template/)
   para `products/<produto>/`, preencha o `CLAUDE.md`, crie `docs/discovery/` antes das specs, e
   registre em [`products/README.md`](products/README.md).
3. Se os docs ficam **no próprio repo**: basta o catálogo + um `CLAUDE.md` nesse repo apontando para cá.
4. Registre a decisão em [`docs/decisions/platform-decisions.md`](docs/decisions/platform-decisions.md) (P-xxx).

---

## ⛔ O que continua valendo — não relaxar
- **Não inferir regra de negócio.** Dúvida → pergunta aberta do produto + `// PROVISÓRIO`.
- **SDD+TDD**; **Segurança/LGPD**; **least-privilege/RBAC**.
- **Stack baseline da plataforma** (recomendado; cada repo confirma): **.NET 10 + EF Core 10 + Dapper +
  PostgreSQL** (api); **React + Vite + TS + Tailwind + PWA** (web); infra **GCP** (Cloud Run + Cloud SQL
  + Secret Manager). Reabrir só por decisão registrada.

### Integrações disponíveis (verificadas 2026-06-13)
- **ClickUp**: MCP (leitura+escrita) workspace `9013772753`. ⚠️ Whiteboard visual só pelo browser.
- **Figma, Slack, Google Drive, Gmail/Calendar**: MCP disponível. **Browser (Claude-in-Chrome)**: sessão própria.

---

## 📌 Estado atual
- **Catálogo de repos:** [`repos.yml`](repos.yml). **Produtos hospedados:** [`products/README.md`](products/README.md).
- **Decisões de plataforma:** [`docs/decisions/platform-decisions.md`](docs/decisions/platform-decisions.md) (P-001, P-002…).
- **Governança transversal:** [`docs/README.md`](docs/README.md).

_Última atualização: 2026-06-23 (repo oficial de governança da empresa = portal-platform; catálogo de repos via manifest — P-002)._
