# Produtos da plataforma — Registry

> Cada produto da empresa que roda sobre a plataforma tem **uma pasta** aqui
> (`products/<produto>/`) com sua própria constituição (`CLAUDE.md`), `docs/`, `specs/` e (quando
> houver) `design/`. O **código** vive em `services/<produto>-*` (repos git separados, gitignorados).
>
> Regra de coerência: **este registry lista exatamente os produtos que têm pasta em `products/`**.
> Nada de produto-fantasma; cada produto ativo tem `CLAUDE.md` + `README.md`.

| Produto | Status | Pasta | Services | Constituição | Dono |
|---|---|---|---|---|---|
| **Doctor-Hub** — planejamento de capacidade médica (oferta × demanda) | 🟢 Build real (Fase 6) | [`doctor-hub/`](doctor-hub/CLAUDE.md) | `doctor-hub-api` (.NET 10), `doctor-hub-web` (React PWA) | [CLAUDE.md](doctor-hub/CLAUDE.md) | Alessandro |
| _Teleconsulta_ | ⚪ Candidato (vive em `../teleconsulta`) | — | — | — | — |
| _Telediagnóstico_ | ⚪ Candidato (não iniciado) | — | — | — | — |
| _Dados_ | ⚪ Candidato (não iniciado) | — | — | — | — |

**Legenda:** 🟢 ativo · 🟡 em discovery · ⚪ candidato/não iniciado.

## Onboard de um produto novo
Ver "Como adicionar um produto" na constituição raiz ([`../CLAUDE.md`](../CLAUDE.md)) e o scaffold em
[`_template/`](_template/). Resumo: copie `_template/` → `products/<produto>/`, preencha o `CLAUDE.md`,
crie a `docs/discovery/` antes das specs, registre aqui e em
[`../docs/decisions/platform-decisions.md`](../docs/decisions/platform-decisions.md).
