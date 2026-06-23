---
title: Fases de Entrega — o que entregamos em 3 e 6 semanas
status: draft
date: 2026-06-14
---

# Fases de Entrega (para apresentar a fases, com clareza ao humano)

> Princípio: **cada fase tem sua própria apresentação no Figma, isolada — só os itens daquela entrega.**
> Assim o stakeholder vê exatamente o que recebe em cada marco, sem ruído das fases futuras.

## 🎯 O problema que estamos resolvendo (a "estrela-guia")
Hoje, o controle de demanda de atendimentos médicos vive em **planilhas Excel** (`agenda-operacional-*.xlsx`)
mantidas manualmente por **1-2 funcionárias, horas por dia, fora de qualquer sistema**. O objetivo é tirar
isso do operacional manual: um sistema onde
1. um **cliente** registra numa tela **quanto precisa** (ex.: "Piauí precisa de X cardiologistas");
2. nós respondemos com uma **proposta de atendimento** (temos? quantos cardiologistas?);
3. e **administramos a decisão** — olhando **um health center** (ex.: Piauí) **ou todos os clientes** de uma vez.

## 🏢 Clientes: público e privado (modelo confirmado 2026-06-14)
- **Cliente público:** um estado / órgão público (ex.: Piauí). Nós (PTM) somos **prestadora de serviço** para
  uma empresa que tem o vínculo com o governo.
- **Cliente privado:** uma **clínica** ou um **plano de saúde**.
- Cada cliente agrupa um ou mais **Health Centers (HC)**. Visões devem permitir **por HC** e **consolidado
  (todos os clientes, público + privado)**.

---

## 📦 As fases

### Fase 0 — Semana 0 · "Ver o produto" (EM CURSO)
**Figma navegável de máxima fidelidade** representando a entrega final + **todas as instruções de dev**
(tokens, componentes, estados, UI-specs, arquitetura). É o que se apresenta para decidir e aprovar.
> Apresentação: o arquivo Figma navegável + este pacote de docs.

### Fase 1 — ~3 semanas · "Sair do Excel" (o cockpit de planejamento)
O **mínimo que substitui a planilha** e tira o controle das mãos manuais. Fluxo ponta-a-ponta do
**planejamento/decisão** (ainda sem execução paciente-a-paciente):
- **Clientes & HCs** (cadastro público/privado, seleção de escopo).
- **Capacidade** (médicos + escala → estoque) — cadastro ou importação inicial.
- **Solicitação** — o cliente registra "preciso de N de especialidade X no mês".
- **Disponibilização** — responder com proposta: *temos? quantos?* → simular saldo → reservar → emitir.
- **Painel consolidado** — decidir olhando **1 HC** (ex.: Piauí) **ou todos os clientes** (púb+priv).
- **Saída**: a decisão registrada e **exportável** (substitui a `agenda-operacional.xlsx`).
> Resultado: a funcionária deixa de manter Excel; o controle passa a viver no sistema, auditável.
> Apresentação isolada: board **"Apresentação · Fase 1"** no Figma (só estas telas).

### Fase 2 — ~6 semanas (acumulado) · "Executar e integrar"
Adiciona a **execução** e a **integração** com a Teleconsulta:
- **Assunção de Vagas** — gestor local assume slot e **seleciona o paciente** (lista da TC).
- **Agendamento → Teleconsulta** (`POST /integration/appointment`, médico preferencial + fallback).
- **Remanejamento** (janela 24/48h, demanda não atendida).
- **Auditoria/LGPD** + **Configurações**.
> Apresentação isolada: board **"Apresentação · Fase 2"**.

### Fase 3+ — Escala (futuro)
Cobertura analítica, remanejamento automático, mobile (Gestor), multi-cliente avançado, BI.

---

## ⏱️ Sobre prazo (honestidade)
"3 semanas / 6 semanas" são **fases de capacidade**, não promessa de relógio a 10h/semana (a 10h/sem
seria mais lento — ver `05-estimativa-normal-vs-ai.md`). O prazo real depende de (a) dedicação semanal e
(b) quanto aceleramos com **agentes de IA em paralelo** (arquitetura + código sob SDD+TDD). As fases acima
são desenhadas para serem **apresentáveis e faturáveis isoladamente**.

## 🖼️ Apresentação por fase (resolve o "entendimento do humano")
Para cada fase, um board dedicado no Figma com **apenas as telas daquela fase**, em ordem de jornada, com
títulos e legendas curtas — o stakeholder navega só aquele recorte. Nada da fase seguinte aparece.
