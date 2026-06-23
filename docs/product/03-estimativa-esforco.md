---
title: Estimativa de Esforço e Prazo
status: draft
date: 2026-06-14
gerado_por: rascunho automático (a validar com Alessandro)
---

# Estimativa de Esforço & Prazo

> ⚠️ Estamos no fim da **Descoberta**. Pela "Cone of Uncertainty", estimativas aqui têm faixa larga
> (tipicamente −25% a +50%). Os números abaixo são **horas-ideais 1 dev + IA** (spec+teste+código+revisão),
> sem reuniões/contexto-switch. Tratar como faixa, não como promessa de relógio.

## Premissas (EXPLÍCITAS — me corrija quando voltar)
- P1 — **1 desenvolvedor** (você) + Claude Code interativo. Sem time.
- P2 — Stack ainda **não escolhida** (D-001); estimativa é agnóstica. Stack muito nova pra você pode +15–25%.
- P3 — **Não conto "mágica de IA"**: a pesquisa (METR/DORA) mostra que IA não acelera expert em código
  complexo de forma garantida e cobra "imposto de verificação". O ganho de IA já está embutido no fato
  de as horas-ideais serem enxutas — não aplico desconto extra por cima.
- P4 — Dependências externas (time da TC emitir `PartnerType`/API-key; acesso a homologação) **não** estão
  no meu controle e podem adicionar espera (não horas, mas prazo).
- P5 — Descoberta/método já feitos nesta semana **não** estão recontados aqui (já entregues).

## Esforço por tier (horas)
| Tier | Otimista (−20%) | **Provável** | Pessimista (+35%) |
|---|---|---|---|
| 🟢 Tier 1 — Núcleo ponta-a-ponta | ~265h | **~330h** | ~445h |
| 🟡 Tier 2 — Entrega 1 completa | ~520h | **~650h** | ~875h |
| 🔵 Fase 2 (referência) | — | ~250–400h | — |

## Prazo (depende de quantas horas/semana você dedica)
| Dedicação | Tier 1 (~330h) | Tier 2 (~650h) |
|---|---|---|
| **Meio período** (~20h úteis/sem) | ~16–17 semanas | ~32 semanas |
| **Quase integral** (~36h úteis/sem) | ~9–10 semanas | ~18 semanas |

> "Horas úteis" ≠ horas no relógio. Mesmo "full-time", ~6h/dia de foco real é o realista (o resto é
> contexto, espera de homologação, revisão). Por isso 36h úteis/semana já assume ~7–8h de relógio/dia.

## Recomendação
- Começar pelo **Tier 1** (menor risco, valor ponta-a-ponta cedo, valida a integração com a TC logo).
- Promover para **Tier 2** após o Tier 1 estar aceito e em homologação.
- Reservar **20–30% de contingência** no preço (a faixa pessimista existe por bons motivos: integração
  externa, LGPD, e a granularidade do estoque ainda em aberto).

## 🗓️ Gates semanais (cadência de validação)
Toda **sexta** (sugestão), um gate de ~30–45 min:
1. **Demo do que avançou** — specs que passaram de `specified → tested → implemented` (visível no `STATUS.md`).
2. **Aceite** das specs concluídas (você valida que "resolve a dor", não só "funciona").
3. **Revisão do backlog** e replanejamento da semana seguinte.
4. **Log de mudanças** — qualquer PM aprovado/recusado (`change-requests.md`).
5. **Gatilho de pagamento** (se atrelado a milestone — ver `04-custo-e-proposta.md`).

> Cada gate é também o ponto onde o "humano valida e a IA aprende": correções viram regra em
> `CLAUDE.md`/skills/hooks. Quanto mais gates, mais o repo fica calibrado ao negócio.

## O que muda esta estimativa (sensibilidade)
- ➕ Volume alto (muitos HCs/estados, isolamento forte de dados) → +RBAC/+infra.
- ➕ Granularidade do estoque = "horário concreto" (vs contagem) → +Épico B e +E.
- ➕ Stack nova pra você → +setup/aprendizado.
- ➖ Aceitar Tier 1 e empurrar mais itens pra Fase 2 → −esforço imediato.
