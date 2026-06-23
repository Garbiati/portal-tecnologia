---
title: Estimativa — Desenvolvimento Normal × AI Coding
status: draft
date: 2026-06-14
gerado_por: rascunho automático (a validar com Alessandro)
---

# Estimativa: Desenvolvimento Normal × AI Coding

## Parâmetros confirmados pelo Alessandro (2026-06-14)
- **Tier alvo:** Tier 2 (Entrega 1 completa)
- **Valor/hora:** R$180
- **Dedicação:** 4h em dias úteis + 6h no fim de semana = **10h úteis/semana**
- **Contingência:** 25% · **Câmbio:** US$1≈R$5,50 (verificar)

## Como modelo "normal" × "AI coding"
- As horas do backlog (`01-spec-backlog.md`) já foram estimadas como **1 dev + IA** → são a coluna **AI coding**.
- **Desenvolvimento normal** (sem IA) = AI coding **+ ~35%** (faixa +25% a +45%).
- ⚠️ **Este delta é o número MAIS INCERTO de toda a estimativa.** A pesquisa (`docs/method/`) mostra:
  o ganho da IA **concentra-se em boilerplate/CRUD/UI/testes/docs**, e é **fraco ou negativo** na lógica
  complexa de domínio (o motor de alocação) e no debug de integração, onde ainda há "imposto de verificação"
  (METR 2025: experts ficaram mais lentos em código complexo). Ou seja: a economia é real nas telas e na
  infra, pequena no núcleo. Trate o delta como faixa, não como garantia.

## Esforço (horas)
| | AI coding (provável) | Normal (provável, +35%) |
|---|---|---|
| 🟢 Tier 1 | ~330h | ~445h |
| 🟡 **Tier 2** | **~650h** | **~880h** |

## Prazo a 10h/semana (o ponto crítico)
| | AI coding | Normal |
|---|---|---|
| 🟢 Tier 1 | ~33 sem (**~7,5 meses**) | ~44 sem (**~10 meses**) |
| 🟡 **Tier 2** | ~65 sem (**~15 meses**) | ~88 sem (**~20 meses**) |

> A 10h/semana, **Tier 2 leva ~15 meses mesmo com AI coding** (~20 meses sem). Isso é consequência direta
> da dedicação, não do escopo. Ver "Alavancas de prazo" abaixo.

## Custo de mão de obra e PREÇO (R$180/h, contingência 25%)
`Preço = horas × 180 × 1,25 + pass-through`

| | AI coding | Normal |
|---|---|---|
| 🟢 Tier 1 | ~R$79.000 | ~R$105.000 |
| 🟡 **Tier 2** | **~R$156.000** | **~R$208.000** |

(pass-through de IA/infra: ~R$5–10k, pequeno; no "normal" não há custo de assinatura de IA, mas a duração maior
eleva infra — no líquido a diferença de pass-through é desprezível frente à mão de obra.)

## O que o comparativo mostra
- **AI coding economiza ~R$50k e ~5 meses no Tier 2** neste modelo — **mas** a economia vem das telas/infra,
  não do motor de alocação. Não conte com IA para acelerar a parte difícil.
- A **dedicação** é a maior alavanca de prazo, muito mais que normal × IA.

## 🎚️ Alavancas de prazo (a 10h/sem, Tier 2 = ~15 meses)
1. **Aumentar horas/semana** — a 20h/sem, Tier 2 AI cai para ~33 sem (~7,5 meses).
2. **Começar pelo Tier 1** — entrega valor e integração com a TC em ~7,5 meses (10h/sem) e fatura antes;
   Tier 2 vira evolução paga.
3. **Cortar mais para a Fase 2** — reduzir o escopo da 1ª entrega.

## Recomendação
Dado 10h/semana: **fazer Tier 1 primeiro como Entrega 1** (fatura ~R$79k em ~7,5 meses, valida tudo cedo),
e **Tier 2 como Entrega 2** (aditivo). Fechar Tier 2 inteiro como primeira entrega a 10h/semana significa
**~15 meses até o primeiro faturamento cheio** — risco alto de fôlego/caixa para 1 pessoa.
