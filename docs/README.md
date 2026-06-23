# `docs/` — Governança de Plataforma (transversal)

> Aqui vive só o que vale para **TODOS os produtos**. Conteúdo específico de um produto (domínio,
> regras de negócio, telas, decisões D-xxx) vive em `products/<produto>/docs/`.

## Mapa

| Pasta | O que é | Entradas |
|---|---|---|
| [`method/`](method/) | **Como construímos** — SDD + TDD + AI-coding | `spec-first-hook.md` (desenho do enforcement), `ai-coding-sdd-report.md` (pesquisa/fontes). Ciclo de vida da spec: [`../specs/README.md`](../specs/README.md). Exemplo aplicado (mapa de paralelização de agentes) vive no produto: `products/doctor-hub/docs/architecture/03-sdd-tdd-e-agentes-paralelos.md`. |
| [`security/`](security/) | **Baseline de segurança & LGPD** | `security-baseline.md` |
| [`architecture/`](architecture/) | **Arquitetura DA PLATAFORMA** (como ela serve produtos) | `platform-architecture.md` |
| [`decisions/`](decisions/) | **ADR de plataforma** (decisões transversais) | `platform-decisions.md` (P-001…) |

## Relação com o resto do hub
- **Método de spec (ciclo de vida + template):** [`../specs/README.md`](../specs/README.md).
- **Regras aplicadas pela máquina:** [`../.claude/rules/`](../.claude/rules/) (security; o `spec-first-hook`
  é o desenho do enforcement em `method/`).
- **Produtos:** [`../products/README.md`](../products/README.md).
