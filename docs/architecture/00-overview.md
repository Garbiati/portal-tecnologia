---
title: Arquitetura — Contexto C4 (L1/L2)
status: draft
date: 2026-06-14
author: Staff Architect (agente)
rastreabilidade: D-001, D-002, D-003, D-008, D-018, D-019, contrato em docs/discovery/04-integration-teleconsulta.md
---

# 00 — Visão Geral / Contexto C4 (L1 e L2)

> Documento de arquitetura. **Não cria regra de negócio** — toda regra citada está rastreada a um
> `D-xxx` (`docs/decisions/decisions-log.md`) ou a um doc de descoberta. O que falta está marcado
> 🔴 (bloqueia) / 🟡 (importante). **Stack permanece DECISÃO ABERTA (D-001)** — ver `02-system-design.md`.

## 0. Em uma frase

O sistema **"Demandas"** (nome provisório "Agenda Fixa") é o **cockpit a montante** que **tira o
controle do Excel** (`agenda-operacional-*.xlsx`, D-019) e **alimenta a Teleconsulta (TC) a jusante**
com agendamentos prontos, integrando como **parceiro externo** via `POST /integration/appointment`
+ header `X-API-KEY` (D-002, contrato em `04-integration-teleconsulta.md`). Não substitui a TC.

## 1. C4 Nível 1 — Contexto do Sistema

```mermaid
C4Context
    title C4 L1 — Contexto: Demandas (cockpit a montante) → Teleconsulta (a jusante)

    Person(admin, "Admin / Demandas", "Operador interno PTM. Configura, opera Disponibilização (simular/reservar/emitir), cadastra médicos+escala, ajusta estoque. Escopo global. (D-008)")
    Person(solicitante, "Solicitante", "Secretário de Saúde estadual. Abre a Solicitação (especialidade × qtd × período). Escopo: seu estado. (D-008)")
    Person(gestor, "Gestor local", "Gestor de unidade/HC (~1 por cidade). Assume slots da sua unidade e seleciona o paciente. Escopo: sua unidade. Caso mobile prioritário. (D-008, D-015)")

    System(demandas, "Sistema Demandas (este projeto)", "Planejamento de capacidade médica: oferta × demanda → alocação → assunção → agendamento. Repo SEPARADO (D-002).")

    System_Ext(tc, "Teleconsulta (TC)", "Plataforma de atendimento existente (C#/.NET + PostgreSQL). Sistema de registro do atendimento. Repo/monorepo da empresa.")
    System_Ext(excel, "Controle manual em Excel (AS-IS)", "agenda-operacional-*.xlsx mantido por 1-2 pessoas horas/dia. É o que o sistema SUBSTITUI (D-019).")

    Rel(solicitante, demandas, "Registra demanda (Solicitação)")
    Rel(admin, demandas, "Opera disponibilização, cadastra oferta")
    Rel(gestor, demandas, "Assume vagas, seleciona paciente")
    Rel(demandas, tc, "Envia agendamento pronto", "POST /integration/appointment · X-API-KEY (D-002/D-003)")
    Rel(demandas, tc, "Consulta paciente por CPF/CNS; lista pacientes por HC", "GET /integration/patient/... (D-012)")
    Rel(demandas, excel, "Substitui (não integra)", "internaliza a camada de visibilidade/triagem (D-019)")
```

### Fronteira de integração (D-002 / D-003)

- O sistema é um **produto/repo SEPARADO** e integra com a TC **como parceiro**, não como serviço
  dentro do monorepo da TC (**D-002**). Existe um diretório `services/saude-digital-demandas/`
  **vazio** no monorepo da TC — sinal de que já se cogitou viver dentro; a decisão tomada foi repo
  separado (D-002).
- A **alocação de médico é NOSSA** (**D-003**): nós decidimos o médico e o enviamos em
  `preference_of_doctor_id`; a TC **respeita** o `external_appointments`. Sem sobreposição com o
  `ptm-matching-api` da TC.
- A integração é **síncrona, por API-key de parceiro**, sem FHIR/RNDS na v1
  (`04-integration-teleconsulta.md` §5). Idempotência via `external_id` (UNIQUE na TC).

## 2. C4 Nível 2 — Contêineres (proposta)

> Os contêineres abaixo são **proposta de arquitetura** (rastreada a `02-system-design.md`). A
> escolha de runtime/stack é **DECISÃO ABERTA (D-001)**. A forma recomendada é **monólito modular**
> + um **adapter de integração** isolado.

```mermaid
C4Container
    title C4 L2 — Contêineres (proposta · stack = DECISÃO ABERTA D-001)

    Person(admin, "Admin / Demandas")
    Person(solicitante, "Solicitante (Secretário estadual)")
    Person(gestor, "Gestor local (HC)")

    System_Boundary(demandas, "Sistema Demandas (repo separado · D-002)") {
        Container(web, "Web App (SPA responsiva)", "Front-end", "UI por papel; mobile-first p/ Gestor. Design system tokenizado (design/). D-015/D-016/D-017.")
        Container(api, "Aplicação (monólito modular)", "Back-end", "Módulos com fronteiras claras: Cliente/HC, Médico+Escala+Estoque, Solicitação, Disponibilização, Assunção+Agendamento, Remanejamento, Monitor/Integração, Acesso/RBAC, Auditoria. Ver 01-domain-model.md.")
        ContainerDb(db, "Banco de dados", "RDBMS (DECISÃO ABERTA — TC usa PostgreSQL)", "Estado do domínio + read-models + outbox + trilha de auditoria.")
        Container(adapter, "Adapter de Integração TC", "Cliente HTTP + idempotência", "Encapsula POST /integration/appointment, lookups de paciente, retry/backoff, idempotência por external_id.")
        Container(jobs, "Jobs agendados / Worker", "Background", "Processa outbox, roda o Monitor proativo de janela, gatilho de remanejamento (janela D-013).")
    }

    System_Ext(tc, "Teleconsulta (TC)", "API de parceiro (X-API-KEY)")

    Rel(admin, web, "Usa", "HTTPS")
    Rel(solicitante, web, "Usa", "HTTPS")
    Rel(gestor, web, "Usa", "HTTPS")
    Rel(web, api, "Chama", "HTTPS/JSON")
    Rel(api, db, "Lê/escreve")
    Rel(jobs, db, "Lê outbox / read-models")
    Rel(jobs, adapter, "Dispara envio idempotente")
    Rel(adapter, tc, "POST /integration/appointment", "X-API-KEY (novo PartnerType — tarefa da equipe TC)")
    Rel(adapter, tc, "Lookup paciente / HC", "GET /integration/patient/... (D-012)")
```

## 3. Atores e papéis (D-008, D-010)

| Ator | Quem é | Faz login? | Escopo | Fonte |
|---|---|---|---|---|
| **Admin / Demandas** | Operador interno PTM | ✅ Sim | Global | D-008 |
| **Solicitante** | Secretário de Saúde estadual | ✅ Sim | Seu estado (🟡 isolamento a confirmar) | D-008 |
| **Gestor** | Gestor local de unidade/HC (~1/cidade) | ✅ Sim | Sua unidade (🟡 isolamento a confirmar) | D-008 |
| **Doutor** | Médico cadastrado com escala | ❌ Não (é DADO) | — | D-010 |
| **Paciente** | Selecionado pelo Gestor; master é da TC | ❌ Não (é DADO) | — | D-010, D-012 |

> 🟡 Escopo de dados (Solicitante vê só o estado; Gestor só a unidade) é **provável mas não confirmado**
> (`02-roles.md`, `03-open-questions.md`). O RBAC deve ser desenhado para suportá-lo (ver `02-system-design.md`).

## 4. Clientes: público e privado (D-018)

```mermaid
flowchart LR
    subgraph Consolidado["Visão consolidada (todos os clientes)"]
        direction TB
        Pub["Cliente PÚBLICO<br/>(estado/órgão — ex.: Piauí)"]
        Priv["Cliente PRIVADO<br/>(clínica ou plano de saúde)"]
    end
    Pub --> HC1["HC A"] & HC2["HC B"]
    Priv --> HC3["HC C"]
    HC1 & HC2 & HC3 -.->|≈ ProfileTag / group_id por CNES na TC| TC[(Teleconsulta)]
```

- **Cliente** é um conceito **acima de HC** (D-018). Cada cliente agrupa um ou mais **Health Centers**.
- Visões exigidas: **por HC** e **consolidado** (público + privado).
- **HC ≈ `ProfileTag` / `group_id`** na TC, identificável por **CNES**
  (`04-integration-teleconsulta.md` §3). O master do paciente é da TC (D-012), o que reduz exposição LGPD.

## 5. Pipeline de domínio (recapitulação)

```mermaid
flowchart LR
    O["① Oferta<br/>médico + escala → estoque"] --> D["② Demanda<br/>Solicitação"]
    D --> A["③ Alocação / Disponibilização<br/>simular → reservar → emitir"]
    A --> AS["④ Assunção<br/>Gestor assume + seleciona paciente"]
    AS --> AG["⑤ Agendamento<br/>médico+paciente+especialidade+HC"]
    AG --> TC[("⑥ Teleconsulta<br/>POST /integration/appointment")]
    A -. "janela D-013" .-> R["Remanejamento<br/>(vagas não assumidas)"]
    R --> AS
    AG -. "monitor proativo" .-> M["Monitor de Janela/Integração<br/>alerta ANTES de expirar"]
```

Detalhe de cada bounded context e suas invariantes em **`01-domain-model.md`**.

## 6. Perguntas abertas que afetam o contexto

- 🔴 Regra da **"janela de envio"** que expira (causa dos 7,7% de perda) — não definida
  (`05-processo-manual-excel.md` §8; `monitor-integracao/ui.md` §8). Define o gatilho do Monitor.
- 🔴 O **"REGULA-HUB" (AM/SISReg)** das planilhas é a mesma fonte deste projeto (HC-SP) ou produto
  anterior? Define se o Monitor lê **da nossa integração com a TC** ou de **hub externo**
  (`05-processo-manual-excel.md` §8). No monorepo da TC há serviços `ptm-regula-hub`/`ptm-regula-sisreg`.
- 🟡 Novo **`PartnerType` + `X-API-KEY`** a ser emitido pela equipe da TC (tarefa externa).
- 🟡 Mapeamento de **especialidades** (texto / `internal_specialization_id`) entre os dois sistemas.

## Índice

Ver `README.md` desta pasta.
