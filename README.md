# ptm-platform

**Spec-hub** da plataforma interna da empresa — análogo ao `../teleconsulta`. Guarda
**especificações, regras e governança**; o código vive em `services/` (repos git separados).

## Produtos

| Produto | Status | Services |
|---|---|---|
| **Doctor-Hub** — planejamento de capacidade médica (oferta × demanda) | 🟢 build real (Fase 6) | `doctor-hub-api` (.NET 10), `doctor-hub-web` (React PWA) |

> A plataforma nasce para servir os produtos da empresa (Teleconsulta, Telediagnóstico, Dados…).

## Estrutura

```
ptm-platform/
├── CLAUDE.md           Constituição (ler antes de qualquer ação)
├── docs/               discovery, decisions-log, design, glossary, architecture, research, security
├── specs/              specs por subdomínio (SDD) — caminho para PRDs
├── infrastructure/     docker-compose + envs
├── .claude/rules/      regras globais (SDD, security)
└── services/  (gitignored)
    ├── doctor-hub-api/     .NET 10 · EF Core+Dapper · Postgres
    └── doctor-hub-web/     React · Vite · Tailwind · PWA
```

## Começar

```bash
# Cada service é um repo git próprio em services/ (não versionado por este hub).
make api      # roda a API (.NET) — http://localhost:5000/health
make web      # roda o front (Vite) — http://localhost:5173
make test     # testes dos dois services
```

## Princípios (não relaxar)

- **Não inferir regra de negócio** — dúvida vira pergunta aberta em `docs/discovery/03-open-questions.md`.
- **SDD+TDD** — spec/teste antes; invariantes médicas/financeiras cercadas de teste.
- **Segurança/LGPD** — zero segredo no código (gitleaks + pre-commit); prod = Secret Manager.
- **Decisões** confirmadas → `docs/decisions/decisions-log.md`.

## Stack (D-109)

Backend **.NET 10 + EF Core 10 + Dapper + PostgreSQL** · Frontend **React + Vite + TS + Tailwind + PWA** ·
Infra **GCP** (Cloud Run + Cloud SQL + Secret Manager — a confirmar com a infra da Portal).
