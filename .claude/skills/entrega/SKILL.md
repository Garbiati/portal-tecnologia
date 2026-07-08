---
name: entrega
description: Checklist de "pronto para subir" — roda os gates da casa (testes, check:ui, coerência, segurança/LGPD) antes de commitar/pushar. Use antes de todo push. Orquestra os revisores baratos (sonnet) e só entrega com tudo verde.
---

# /entrega — gate de "sobe ou não sobe"

Segurança é o **gate de release** (P-014): achado 🔴 = não sobe. Rode esta sequência antes
de commit/push. Delegue as varreduras (não gaste Opus); a decisão final é do orquestrador + humano.

## Sequência

1. **Testes verdes** — `dotnet test` (api) e/ou `pnpm test` (web) no service tocado.
2. **Design system** (se mexeu no web) — `pnpm check:ui` (roda dentro do `pnpm build`).
3. **Coerência** (se mexeu em telas) — `/coerencia` (agent `revisor-adversarial`).
4. **Segurança/LGPD do diff** — delegue ao agent `revisor-seguranca`: segredo, dado de
   paciente/CPF, pacote novo suspeito, violação de baseline (least-privilege, D-069).
   Veredito **BLOQUEAR** = não sobe até corrigir.
5. **Revisão humana das invariantes** — se o diff toca capacidade/escala/alocação/status
   financeiro, Alessandro revisa (security.md §4 — núcleo crítico não é delegado cegamente).
6. **Commit + push** — mensagem descritiva; push só para `Garbiati/`. Só depois de 1–5 verdes.

## Regra

Nunca dizer "pronto"/"subi" sem 1–5. Se algum gate não rodou, diga qual e por quê — não
maquiar. O Alessandro não deve descobrir um furo que um gate pegaria.
