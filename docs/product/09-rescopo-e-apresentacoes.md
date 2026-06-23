---
title: Re-escopo da Entrega 1 + Dashboards por perfil + Apresentações por persona
status: draft
date: 2026-06-14
fonte: feedback do Alessandro (2026-06-14)
---

# Re-escopo da Entrega 1, visões por perfil e apresentações por persona

## 1. Re-escopo da Entrega 1 (a BASE do sistema)
A Entrega 1 é a **base**, alinhada ao **dashboard do ClickUp** — e **NÃO inclui** agendamento/elegibilidade/
integração full com a Teleconsulta (isso vira venda de **entregas futuras**).

**Entra na Entrega 1:**
- **Acesso & Credenciais & Perfis** — login (com fluxo feliz e infeliz), criação de credenciais/perfis, RBAC.
- **Gestão de Usuários e Credenciais** — Admin cria/gere usuários por papel e escopo.
- **Gestão de Solicitações de Demandas** — o Solicitante registra; o operador gere as solicitações.
- **Médicos & Escala** — cadastro de **capacidade** com a nova arquitetura de escala (ver `discovery/07`).
- **Visão por perfil** — dashboards/home específicos de cada persona (item 2).

**Sai da Entrega 1 → entregas futuras (vender depois):**
- Disponibilização (alocação: simular/reservar/emitir), Assunção de Vagas, **Agendamento**, **Elegibilidade**,
  **integração FULL com a Teleconsulta**, Remanejamento automático, **Produtividade médica**.

> 🔴 **Confirmar a fronteira exata contra o dashboard do ClickUp.** Posso puxar o board do ClickUp (tenho acesso)
> e ajustar este escopo ao que está lá. (Link/board a indicar.)

## 2. Dashboards / "Visão geral" — hoje está fraca
A home atual é só do Admin e **não responde "como estamos"**. Precisa de visão **operacional e acionável**, e
**por perfil**. Perguntas que a visão deve responder:
- Quantos **solicitados**? Quantos **disponibilizados**? Qual o **saldo**?
- Quantos estão **próximos de não serem usados** (em risco → precisa **remanejar** a disponibilidade do médico)?
- **Agrupado por especialidade** e **agrupado por health center** (duas visões).

Por perfil (hipótese a validar):
| Perfil | Home deve mostrar |
|---|---|
| **Admin / Demandas** | Visão global: solicitado × disponibilizado × saldo × em-risco, por especialidade e por HC |
| **Solicitante (Secretário)** | Só do seu escopo: minhas solicitações, status, saldo atendido |
| **Gestor local** | Só da sua unidade: vagas a assumir, em risco na minha unidade |

> 🟡 Confirmar o conteúdo exato da home de cada perfil.

## 3. Apresentações por FASE + PERSONA (resposta: SIM, dá no Figma)
Você quer cada apresentação contendo **só as telas/jornada de UMA persona**, com **login funcionando** (fluxo
feliz com usuário correto **e** infeliz com usuário/senha inválida).

**É possível no Figma**, sim:
- O Figma tem **"Flows"** (múltiplos `flowStartingPoints` no mesmo arquivo) — **um flow por persona**, cada um
  começando no Login. No modo Present, escolhe-se qual flow apresentar → cada um mostra só a jornada daquela persona.
- **Login interativo (happy/unhappy):** simulamos com interações de protótipo — botão "Entrar" → dashboard
  (feliz); um caminho alternativo (ex.: campo/ação específica) → **tela de Login com estado de erro**
  ("usuário ou senha inválidos"). O Figma não valida de verdade, mas **encena** os dois fluxos de forma navegável.
- Mantemos também os **boards de apresentação por persona** (filmstrip) já no padrão que criamos.

**Personas que logam (D-008/D-010):** Admin/Demandas, Solicitante (Secretário), Gestor local. (Doutor/Paciente = dados.)

## Plano (o novo loop homologa isto, tela a tela)
1. Login com estados (erro de credencial) + flow interativo.
2. Visão geral reescrita → operacional, por especialidade e por HC, + variantes por perfil.
3. Médicos & Escala reescrita → busca de profissional (TC) + presets de escala + múltiplos blocos sem overlap +
   timeline de vigências/estados + aba de rastreabilidade (histórico).
4. Apresentações por persona (Flows) com login feliz/infeliz.
5. Ajustar o planejamento/escopo conforme você homologa cada parte.
