# Registro de Decisões de PLATAFORMA (ADR — P-xxx)

> Decisões **transversais** que valem para todos os produtos. Confirmadas por humano. Mudança passa
> por novo registro. Decisões **específicas de um produto** ficam no decisions-log do produto
> (ex.: `products/doctor-hub/docs/decisions/decisions-log.md`, série D-xxx).

| ID | Decisão | Confirmado em | Notas / impacto |
|----|---------|---------------|-----------------|
| **P-002** | **Identidade: `portal-platform` = repo oficial de governança da empresa (Portal Telemedicina); polyrepo via manifest, não submodules.** (1) O hub é **renomeado `ptm-platform` → `portal-platform`** e reposicionado como **guarda-chuva de TODA a empresa** (não só dos produtos hospedados aqui): teleconsulta, telediagnóstico, doctor-hub, dados etc. ficam **abaixo** dele. Remote: `git@github.com:PortalTelemedicina/portal-platform.git`. (2) **Modelo polyrepo**: cada repo é independente; a linkagem oficial é o **manifest [`repos.yml`](../../repos.yml)** + catálogo — **descartados git submodules** (acoplam versão, DX ruim) e **true-monorepo** (juntaria tudo num git). (3) `make workspace` (scripts/workspace.sh) clona/atualiza os repos com `url` confirmada num **`workspace/` gitignored** (visão local de DEV). (4) Catálogo factual: só `portal-platform` e `teleconsulta` têm url verificada; demais marcados `confirmar: true` (não inventar URL — Diretriz Suprema). | 2026-06-23 | Confirmado por Alessandro (criou o repo `PortalTelemedicina/portal-platform`; 2 perguntas: linkagem = manifest+registry; nome = portal-platform governança≠produto; +1 ajuste: teleconsulta/telediagnóstico ficam **abaixo** do portal-platform). **Estende P-001.** |
| **P-001** | **Governança multi-produto: `governança (raiz) + products/ + services/`.** O `ptm-platform` deixa de ser Doctor-Hub-cêntrico e passa a ser **hub de governança da plataforma**. (1) A governança transversal sobe à raiz: `docs/method/` (SDD/TDD/AI-coding), `docs/security/security-baseline.md`, `docs/architecture/platform-architecture.md`, `docs/decisions/platform-decisions.md`, `specs/` (só método + template). (2) Cada produto vira um inquilino em `products/<produto>/` com `CLAUDE.md` próprio, `docs/`, `specs/`, `design/`. (3) **Doctor-Hub** vira o 1º produto (`products/doctor-hub/`), com todo o seu conteúdo (discovery, product, design, business, architecture 00–02, decisions-log D-001..D-110, specs de feature) **movido via `git mv`** (histórico preservado). (4) Onboarding de produto novo via `products/_template/` + registry `products/README.md`. | 2026-06-23 | Confirmado por Alessandro (2 perguntas: foco = camada de governança multi-produto; pode reorganizar de fato). **Estende** D-110 (spec-hub + services) e D-109 (build real/stack), que continuam válidos como história do Doctor-Hub. Stack .NET/React/GCP promovido a **baseline recomendado de plataforma**. |

## Como registrar uma decisão de plataforma
1. A decisão precisa ser **transversal** (afeta mais de um produto ou o hub em si). Se é só de um
   produto, registre no decisions-log daquele produto.
2. Adicione uma linha **P-xxx** acima, com `✅ Confirmado por <humano> em <data>` e o impacto.
3. Se a decisão muda a estrutura, atualize também `CLAUDE.md` (raiz) e
   [`../architecture/platform-architecture.md`](../architecture/platform-architecture.md).
