# Doctor-Hub

**Planejamento de capacidade médica** (oferta × demanda) para health centers de governos. 1º produto
da plataforma `portal-tecnologia`. Fica a montante da Teleconsulta e a alimenta com agendamentos prontos.

- **Constituição do produto:** [`CLAUDE.md`](CLAUDE.md) (leia também a raiz [`../../CLAUDE.md`](../../CLAUDE.md)).
- **Domínio / descoberta:** [`docs/discovery/`](docs/discovery/) · **Glossário:** [`docs/discovery/glossary.md`](docs/discovery/glossary.md)
- **Produto / escopo / roadmap:** [`docs/product/`](docs/product/)
- **Arquitetura (domínio/sistema):** [`docs/architecture/`](docs/architecture/)
- **Design system / Figma:** [`docs/design/`](docs/design/) · [`design/`](design/)
- **Specs (SDD):** [`specs/`](specs/) · **Decisões:** [`docs/decisions/decisions-log.md`](docs/decisions/decisions-log.md)

## Código (services/)
| Service | Stack | Rodar |
|---|---|---|
| `doctor-hub-api` | .NET 10 · EF Core + Dapper · Postgres | `make api` (raiz) |
| `doctor-hub-web` | React · Vite · TS · Tailwind · PWA | `make web` (raiz) |

> Os services são repos git próprios, gitignorados pelo hub. O `Makefile` da raiz tem `PRODUCT ?= doctor-hub`.
