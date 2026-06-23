---
title: Custo & Modelo de Proposta de Preço
status: draft
date: 2026-06-14
gerado_por: rascunho automático (a validar com Alessandro)
---

# Custo & Proposta de Preço

> ⚠️ **Nada aqui é preço final.** Seu **valor/hora** é a variável que você define. Câmbio assumido
> **US$1 ≈ R$5,50** (verificar). Preços de IA conforme `docs/method/ai-coding-sdd-report.md` (2026-06-14).
> A mão de obra **domina** o custo; IA + infra são pequenos.

## 1. Custos de IA, ferramentas e infraestrutura (pass-through)

**IA (Claude Code interativo — coberto por assinatura, D-007):**
- Plano **Max 5x ≈ US$100/mês** atende a maioria; uso pesado pode exigir **Max 20x (~US$200/mês)** (a verificar).
- Referência da pesquisa: ~US$150–250/dev/mês em uso intenso. **Atenção:** automações via Agent SDK/`claude -p`
  (se você adotar) saem da assinatura e viram crédito a preço de API (mudança 15/06/2026). Na Entrega 1 usamos
  só o modo interativo → fica na assinatura.

**Ferramentas:** Obsidian, MkDocs, VS Code, Gitleaks/TruffleHog (OSS) = **R$0**. ClickUp/Figma você já tem.

**Infra (homolog + prod):** nuvem modesta p/ 1 sistema de baixo volume inicial ≈ **US$30–80/mês** + domínio.

| Tier (duração ~) | IA | Infra | **Pass-through total (faixa)** |
|---|---|---|---|
| 🟢 Tier 1 (~2–4 meses) | US$300–600 | US$90–320 | **≈ US$400–900 (R$2,2k–5,0k)** |
| 🟡 Tier 2 (~4–8 meses) | US$600–1.200 | US$180–640 | **≈ US$800–1,8k (R$4,4k–10k)** |

## 2. Custo de mão de obra (a maior parcela)

`Custo de MO = horas-prováveis × seu valor/hora.` Tabela de referência (horas-prováveis: Tier 1=330, Tier 2=650):

| Valor/hora | Tier 1 (330h) | Tier 2 (650h) |
|---|---|---|
| R$100 | R$33.000 | R$65.000 |
| R$150 | R$49.500 | R$97.500 |
| R$200 | R$66.000 | R$130.000 |
| R$250 | R$82.500 | R$162.500 |

> Esses são **custos**, não preço. O preço inclui contingência/risco e sua margem (abaixo).

## 3. Modelo de PREÇO (recomendado: escopo fixo + controle de mudança)

```
Preço fixo = (horas-prováveis × valor/hora) × (1 + contingência)  +  pass-through
contingência recomendada = 20–30% (cone de incerteza + integração externa + LGPD + estoque em aberto)
```

**Exemplos trabalhados** (contingência 25%, câmbio R$5,50, pass-through no topo da faixa):
| Cenário | Cálculo | **Preço ≈** |
|---|---|---|
| Tier 1 @ R$150/h | 330×150×1,25 + R$5k | **≈ R$67.000** |
| Tier 1 @ R$200/h | 330×200×1,25 + R$5k | **≈ R$87.500** |
| Tier 2 @ R$150/h | 650×150×1,25 + R$10k | **≈ R$132.000** |
| Tier 2 @ R$200/h | 650×200×1,25 + R$10k | **≈ R$172.500** |

> Troque o valor/hora pelo seu e recalcule. Se for **revenda** (você cobra de um cliente final com margem
> sobre seu custo), adicione a margem desejada por cima do custo, não sobre o preço.

## 4. Pagamento atrelado aos gates (protege os dois lados)
- **20% na mobilização** (assinatura + setup + Fundação começa).
- **Parcelas por milestone aceito** nos gates semanais/quinzenais (proporcional aos épicos entregues e **aceitos**).
- **10% de retenção** liberados no aceite da homologação (Entrega 1 rodando ponta-a-ponta na TC).
- Todo **Pedido de Mudança** aprovado vira aditivo (não consome o orçamento congelado).

## 5. Modalidade — recomendação
- **Escopo fixo + controle de mudança** (este modelo): bom quando o escopo está claro (estamos quase lá) e
  o cliente quer previsibilidade. A contingência te protege.
- Alternativa **Time & Materials** (horas medidas): melhor se o escopo ainda vai mexer muito. Menos previsível
  para o cliente, menos risco para você.
- Para healthcare/governo, **escopo fixo por tier + aditivos** costuma ser o mais vendável.

## 6. ❗ Premissas que preciso que você confirme quando voltar
1. Seu **valor/hora** (ou faixa) — destrava o preço real.
2. **Tier** escolhido para a Entrega 1 (recomendo Tier 1 → depois Tier 2).
3. **Dedicação semanal** (meio período vs integral) — define o prazo.
4. É **projeto próprio** (você fatura um cliente) ou **trabalho interno** (PTM)? Muda margem vs custo.
5. **Câmbio** e se prefere mostrar preço em R$ ou US$.
6. Prazo-alvo do cliente, se houver (pode forçar Tier 1 e mais coisas pra Fase 2).
