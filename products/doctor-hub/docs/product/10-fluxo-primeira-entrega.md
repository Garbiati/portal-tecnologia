---
title: Fluxo da Primeira Entrega (até o agendamento na Teleconsulta)
status: draft
date: 2026-06-14
fonte: correção do Alessandro (2026-06-14) — corrige o re-escopo de product/09
---

# Primeira Entrega — o fluxo completo (até o agendamento na TC)

> ⚠️ Corrige `product/09` e D-023: a Primeira Entrega **NÃO é só a base**. Vai **até o agendamento**.
> E **não há "v1/v2/antiga"** — é um protótipo único, em refinamento. As telas melhoradas viram as oficiais.

## A jornada (ponta a ponta)
1. **Acesso & perfis** — login, credenciais, gestão de usuários (RBAC). *(base)*
2. **Solicitação de especialidades** — os personas (Solicitante) registram a demanda por especialidade.
3. **Montagem da escala** — o doutor (buscado da TC, D-021) recebe sua **escala própria** (D-026), que **gera os slots concretos**.
4. **Reserva de slots pelas unidades** — a unidade reserva os slots disponibilizados.
5. **Agendamento** — atribuir **1 doutor + 1 paciente** a um **slot concreto** → enviar à Teleconsulta (`POST /integration/appointment`).

O que fica para **entregas futuras (vender depois)**: elegibilidade, produtividade médica, monitor proativo
da janela, remanejamento automático.

## Modelo do SLOT (D-028) e do AGENDAMENTO (D-029)
- **Slot = especialidade × dia × horário concreto.** Ex.: Cardiologia · terça · 08:00–08:20.
- **Duração do slot = 60 ÷ consultas-por-hora.** Ex.: 3 consultas/hora → 20 min/slot.
- A **escala do doutor gera os slots**: o Dr. Fernando atende Cardiologia às terças nesse horário → o sistema
  materializa os slots de 20 min daquele período.
- **Agendamento (exemplo do Alessandro):** no slot de Cardiologia de terça 08:00–08:20, colocar o
  **Dr. Fernando** para atender o **paciente Thiago**. → vira agendamento (médico + paciente + especialidade + HC)
  → inserido na TC.

## Telas que cobrem o fluxo (a consolidar como oficiais, navegáveis ponta a ponta)
Login · Visão geral (por perfil) · Clientes & HCs · **Médicos & Escala** (busca TC + escala → slots) ·
**Solicitações** · **Disponibilização/Reserva de slots** · **Agendamento** (atribuir doutor+paciente ao slot) · Usuários.
> A tela de **Agendamento** é a peça a desenhar/explicitar: grade de slots concretos (especialidade×dia×horário,
> duração derivada da escala) + atribuição de doutor + paciente.

## Perguntas abertas (não inferir)
- 🟡 Quem faz o **agendamento** (atribui doutor+paciente ao slot): o **gestor da unidade** (D-009) ou um **operador**?
- 🟡 Como o doutor é escolhido no slot: respeita o **preferencial** (D-011) e/ou o gestor escolhe manualmente?
- 🟡 Intervalo entre slots / almoço entram na geração (a escala v2 já trata blocos sem overlap).
