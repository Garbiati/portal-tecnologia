# Componentes — Saúde Digital · Demandas (HTML + CSS)

Biblioteca de componentes em **HTML + CSS puro** (sem JavaScript, sem framework),
derivada 100% de [`../tokens.css`](../tokens.css) e [`../design-system.md`](../design-system.md).
Espelha o board **“UI Kit”** do Figma. Conformidade **WCAG 2.2 AA**.

> Regra de ouro: **nunca** usar hex/medidas soltas no código. Sempre `var(--token)`.
> Trocar a marca no futuro = remapear tokens, sem tocar nos componentes.

## Arquivos

| Arquivo | Papel |
|---|---|
| `components.css` | A biblioteca. Importa `../tokens.css` no topo via `@import`. |
| `index.html` | Galeria viva: cada componente em **todos os estados**. Carrega Inter + os dois CSS. |
| `README.md` | Este guia. |

## Como usar

1. Garanta que `tokens.css` está acessível (a galeria importa `../tokens.css`).
2. Em qualquer página, carregue **a fonte Inter** e o CSS:

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="design/components/components.css" />
<!-- components.css já faz @import "../tokens.css"; ajuste o caminho se necessário. -->
```

3. Aplique as classes no HTML. Exemplos rápidos:

```html
<!-- Botão primário com estado de carregamento -->
<button class="btn btn--primary is-loading">Salvando</button>

<!-- Campo com erro -->
<label class="field">
  <span class="field-label">CRM <span class="req">*</span></span>
  <input class="input is-error" aria-invalid="true" aria-describedby="e1" />
  <span class="field-error" id="e1">CRM inválido.</span>
</label>

<!-- KPI de alerta -->
<div class="kpi kpi--warning">
  <span class="kpi__label">Janela em risco</span>
  <span class="kpi__value">7</span>
</div>
```

### Estados via classe (o app/JS aplica/remove)

- `.is-loading`, `.is-disabled` (ou atributo nativo `disabled`) — botões/chips
- `.is-error` — campos de formulário (pareie com `aria-invalid` e `.field-error`)
- `.is-active` — nav item selecionado
- `.is-on` — chip ligado (pareie com `aria-pressed`)
- `.is-selected`, `.is-empty` — linhas/estados de tabela
- Variantes: `--primary/--secondary/--danger/--subtle/--sm` (btn), `--neutral/--info/--success/--warning/--danger` (badge/kpi/toast)

## Mapa componente → classe CSS → tokens principais

| Componente | Classe(s) | Tokens usados |
|---|---|---|
| Button | `.btn` `.btn--primary/--secondary/--danger/--subtle/--sm` `.is-loading` `[disabled]` | `--control-height(-sm)`, `--color-accent(-hover)`, `--color-danger`, `--color-accent-subtle/-text`, `--color-surface(-muted)`, `--color-border-strong`, `--radius-md/-sm`, `--text-base/-sm`, `--space-*`, `--focus-ring-width`, `--color-focus-ring` |
| Label / hint / erro | `.field` `.field-label` `.field-hint` `.field-error` | `--text-sm/-xs`, `--lh-xs`, `--color-text-secondary/-muted`, `--color-danger` |
| Input | `.input` `.is-error` `.input-group` `.input-icon` | `--control-height`, `--color-surface(-muted)`, `--color-border-strong`, `--color-accent`, `--color-danger(-bg)`, `--radius-md`, `--text-base`, `--space-*`, foco AA |
| Select | `.select` `.is-error` | idem Input + `--color-text-secondary` (chevron) |
| Textarea | `.textarea` `.is-error` | idem Input + `--lh-md` |
| Checkbox | `.checkbox` + `input` | `--control-height`, `--color-accent`, `--color-border-strong`, `--color-surface`, `--color-text-on-accent`, `--radius-sm`, foco AA |
| Radio | `.radio` + `input` | idem Checkbox + `--radius-full` |
| Switch | `.switch` + `input` | `--color-accent`, `--color-border-strong`, `--color-surface`, `--radius-full`, `--shadow-sm`, foco AA |
| Badge / Tag | `.badge` `.badge--neutral/--info/--success/--warning/--danger` `.dot` | `--slate-100`, `--color-accent-subtle/-text`, `--color-success(-bg)`, `--color-warning(-bg)`, `--color-danger(-bg)`, `--radius-full`, `--text-xs` |
| Card | `.card` `.card--interactive` `.card__title/__body/__footer` | `--color-surface`, `--color-border(-strong)`, `--radius-xl`, `--shadow-sm/-md`, `--space-5`, `--text-md`, foco AA |
| Table | `.table-wrap` `.table` `.table--stack` `.row` `.is-selected` `.is-empty` | `--color-surface(-muted)`, `--color-border`, `--color-accent-subtle`, `--radius-xl/-lg`, `--text-base/-sm`, `--space-*` |
| KPI Stat | `.kpi` `.kpi--info/--success/--warning/--danger` `.kpi__label/__value/__delta` | `--color-surface`, `--color-border(-strong)`, `--color-accent(-text)`, `--color-success/-warning/-danger`, `--radius-xl`, `--text-2xl/-sm/-xs` |
| Chip (toggle) | `.chip` `.is-on` `[disabled]` | `--control-height-sm`, `--color-surface(-muted)`, `--color-border-strong`, `--color-accent(-text)`, `--color-accent-subtle`, `--radius-full`, foco AA |
| Nav item | `.nav-item` `.is-active` `.nav-item__icon` | `--control-height`, `--color-text-secondary`, `--color-accent(-text)`, `--color-accent-subtle`, `--color-surface-muted`, `--radius-md`, foco AA |
| Sidebar | `.sidebar` `.sidebar__brand/__section` | `--sidebar-width`, `--topbar-height`, `--color-surface`, `--color-border`, `--text-xs/-md`, `--space-*` |
| Topbar | `.topbar` `.topbar__title/__spacer/__actions/__menu-btn` | `--topbar-height`, `--control-height`, `--color-surface`, `--color-border`, `--text-lg`, foco AA |
| Toast | `.toast` `.toast--success/--error` `.toast__icon/__body/__title/__close` `.toast-stack` | `--color-surface`, `--color-success/-danger/-text-secondary`, `--shadow-lg`, `--radius-lg`, `--text-sm`, `--space-*` |
| Empty state | `.empty-state` `.empty-state__icon/__title/__desc/__actions` | `--color-surface-muted`, `--color-text(-secondary/-muted)`, `--radius-full`, `--text-md/-base`, `--space-*` |
| Skeleton | `.skeleton` `.skeleton--text/--title/--line/--circle/--btn` | `--slate-100/-200`, `--radius-sm/-md/-full`, `--control-height` |
| App shell | `.app-shell` `.app-main` | `--sidebar-width`, `--topbar-height`, `--space-6`, breakpoints |

## Acessibilidade (WCAG 2.2 AA)

- **Foco visível (2.4.7):** todo elemento interativo recebe anel
  `outline: var(--focus-ring-width) solid var(--color-focus-ring)` com `offset 2px`,
  via `:focus-visible` (não aparece em clique de mouse, só em teclado).
- **Alvos de toque (2.5.8):** botões, inputs, nav-items, checkbox/radio/switch e linha
  de chip têm altura mínima `var(--control-height)` (44px). O chip usa o tamanho compacto
  `--control-height-sm` (36px), reservado a contextos densos de desktop.
- **Contraste:** garantido pelos tokens — texto `≥4.5:1`, UI/large `≥3:1` (ver tabela em
  `../design-system.md`). Não usar texto branco sobre `--color-accent-subtle`, nem
  `--color-text-muted` em texto crítico < 14px.
- **Erros de formulário:** combine `.is-error` com `aria-invalid="true"` e
  `aria-describedby` apontando para a `.field-error` (que traz ícone ⚠ via CSS).
- **Estados não dependem só de cor:** badges/toasts trazem ícone/rótulo; chip e nav usam
  `aria-pressed`/`aria-current` no HTML do app.
- **Touch:** hover de tabela e chip fica sob `@media (hover: hover)` — nada de hover-only.
- **Movimento:** `@media (prefers-reduced-motion: reduce)` neutraliza shimmer e spinners.
- **Mobile:** inputs sobem para `16px` abaixo de `768px` (evita zoom automático do iOS);
  tabelas com `.table--stack` viram cards empilhados.

## Responsividade

Mobile-first, com os breakpoints do `tokens.css`: `sm 640 · md 768 · lg 1024 · xl 1280 · 2xl 1440`.
Pontos de quebra implementados: inputs 16px (`<768`), tabela em cards (`<768`),
sidebar/shell colapsam (`<1024`), hamburger na topbar (`<1024`), toasts full-width (`<640`).
