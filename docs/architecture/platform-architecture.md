---
title: Arquitetura da Plataforma — como o portal-tecnologia serve produtos
status: active
scope: plataforma
date: 2026-06-23
---

# Arquitetura da Plataforma

> Como o **hub de governança** se relaciona com os **produtos** e o **código**. Não é a arquitetura
> de um produto (essa vive em `products/<produto>/docs/architecture/`) — é o modelo do guarda-chuva.

## 1. Três camadas

```
GOVERNANÇA (este repo, versionado)        PRODUTOS (este repo, versionado)      CÓDIGO (repos próprios)
┌─────────────────────────────┐           ┌──────────────────────────┐          ┌───────────────────┐
│ docs/method  · SDD/TDD/AI    │  rege →   │ products/doctor-hub/     │  spec →  │ services/         │
│ docs/security· baseline LGPD │           │   docs/ specs/ design/   │          │  doctor-hub-api   │
│ docs/architecture (este doc) │           │   CLAUDE.md (produto)    │          │  doctor-hub-web   │
│ docs/decisions· ADR plataf.  │           │ products/<outro>/…       │          │  <outro>-…        │
│ specs/ (método + template)   │           └──────────────────────────┘          └───────────────────┘
│ CLAUDE.md (constituição-mãe) │                                                   (gitignorados aqui)
└─────────────────────────────┘
```

- **Governança** é transversal: muda raramente, vale para todos. Mudança → ADR de plataforma (P-xxx).
- **Produto** é um inquilino: domínio + regras de negócio + telas + decisões D-xxx próprias.
- **Código** vive em `services/<produto>-*` como **repos git separados** (D-110), gitignorados pelo
  hub. A **spec** (no produto) é a fonte da verdade; o código é artefato derivado.

## 2. Posição no ecossistema da empresa
A plataforma fica **a montante** de produtos existentes. O 1º produto, **Doctor-Hub**, alimenta a
**Teleconsulta** (`/home/alessandro/ptm/teleconsulta`) a jusante com agendamentos prontos — não a
substitui. A integração entre um produto e a Teleconsulta é **via banco**, sob o protocolo de
[`../security/security-baseline.md`](../security/security-baseline.md) §5 (PULL RO; PUSH com
allowlist + dry-run + `--apply`).

## 3. Multi-tenancy de governança
Um produto = uma pasta em `products/`. Isolamento: cada produto tem sua **constituição** (`CLAUDE.md`
que aponta de volta à raiz), seu **decisions-log** (D-xxx isolados por produto) e seu **RBAC**.
Nenhuma regra de negócio de um produto vaza para outro; o que é comum sobe para `docs/` (governança).

## 4. Stack baseline (recomendação de plataforma)
Para reduzir custo cognitivo de 1 dev + IA, a plataforma recomenda um stack único; cada produto o
**adota ou registra uma divergência**:
- **API:** .NET 10 + EF Core 10 + Dapper + PostgreSQL.
- **Web:** React + Vite + TypeScript + Tailwind + PWA mobile-first.
- **Infra:** GCP (Cloud Run + Cloud SQL + Secret Manager) — a confirmar com a infra da Portal.

## 5. Decisões que sustentam este modelo
- **P-001** — estrutura `governança + products/ + services/` (este doc). Ver
  [`../decisions/platform-decisions.md`](../decisions/platform-decisions.md).
- Origem (history do Doctor-Hub): **D-109** (build real, stack), **D-110** (spec-hub + services).
