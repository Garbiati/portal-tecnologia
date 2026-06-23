# Validação de Arquitetura do Figma — Doctor-Hub (multi-agente, 2026-06-18)

> 4 agents validaram **completude · arquitetura de componentes · padronização · UX/fluxo** das 51 telas
> (`snTNGRUJO2GwoKpXTHCBjf`). Alguns leram o Figma ao vivo. Síntese + plano abaixo.

## ✅ O que está saudável
- **Navegação 100%** (51/51 alcançáveis, 0 órfãos, 0 dead-ends de tela). Conteúdo limpo: 0 demanda inventada, 0 sync/Teleconsulta-source, 0 código D-xx, 0 "Yannka". Componentes de chrome existem (Sidebar ×46, ContextHeader ×26, DoctorRow ×16, Icon ×14).
- **Correções ao snapshot** (agents acharam): 🔒 emoji = ~22 nós (não 62 ocorrências); **Button e Field têm master mas 0 uso** (128 botões feitos à mão!).

## 🔴 4 frentes de dívida

### Frente 1 — Padronização visual (rápido, é o que o olho pega)
Ordem p/ homologação: **(1)** matar 🔒 emoji → `Icon/lock` · **(2)** setas de navegação → `Icon` (as de valor "R$x→R$y" ficam texto) · **(3)** caret ▾ / ✕ close / ✓ / ⚠ / ⓘ → `Icon` (dot ● e radio ◉○ ficam) · **(4)** aplicar type ramp (reapontar 24 estilos → 10). Adiar: binding de tokens e criar masters (alto esforço, **invisível na foto**).

### Frente 2 — Estados/feedback FALTANDO (mata a credibilidade)
- **Sem tela de sucesso/resultado** — a ação volta igual, "parece que não fez nada" (A1-A7). **Maior gap.**
- Sem **validação nos modais de faturamento** (valor vazio/≤0, duplicado) — dinheiro público sem barreira (D4).
- Sem **loading/"salvando"** (duplo-submit) e sem **erro de sistema/falha ao salvar** (B, C1).
- Sem **reativar especialidade/exame** (regra D-089 diz reativável, mas não tem tela) (D1).
- Sem **editar escala existente** (só "Criar nova") (E2); sem **descartar alterações** (F1); sem **busca de escala sem resultado** (E1).

### Frente 3 — Arquitetura de componentes 🟠 frágil (dívida de manutenção)
- Só **~3% dos nós são instâncias** (116 de ~3.746) → a regra "propaga a todas as telas" **não vale** hoje.
- Plano: **P0** adotar Button (existe, 0 uso) → **P1** ressuscitar Field (estado de erro = variante, não tela clonada) → **P2** Modal (1 componente c/ slots vs 8 clones) → **P4** unificar DadosMedico `modo=ver|editar` + estados como variante (6 fichas-estado furam o master hoje) → **P3** Tabela/Linha/Célula → **P5** ações de linha DENTRO do componente (hoje só no Alessandro) → **P6** auto-layout no lugar de overlays absolutos.

### Frente 4 — 3 inconsistências CRÍTICAS de UX (o avaliador caça)
1. **Ações de linha (✎/🗑) só na ficha do Alessandro** — os outros 5 médicos não têm → lê como **bug**.
2. **Modais mostram dados do Alessandro** mesmo abertos de outro médico → credibilidade + **cheiro de LGPD**.
3. **Modais sem ✕ / fechar no overlay** (só [Cancelar]); destrutivos deveriam ter **foco em Cancelar** + botão vermelho distinto.

## Regras de negócio a confirmar (em `03-open-questions.md` §Validação) — não inferir
Padrão de feedback · validação/duplicata no faturamento · médico sem produto pode escalar? · remover a última especialidade? · escala editável/cancelável? · sobreposição de horário · edição concorrente · RBAC · autoria das alterações · reativar especialidade.

## Recomendação de sequência
1. **Frente 1 (1→2→3→4)** — ganho visual rápido p/ a foto. 2. **Frente 4** (esp. #2 modal-com-dado-errado = risco LGPD). 3. **Frente 2** (feedback/estados — confirmar padrão antes). 4. **Frente 3** (componentização — pós-foto, destrava manutenção).
