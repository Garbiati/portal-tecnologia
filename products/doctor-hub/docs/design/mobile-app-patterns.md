# Padrões mobile-first / PWA→app — guia oficial do doc hub

> Pesquisa de comunidade (2026-07-05, agente UX; fontes: Material 3, Apple HIG, NN/g, web.dev,
> shadcn/Vaul, Tailwind Plus). Base do redesign pedido pelo Alessandro ("design pro sistema,
> mobile first, PWA, com possível migração para aplicativos"). Direção visual (A/B/C) é escolha
> do dono; ESTES padrões estruturais valem em qualquer direção.

## Receita (por impacto)

1. **Bottom navigation** com 3–5 destinos (ícone + rótulo SEMPRE), fixa, com safe-area
   (`env(safe-area-inset-bottom)`). Excedente vai numa aba **"Mais"** (padrão Apple HIG) — nunca
   6+ ícones nem hambúrguer como navegação primária (NN/g: navegação oculta mata descoberta).
2. **App shell adaptativo**: mesmos destinos — bottom bar (mobile) → rail (tablet) → sidebar
   (desktop). Material 3 window size classes.
3. **List item M3 no lugar de tabela empilhada**: leading avatar/ícone + título + 1 linha de
   metadado + trailing badge; 2 linhas por item; **tap no item = detalhe**.
4. **Ações por item no "⋯" → action/bottom sheet** com RÓTULOS de texto (Detalhes/Editar/
   Desativar/Excluir; destrutiva em vermelho + confirmação em dialog). Swipe = só atalho
   redundante depois (NN/g), nunca caminho único.
5. **FAB (extended, "+ Novo …")** nas telas de lista — um por tela, acima da bottom bar, com
   padding no fim da lista pra não cobrir o último item.
6. **Formulários criar/editar**: mobile = full-screen dialog (header Cancelar/título/Salvar);
   desktop = modal centrado. Mesmo componente, container responsivo (padrão shadcn Dialog↔Drawer).
   Bottom sheet NÃO é lugar de formulário longo (teclado+scroll).
7. **Bottom sheets arrastáveis** (grabber + swipe-to-dismiss) p/ filtros, seleções e menus — o
   detalhe que mais dá sensação nativa.
8. **Polimento "nativo" (web.dev/learn/pwa/app-design)**: `user-select:none` em controles,
   `overscroll-behavior` (matar pull-to-refresh acidental), `theme-color` por tema,
   `prefers-reduced-motion`, display standalone (já temos).
9. **Auditoria contínua**: touch targets ≥44px (HIG) e safe areas em tudo que é `fixed`.
10. **Loja depois sem redesenho**: manifest completo (maskable ✓, theme/background ✓), rotas com
    deep-link (✓), back do sistema respeitado → empacotar via TWA (Play) / Capacitor (App Store)
    vira tarefa de infra.

## Fontes principais
m3.material.io (navigation-bar, navigation-rail, lists, FAB/extended-fab, bottom-sheets, dialogs,
applying-layout) · developer.apple.com HIG (tab-bars, toolbars) · nngroup.com (contextual-swipe,
contextual-menus-guidelines, hamburger-menus) · web.dev/learn/pwa (app-design, architecture) ·
ui.shadcn.com (drawer/Vaul responsive dialog) · tailwindcss.com/plus (stacked lists, Catalyst) ·
developers.google.com/codelabs/pwa-in-play · WCAG 2.5.8.

## Implementação no doc hub
- Componentes estruturais no design system: `BottomNav`, `ListItem`, `ActionSheet`
  (src/components/ui + components.css §16 — fonte canônica + cópia).
- Aplicação por telas: admin (Usuários, Clientes) primeiro; jornadas em seguida.
- Direção visual escolhida pelo Alessandro no artifact "direções de design" (A Navy Pro ·
  B Clean Health · C Dark 9.4) — tokens ajustados conforme a escolha.
