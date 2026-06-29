# portal-tecnologia

**Repo oficial de governança da Portal Telemedicina.** Guarda-chuva acima de todos os repos da
empresa: **método, padrões, governança de IA, LGPD/segurança e o catálogo de repositórios**. O
**código** vive em cada repo (polyrepo); aqui fica o que é **comum**.

> Leia a **constituição** antes de qualquer ação: [`CLAUDE.md`](CLAUDE.md).

## Catálogo de repositórios → fonte da verdade: [`repos.yml`](repos.yml)

| Repo | Tipo | Status | Docs | URL |
|---|---|---|---|---|
| **portal-tecnologia** | governança | active | self | `PortalTelemedicina/portal-tecnologia` ✅ |
| **teleconsulta** | hub (monorepo, ~30 services) | production | self | `PortalTelemedicina/teleconsulta` ✅ |
| **doctor-hub-api** | service (doctor-hub) | build | `products/doctor-hub` | `PortalTelemedicina/doctor-hub-api` ✅ |
| **doctor-hub-web** | service (doctor-hub) | build | `products/doctor-hub` | `PortalTelemedicina/doctor-hub-web` ✅ |
| _dados_ | produto | candidato | — | a confirmar |
| _telediagnostico_ | produto | candidato | — | a confirmar |

✅ = url verificada · "a confirmar/publicar" = ainda não verificado (não inventamos URL).

## Estrutura

```
portal-tecnologia/
├── CLAUDE.md           Constituição da empresa (ler antes de qualquer ação)
├── repos.yml           Manifest/catálogo de todos os repos (fonte da verdade)
├── docs/               GOVERNANÇA transversal: method/ security/ architecture/ decisions/
├── specs/              Metodologia SDD (ciclo de vida + template)
├── products/           Produtos com governança HOSPEDADA aqui (doctor-hub/ + _template/ + registry)
├── infrastructure/     docker-compose + envs (compartilhado)
├── scripts/            workspace.sh (clona repos do manifest)
├── workspace/ (gitignored)  clones locais dos repos da empresa (make workspace)
└── services/  (gitignored)  código local do doctor-hub (api/web)
```

## Começar

```bash
make help          # lista os alvos
make catalog       # mostra o catálogo de repos (repos.yml)
make workspace     # clona/atualiza os repos da empresa em ./workspace/ (gitignored)
make api           # roda a API do produto (default PRODUCT=doctor-hub) — :5000/health
make web           # roda o front (Vite) — :5173
make test          # testes dos services do produto
```

## Modelo de repositórios (por que NÃO é monorepo nem submodules)

Polyrepo: cada produto/serviço é **seu próprio repo git**, independente. O guarda-chuva os
**referencia** via `repos.yml` (manifest revisável) — **não** via git submodules (acoplam versão e
têm DX ruim) nem true-monorepo (juntaria tudo num git só). `make workspace` dá a visão local aninhada
(em `workspace/`, gitignored) sem poluir o histórico deste repo. Detalhe:
[`docs/architecture/platform-architecture.md`](docs/architecture/platform-architecture.md).

## Princípios (não relaxar — detalhe em `CLAUDE.md`)

- **Não inferir regra de negócio** — dúvida vira pergunta aberta no produto.
- **SDD+TDD** — spec/teste antes; invariantes médicas/financeiras cercadas de teste.
- **Segurança/LGPD** — zero segredo (gitleaks + pre-commit); prod = GCP Secret Manager.
  Baseline: [`docs/security/security-baseline.md`](docs/security/security-baseline.md).
- **Decisões** — plataforma: [`docs/decisions/platform-decisions.md`](docs/decisions/platform-decisions.md) (P-xxx);
  por produto, no decisions-log do produto (D-xxx).
