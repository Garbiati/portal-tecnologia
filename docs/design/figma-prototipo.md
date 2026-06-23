---
title: Protótipo Figma — Telas-núcleo (M0 / Semana 1)
status: draft
date: 2026-06-14
---

# 🎨 Protótipo Figma — Núcleo

**Arquivo:** https://www.figma.com/design/NCMcYURZgrHH36f9DTk7di
(conta `a.garbiati@gmail.com` · plano Professional · página "Protótipo · Núcleo")

Criado 100% via integração (Figma MCP, `use_figma`), estilo **limpo e neutro**:
- Tipografia **Inter**; paleta neutra (#F4F5F7 fundo, branco cards, #1A1D21 texto) + 1 acento (#2D6FF0).
- Shell compartilhado: sidebar de navegação + topbar com o papel logado.

## Telas entregues (6 do núcleo / Tier 1)
| Tela | Conteúdo | Papel no topo |
|---|---|---|
| **Login** | Card centralizado, e-mail/senha | — |
| **Médicos & Escala** | Dados do médico + escala fixa (dias/horário/consultas) + banner "≈ 208 vagas" | Admin · PTM |
| **Solicitações** | Form (HC + mês) + qtd por especialidade + solicitações recentes | Sec. Saúde · AL |
| **Disponibilização** | 4 KPIs (demanda/estoque/saldo/>30d) + Simular/Reservar/Emitir + tabela com saldo | Admin · PTM |
| **Assunção de Vagas** | Lista de vagas emitidas + painel assumir/selecionar paciente (TC) + médico preferencial | Gestor · Maceió |
| **Gestão de Usuários** | Tabela de usuários com papel/escopo/status | Admin · PTM |

## Telas ainda a desenhar (próximas semanas)
Visão geral (dashboard), Remanejamento, Painel/Visões completas, Mapa de Cobertura, Configurações, Auditoria.

## Observações
- É **protótipo de validação de fluxo/layout** (dados fictícios), não design final. Serve de base para
  as specs de UI e para a diretoria "ver o produto".
- Próximo: validar com você/diretoria → ajustar → cada tela aprovada vira spec em `specs/` e depois código.
