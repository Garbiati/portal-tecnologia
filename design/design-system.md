---
title: Design System — Saúde Digital · Demandas
status: draft
date: 2026-06-14
a11y: WCAG 2.2 AA
---

# Design System (máxima fidelidade · zero inferência)

> Objetivo: que a IA construa front-end **sem inferir nada**. Tokens em `tokens.css`/`tokens.json`
> são a fonte da verdade; este doc define **componentes, estados, responsividade e regras de uso**.
> Identidade **neutra por agora** (tokenizada → trocar a marca depois é só remapear tokens).

## 1. Princípios
- **Tokens primeiro.** Nenhum hex/medida solta no código — sempre `var(--token)`.
- **WCAG 2.2 AA.** Contraste ≥4.5:1 (texto), ≥3:1 (UI/large); foco visível; alvos ≥44px.
- **Auto-layout/flex.** Layout por composição, não posição absoluta.
- **Mobile-first responsivo** (decisão: tudo responsivo, todos os papéis).

## 2. Cor & contraste (verificado sobre branco)
| Token | Hex | Uso | Contraste |
|---|---|---|---|
| `--color-text` | #0F172A | títulos, corpo forte | 17.4:1 ✓AAA |
| `--color-text-secondary` | #475569 | rótulos, texto de apoio | 7.5:1 ✓AAA |
| `--color-text-muted` | #64748B | placeholder, meta | 4.8:1 ✓AA |
| `--color-accent` (#2563EB) | botões/fills; texto branco | 5.2:1 ✓AA |
| `--color-accent-text` (#1D4ED8) | links/texto pequeno | 6.4:1 ✓AA |
| status success/danger/warning | texto *-700 sobre fundo *-50 | ✓AA |

> ⚠️ Nunca usar `--color-text-muted` para texto < 14px crítico; nunca texto branco sobre `--color-accent-subtle`.

## 3. Tipografia
Família **Inter**. Escala: `xs 12 / sm 13 / base 14 / md 15 / lg 18 / xl 22 / 2xl 26` (line-height no token).
Pesos: regular 400, medium 500, semibold 600. Sem itálico no produto.
- Título de página: `2xl/semibold`. Título de card: `md/semibold`. Corpo: `base/regular`. Rótulo: `sm/medium`. Meta: `xs/regular muted`.

## 4. Espaçamento & raio
Base 4px (`--space-*`). Padding de card: `--space-5` (20). Gap de seção: `--space-5/6`. Raio: inputs/botões `--radius-md/lg`, cards `--radius-xl`, pills `--radius-full`.

## 5. Componentes (a construir como Figma Components + variantes)
Cada um terá **variantes** e **estados** explícitos (nada inferido):

| Componente | Variantes | Estados |
|---|---|---|
| **Button** | primary, secondary(ghost), danger, subtle · size md/sm · iconLeft? | default, hover, active, focus, disabled, loading |
| **Input / Select / Textarea** | text, select, search · com/sem ícone | default, focus, filled, error, disabled, read-only |
| **Checkbox / Radio / Switch** | — | default, checked, focus, disabled |
| **Badge / Tag** | neutral, info(azul), success, warning, danger | — |
| **Card** | default, interactive | hover (se clicável) |
| **Table** | — | header, row, row-hover, selected, **empty**, loading(skeleton) |
| **KPI Stat** | neutral, success, warning, danger | — |
| **Chip (toggle)** | — | on, off, focus, disabled |
| **Nav item** | — | default, hover, **active**, focus |
| **Sidebar / Topbar / Drawer** | desktop, collapsed, mobile | — |
| **Modal / Drawer / Toast** | — | open, closing |
| **Tabs / Breadcrumb / Pagination** | — | active, hover, focus |
| **Empty state / Error state / Skeleton** | — | — |

## 6. Estados obrigatórios (que faltavam na Semana 1)
- **Foco** visível em todo elemento interativo: outline `--focus-ring-width` `--color-focus-ring` (offset 2px).
- **Erro de formulário**: borda `--color-danger`, mensagem `xs` em `--color-danger`, ícone.
- **Vazio**: ilustração simples + texto + ação (ex.: "Nenhuma vaga emitida ainda").
- **Loading**: skeleton para tabelas/cards; spinner no botão `loading`.
- **Feedback de ação**: toast de sucesso/erro após Salvar/Emitir/Assumir.

## 7. Responsividade (decisão: tudo responsivo)
Breakpoints: `sm 640 · md 768 · lg 1024 · xl 1280 · 2xl 1440`. Estratégia **mobile-first**.

| Faixa | Layout |
|---|---|
| **≥ lg (1024)** | Shell completo: sidebar fixa 248px + topbar 64px + conteúdo. |
| **md–lg (768–1023)** | Sidebar colapsa em **rail de ícones** (ou drawer); conteúdo full. KPIs 2 colunas. |
| **< md (mobile)** | **Top app bar + hamburger/drawer**; conteúdo 1 coluna; **tabelas viram cards empilhados**; KPIs 1–2 col; formulários 1 coluna; bottom-sheet para ações. |

Regras: inputs com `font-size:16px` no mobile (evita zoom iOS); alvos ≥44px; nada de hover-only (touch).
Por papel: **Gestor** (assunção) é o caso mais provável de mobile — priorizar essa jornada no mobile.

## 8. Handoff zero-inferência (artefatos)
1. `tokens.css` + `tokens.json` (fonte da verdade) → o código importa os CSS vars.
2. **Figma Variables** espelhando os tokens → Dev Mode mostra o nome do token em cada propriedade.
3. **Componentes** com props documentadas + (opcional) **Code Connect** mapeando Figma↔código.
4. Snippets **HTML/CSS** de cada componente (`design/components/*`) como referência canônica.
5. **UI-spec por tela** em `specs/<tela>/ui.md`: layout, componentes usados, estados, comportamento responsivo, regras — entra no ciclo spec→teste→código.

## 9. Inventário de telas (status de design)
Núcleo (Semana 1, feito como protótipo de fluxo): Login, Médicos & Escala, Solicitações, Disponibilização, Assunção, Usuários.
A desenhar em máxima fidelidade + estados + responsivo: as 6 acima **reconstruídas sobre componentes** + Visão geral, Remanejamento, Painel/Visões, Cobertura, Configurações, Auditoria, e estados vazios/erro.
