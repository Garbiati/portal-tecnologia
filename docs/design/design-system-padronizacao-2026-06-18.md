# Doctor-Hub — Padronização do Design System (síntese multi-agente, 2026-06-18)

> Complementa `design-system.md` (marca + WCAG). Aqui está o **padrão concreto** para as 51 telas,
> gerado por 4 agents que analisaram o inventário REAL do Figma (`snTNGRUJO2GwoKpXTHCBjf`): 33 cores,
> 24 estilos de texto, 15 glyphs de ícone. Aplicar incrementalmente; propaga a TODAS as telas.

## 0. Invariantes (colar no topo do Figma)
1. **Radius:** input/badge/botão **8** · card/modal **12** · pill **999**. Um valor por categoria.
2. **Altura 40px** unifica input + botão (alinham lado a lado). Compacto (tabela/toolbar) = **32px**.
3. **1 ação primária (laranja) por tela/modal.** Resto = secondary/ghost. Destrutivo nunca é primária default.
4. **Footer de modal:** `[Cancelar] [Confirmar]`, primária à direita; destrutiva = danger.
5. **Números/moeda:** à direita, navy 600, tabular-nums. Categórico: esquerda.
6. **Padding:** célula 12×16 · card 24 · modal 24 · content 40.
7. **Sem zebra** — borda inferior `border/default` + hover `surface/page`.
8. **Ícones = componente `Icon` vetorial** (nunca emoji/glyph). `·`/`•` continuam como caractere.

## 1. Escalas base
- **Espaçamento (4pt):** 4 · 8 · 12 · 16 · 24 · 32 · 40 · 48.
- **Radius:** 8 (input/botão/badge) · 12 (card/modal) · 999 (pill).
- **Sombra:** card `0 1px 3px rgba(15,23,42,.08)` · modal `0 12px 32px rgba(13,20,31,.24)` · dropdown `0 4px 12px rgba(15,23,42,.12)`.

## 2. Cores — 20 tokens (33 → 20; marca intacta)
| Token | Hex | | Token | Hex |
|---|---|---|---|---|
| `text/primary` | #0f172a | | `brand/navy` | #054671 |
| `text/secondary` | #475569 | | `accent/default` | #0073bd |
| `text/muted` | #64748b | | `accent/hover` | #00609e |
| `text/disabled` | #94a3b8 | | `accent/subtle-bg` | #e6f1f8 |
| `text/on-brand` | #ffffff | | `action/default` | #b85410 |
| `surface/page` | #f8fafc | | `success/default` | #047857 |
| `surface/card` | #ffffff | | `success/subtle-bg` | #ecfdf5 |
| `surface/subtle` | #f1f5f9 | | `warning/default` | #b45309 |
| `surface/overlay` | #0d141f@45% | | `warning/subtle-bg` | #fffbeb |
| `border/default` | #e2e8f0 | | `danger/default` | #b91c1c |
| `border/strong` | #cbd5e1 | | `danger/subtle-bg` | #fef2f2 |

Neutros = **uma escala Slate**. Dups colapsadas: `#1f2938→text/primary` · `#64738b,#8c99ad→text/muted` ·
`#f7fafc,#f4f7fb→surface/page` · `#edf0f2,#e7eef3→surface/subtle` · `#e6f1fe→accent/subtle-bg` ·
`#b8850a→warning/default` · `#dc2626→danger/default`. Bordas status: `danger/border #fca5a5`, `warning/border #fde68a`.
> A confirmar: warning âmbar (#b45309) separado da ação laranja (#b85410) — papéis distintos. OK?

## 3. Tipografia — ramp (24 → 10). Montserrat só título/herói ≥16; Inter no resto.
| Estilo | Fonte | Peso | Tam | LH | Uso |
|---|---|---|---|---|---|
| `display` | Montserrat | SemiBold | 28 | 34 | nº-herói KPI (24/26/32) |
| `h1` | Montserrat | SemiBold | 18 | 24 | título de tela (17/18) |
| `h2` | Montserrat | SemiBold | 16 | 22 | título de card/seção |
| `h3` | Inter | Semi Bold | 14 | 20 | subtítulo, header de tabela (SB 14-18) |
| `body` | Inter | Regular | 13 | 20 | texto, célula, valor (Reg 13/14) |
| `body-strong` | Inter | Semi Bold | 13 | 20 | ênfase, valor destacado (SB 12/13) |
| `label` | Inter | Medium | 12 | 16 | rótulo, chip, botão, menu (Med 12-15) |
| `label-strong` | Inter | Semi Bold | 11 | 16 | header UPPERCASE, badge, tab |
| `caption` | Inter | Regular | 11 | 16 | hint, timestamp (Reg 10/11/12) |
| `num-tabular` | Inter | Medium | 13 | 20 | colunas numéricas (tabular-nums) |
Heurística: **Montserrat = "olhe aqui"; Inter = "leia/opere". < 16px é sempre Inter.**

## 4. Ícones — componente `Icon` vetorial (resolve emoji 🔒×62, 🗑×4, ✎×4)
- **Componente único `Icon`** com variant `name` → 13 vetores: `edit · trash · lock · check · alert · info ·
  arrow-right · arrow-left · chevron-down · plus · close · radio-on · radio-off` (+ `dot-status` filled).
- **Padrão:** grid 24×24, área 20×20, **stroke 1.75px** round, **sem fill** (exceto dot). Cor via token, herda do
  texto; exceções trash/alert→danger, check→success, dot→status.
- **Tamanhos:** sm 16 (inline) · md 20 (ação) · lg 24 (destaque).
- **`·` (U+00B7) e `•` (U+2022) continuam TEXTO** (`text/muted`).
- Formas: Feather/Lucide (MIT) via `createNodeFromSvg`.

## 5. Componentes — specs
- **Tabela:** linha 48 (header 40) · padding 12×16 (externa 24) · header `surface/subtle` + `label-strong` uppercase ·
  só borda inferior, sem verticais/zebra, hover `surface/page` · número/$ direita navy 600 · **ações: última coluna fixa 80-120px, ícones ghost 32×32 gap 8**.
- **Modal:** confirmação 440 · form 520 · form largo 640. Overlay 45%. Card radius 12, padding 24. Header(h1+close ghost)→16→body→24→footer(direita, gap 12, [Cancelar][Confirmar]).
- **Botões:** altura 40 (compacto 32) · padding 0×18 · radius 8 · label/13-600 · gap 8. primary(action) · secondary(card+borda) · danger · ghost/outline(accent) · ghost-icon. hover −8%, focus ring 2px action, disabled .5.
- **Badge:** padding 4×10 · radius 999 · label-strong/11. info(navy+accent-subtle) · sucesso · aviso · perigo · neutro(text-secondary+surface-subtle). Status = `Icon/dot-status` na cor do texto.
- **Card:** radius 12, padding 24 (16), sombra card. Título h2 navy, gap 16, entre cards 24-32. Table-card: tabela encosta nas bordas.
- **Campo:** label-strong uppercase text/muted mb8 · input h40 bg surface/page borda default radius 8 padding 0×12 body/14 placeholder text/disabled · gap 16 · focus borda action+ring · disabled surface/subtle · erro borda danger+caption · travado = disabled + `Icon/lock`.

## 6. Ordem de aplicação
1. Coleção de variáveis **Tokens** (cores) + estilos de texto (ramp). 2. Componente **`Icon`** (13 vetores).
3. Trocar emoji/glyph → `Icon`. 4. Reapontar cores/tipos avulsos → tokens/estilos. 5. Normalizar tabela/modal/botão/badge/card.
> Regra permanente: toda mudança propaga a TODAS as telas/variantes/duplicatas.
