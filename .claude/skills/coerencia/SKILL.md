---
name: coerencia
description: Roda a REVISÃO DE COERÊNCIA do Doctor-Hub (os 3 pilares — dados/navegação/ciclo de vida de tela) antes de entregar qualquer conjunto de telas. Exigida pelo CLAUDE.md do produto. Delega a varredura ao revisor-adversarial (sonnet).
---

# /coerencia — gate de coerência do protótipo (Doctor-Hub)

O Alessandro homologa por screenshot no celular e **não deve caçar furo**. Antes de dizer
"pronto" para telas, rode esta revisão (regra dura do `products/doctor-hub/CLAUDE.md`).

## Como rodar

1. **Delegue ao agent `revisor-adversarial`** (sonnet — não gaste Opus nisto). Prompt
   auto-contido: quais telas/rotas mudaram, e o critério dos 3 pilares:
   - **(a) Dados** — união dos filtros = total; mesma entidade = mesmos atributos em todas
     as telas; tudo derivado da fixture canônica (`docs/product/22-demo-fixtures.md`), nada à mão.
   - **(b) Navegação** (`23-navegacao-contrato.md`, D-106) — isolamento de persona (troca só
     pelo avatar→Seletor; nenhum link cruza Demandas↔Regulação↔Gestor), toda tela alcançável
     do Login, 0 cliques mortos, 0 órfãs.
   - **(c) Ciclo de vida de tela** (`24-registro-telas.md`, D-108) — 1 tela canônica por
     intenção; nenhuma "v2" convivendo com "v1"; grep por `PROVISÓRIO`; mesmo rótulo → mesmo destino.
2. **Verifique o relatório** (orquestrador). Furo que bloqueia demo → conserte (ou delegue ao
   `implementador`) antes de entregar. Cosmético → decida com o Alessandro.
3. Só diga "pronto" com `pnpm test` e `pnpm check:ui` verdes **e** este gate limpo.
