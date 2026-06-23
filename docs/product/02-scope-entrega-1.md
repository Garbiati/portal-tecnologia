---
title: Escopo da Entrega 1 (faz × não faz) + Controle de Mudança
status: draft
date: 2026-06-14
gerado_por: rascunho automático (a validar com Alessandro)
---

# Escopo — Entrega 1

> O propósito deste doc é **congelar** o que a Entrega 1 faz e **não** faz, e a regra para mudanças
> após aprovação. Proponho **3 tiers** para você escolher o tamanho da 1ª entrega conforme prazo/orçamento.

## Os 3 tiers (escolha um como Entrega 1)

### 🟢 Tier 1 — Núcleo ponta-a-ponta ("walking skeleton") — ~330h
O caminho feliz que **já produz um agendamento real na Teleconsulta**. É o menor sistema que gera valor.
- **Faz:** Fundação/plataforma · RBAC mínimo (Admin, Solicitante, Gestor) · Cadastro de médico + escala + motor de estoque (capacidade) · Solicitação · Disponibilização **essencial** (simular/reservar/emitir + saldo) · Assunção + seleção de paciente (TC) + médico preferencial · Integração TC (`POST /integration/appointment`).
- **Não faz (agora):** remanejamento · dashboards ricos · cobertura/PDF · ajuste manual avançado · relatórios.
- **Blocos:** A(parcial 50) + B(80) + D(32) + E(parcial 70) + F(56) + H(64) + J(88) − sobreposições ≈ **330h**.

### 🟡 Tier 2 — Entrega 1 completa — ~650h
Tier 1 **+** o que torna o produto operacionalmente completo.
- **Adiciona:** RBAC completo + auditoria · Disponibilização completa (todas as visões + flag >30 dias) · **Remanejamento** (janela configurável, manual) · ajuste manual de estoque · LGPD/hardening · QA/E2E ampliado.
- **Não faz (Fase 2):** Cobertura/PDF · remanejamento automático · relatórios analíticos · mobile · portais de médico/paciente.
- **Blocos:** quase todo o backlog **menos** Épico C e automações ≈ **650h**.

### 🔵 Tier 3 — Fase 2 (futuro)
Cobertura/PDF · remanejamento automático · dashboards analíticos · multi-estado avançado · app/portal · (o app com Claude Code embarcado foi **descartado** — D-007).

## Tabela faz × não faz (referência — Tier 2)
| Capacidade | Entrega 1 (Tier 2) | Fase 2 |
|---|---|---|
| Login + RBAC (3 papéis) | ✅ | |
| Cadastro médico + escala + estoque | ✅ | |
| Ajuste manual de estoque + auditoria | ✅ | |
| Solicitação (governo) | ✅ | |
| Disponibilização (simular/reservar/emitir + saldo + flag >30d) | ✅ | |
| Assunção + paciente (TC) + médico preferencial | ✅ | |
| Agendamento → Teleconsulta (`POST /integration/appointment`) | ✅ | |
| Remanejamento manual (janela configurável) | ✅ | |
| Remanejamento **automático** | | ✅ |
| Mapa de cobertura + "PDF Modelo" | | ✅ |
| Dashboards analíticos / relatórios | parcial | ✅ |
| App/portal dedicado, mobile, portal médico/paciente | | ✅ |

## ⚖️ Controle de Mudança (a regra que protege a estimativa)
1. Após você **aprovar** um tier + a estimativa, o escopo está **congelado**.
2. Toda mudança (nova tela, nova regra, alteração de comportamento) entra como **Pedido de Mudança (PM)**
   num log `docs/product/change-requests.md`, com: descrição · impacto em horas · impacto em prazo · novo custo.
3. Nenhuma mudança é executada antes do **seu aceite** do impacto. Sem isso, "1 dev + IA" vira escopo infinito.
4. Itens marcados "Fase 2" **não** entram na Entrega 1 sem virar PM.

## ✅ O que preciso de você para fechar este doc
- Escolher o **tier** (recomendo começar pelo **Tier 1** e evoluir para Tier 2 — reduz risco e antecipa valor).
- Confirmar os cortes (o que pode mesmo ficar para a Fase 2).
