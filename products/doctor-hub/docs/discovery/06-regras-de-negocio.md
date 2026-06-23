---
title: Catálogo de Regras de Negócio e Invariantes
status: draft
date: 2026-06-14
author: Analista de Negócio (SDD)
rastreabilidade: D-001..D-020; specs/*/ui.md; 01-domain-model.md; 01-domain-overview.md; 05-processo-manual-excel.md; 04-integration-teleconsulta.md; 03-open-questions.md
---

# 06 — Regras de Negócio (catálogo único)

> **Zero inferência** (Diretriz Suprema `CLAUDE.md`). Este documento apenas **consolida** o que já
> está escrito nas decisões (`D-xxx`), nas UI-specs e no modelo de domínio. **Nada foi inventado por
> "bom senso".** O que ainda não está definido **não vira regra** — vira **pergunta aberta** (bloco no
> fim). Este catálogo alimenta o board "Regras de Negócio" no Figma e o desenvolvimento.

## Legenda

- **Status:** ✅ confirmada (decisão/spec firme) · 🟡 parcial (princípio definido, detalhe em aberto) · 🔴 aberta (regra ainda não existe — não implementável).
- **Áreas:** Oferta · Demanda · Alocação · Remanejamento · Agendamento · Acesso · Integração · Monitor (+ Cadastro e Auditoria, transversais).
- **Origem:** `D-xxx` (decisão confirmada) · `spec` (UI-spec) · `inv` (invariante do modelo de domínio) · `proc` (processo manual Excel).

---

## 1. Catálogo de Regras (RN)

| ID | Regra | Origem | Área | Status |
|----|-------|--------|------|--------|
| **RN-01** | Todo HC pertence a **exatamente um** Cliente; HC é identificado por **CNES**. | D-018; inv; `clientes-hcs/ui.md` | Cadastro | ✅ |
| **RN-02** | Cliente é **público** (estado/órgão, ex.: Piauí — prestamos serviço a empresa com vínculo de governo) **ou privado** (clínica/plano). Cada cliente agrupa HCs. | D-018; `clientes-hcs/ui.md` | Cadastro | ✅ |
| **RN-03** | As visões de dados devem permitir recorte **por HC** e **consolidado** (todos os clientes). | D-018; `painel/ui.md`; inv | Cadastro/Monitor | ✅ |
| **RN-04** | HC casa com `ProfileTag`/`group_id` da Teleconsulta **por CNES** (mapeável via `GET /integration/profile-tags/by-cnes`). | D-018; `04-integration-teleconsulta.md` | Cadastro/Integração | ✅ |
| **RN-05** | O **master do paciente é da TC** — este sistema não é dono do cadastro de paciente. | D-012; inv | Cadastro/Agendamento | ✅ |
| **RN-06** | **Médico é DADO, não usuário** — não faz login; é cadastrado (escala) por um operador Admin/Demandas. | D-010; `medicos-escala/ui.md` | Oferta/Acesso | ✅ |
| **RN-07** | A **Escala** do médico tem: dias de atendimento, horário (início/fim), consultas/hora, **período válido de prestação de serviço** e flag ativo/inativo. | `01-domain-overview.md` ①; `medicos-escala/ui.md`; inv | Oferta | ✅ |
| **RN-08** | **Estoque é MISTO**: base **calculada** da escala (dias × horário × consultas/hora × período) **+ ajuste manual** ("retornos/extras"). | D-005; inv (INV-2) | Oferta | ✅ |
| **RN-09** | O **estoque é calculado ANTES** (visão prévia de oferta por especialidade), não observado a posteriori como hoje ("Sem médico / horário ocupado"). | D-005; `medicos-escala/ui.md`; `05-processo-manual-excel.md` §6 | Oferta | ✅ |
| **RN-10** | O **ajuste manual** de estoque (retornos/extras) é **auditável** (registra trilha da alteração). | D-005; inv; `medicos-escala/ui.md` EARS | Oferta/Auditoria | 🟡 |
| **RN-11** | Validação da escala: horário de **fim deve ser > início**; consultas/hora **> 0**; período válido coerente. | `medicos-escala/ui.md` EARS/§4 | Oferta | ✅ |
| **RN-12** | A **Solicitação (demanda)** é aberta pelo papel **Solicitante** (Secretário de Saúde estadual). | D-008; `solicitacao/ui.md` | Demanda/Acesso | ✅ |
| **RN-13** | Solicitação = lista de especialidades **× quantidade × período (mês)**, por **Cliente → HC**, com identificação do solicitante + data (automáticos). | D-018; `01-domain-overview.md` ②; `solicitacao/ui.md` | Demanda | ✅ |
| **RN-14** | Ao selecionar um Cliente na Solicitação, o seletor de **HC é restrito** aos HCs daquele cliente. | D-018; `solicitacao/ui.md` EARS | Demanda | ✅ |
| **RN-15** | Quantidade por especialidade **deve ser > 0**; linha com qtd ≤ 0 **bloqueia o envio**. | `solicitacao/ui.md` EARS | Demanda | ✅ |
| **RN-16** | **A alocação de médico é NOSSA**: o sistema decide o médico e o envia em `preference_of_doctor_id`; a TC **respeita** o que está em `external_appointments`. | D-003; inv (INV-1) | Alocação/Agendamento | ✅ |
| **RN-17** | A Disponibilização opera por **Cliente/HC/período**, com linhas por especialidade: qtd solicitada (Gov) · qtd a disponibilizar · retornos/extras (manual) · **saldo +/-**. | `01-domain-overview.md` ③; `disponibilizacao/ui.md` | Alocação | ✅ |
| **RN-18** | Fluxo de ações da Disponibilização: **Simular → (Limpar) → Reservar → Emitir**. | `01-domain-overview.md` ③; `disponibilizacao/ui.md` | Alocação | ✅ |
| **RN-19** | **Simular** calcula o saldo (demanda × estoque) por especialidade **sem efetivar** reserva. | `disponibilizacao/ui.md` EARS; inv | Alocação | ✅ |
| **RN-20** | **Saldo < 0** é sinalizado como danger; **saldo ≥ 0** como success. | `disponibilizacao/ui.md` EARS; `01-domain-overview.md` ③ | Alocação | ✅ |
| **RN-21** | Vaga com prazo de atendimento **> 30 dias** recebe a flag **">30d"** (warning). | `01-domain-overview.md` ③; `disponibilizacao/ui.md` | Alocação | 🟡 |
| **RN-22** | **Reservar** bloqueia a escala e **baixa do estoque**. | `disponibilizacao/ui.md` EARS; inv (INV-6) | Alocação | ✅ |
| **RN-23** | **Não é permitido reservar além do estoque disponível** — a ação é bloqueada com erro. | `disponibilizacao/ui.md` EARS; inv (INV-6) | Alocação | ✅ |
| **RN-24** | **Emitir** publica as vagas para o HC poder **assumi-las**. | `01-domain-overview.md` ③; `disponibilizacao/ui.md` EARS | Alocação | ✅ |
| **RN-25** | O **Gestor local** (de unidade/HC, ~1 por cidade) **assume** os slots emitidos para a sua unidade. | D-008; D-009; `assuncao/ui.md` | Agendamento/Acesso | ✅ |
| **RN-26** | O **paciente é associado à vaga NO MOMENTO da assunção** — o Gestor seleciona o paciente ali. | D-009; inv (INV-5) | Agendamento | ✅ |
| **RN-27** | A **lista de pacientes vem da Teleconsulta por health center**, com `patient_id` **já resolvido** (reduz exposição LGPD). | D-012; inv (INV-5); `assuncao/ui.md` | Agendamento/Integração | ✅ |
| **RN-28** | **Médico preferencial:** em **retorno**, o último doutor que atendeu vira preferencial; senão o Gestor escolhe um. | D-011; inv (INV-3) | Agendamento | ✅ |
| **RN-29** | Se o **preferencial estiver indisponível** no dia, o atendimento é feito por **outro doutor da mesma especialidade** (fallback). Casa com fallback de especialidade da TC (`preference_of_doctor_id` → se 409, repetir sem ele). | D-011; D-003; `04-integration-teleconsulta.md`; `assuncao/ui.md` | Agendamento/Integração | ✅ |
| **RN-30** | A **confirmação de assunção exige paciente selecionado** — sem paciente, a confirmação é bloqueada. | `assuncao/ui.md` EARS | Agendamento | ✅ |
| **RN-31** | O **Agendamento** que vai à TC compõe **médico + paciente + especialidade + HC**. | D-004; `01-domain-overview.md` ⑤; `assuncao/ui.md` | Agendamento | ✅ |
| **RN-32** | O agendamento é inserido na TC via **`POST /integration/appointment`**, autenticado por header **`X-API-KEY`** (novo `PartnerType` para este sistema). | D-002; `04-integration-teleconsulta.md` | Integração | ✅ |
| **RN-33** | O **envio à TC é idempotente** por `external_id` (campo UNIQUE) — retry é seguro. | inv (INV-7); `04-integration-teleconsulta.md`; `assuncao/ui.md` | Integração | ✅ |
| **RN-34** | Schema de saída **parcialmente ditado pela TC**: obrigatórios `patient_id`, `external_id`, `start_date`/`end_date` (ISO 8601 c/ offset), `specialty`, `preference_of_service` ("ONLINE"\|"PRESENCIAL"); recomendados `group_id` (HC) e `preference_of_doctor_id` (opcional). | `04-integration-teleconsulta.md` | Integração/Agendamento | ✅ |
| **RN-35** | **Remanejamento** atua sobre vagas **emitidas e NÃO assumidas**. | D-013; `01-domain-overview.md` ④; inv | Remanejamento | ✅ |
| **RN-36** | Gatilho do remanejamento = **janela configurável** (ex.: 24h/48h após a disponibilização) sobre slots não assumidos. | D-013; inv (INV-4) | Remanejamento | ✅ |
| **RN-37** | Critério de remanejamento = **demanda não atendida** (HC com saldo negativo). | D-013; inv (INV-4) | Remanejamento | ✅ |
| **RN-38** | Remanejamento é **determinístico, auditável e sem ML** na v1; **não precisa ser automático** (o operador pode rodar), mas a **janela é configurável**. | D-006; D-013; inv (INV-4) | Remanejamento | ✅ |
| **RN-39** | Motivação do remanejamento: **o médico já foi pago — não desperdiçar capacidade**. | D-013 | Remanejamento | ✅ |
| **RN-40** | **Apenas 3 papéis logam:** Admin/Demandas (operador interno PTM, escopo global), Solicitante (estado), Gestor (unidade). | D-008; inv (INV-8) | Acesso | ✅ |
| **RN-41** | **Doutor e Paciente NÃO logam** — são DADOS, não usuários. | D-010; inv (INV-8) | Acesso | ✅ |
| **RN-42** | Cadastro/configuração (Clientes & HCs, Médicos & Escala, Disponibilização, Painel, Monitor) é do **Admin/Demandas**; Solicitante e Gestor não acessam essas telas. | D-008; `clientes-hcs/ui.md`; `medicos-escala/ui.md`; `disponibilizacao/ui.md`; `painel/ui.md`; `monitor-integracao/ui.md` | Acesso | ✅ |
| **RN-43** | Acesso fora do papel correto a uma tela retorna **erro 403**. | `*/ui.md` EARS (todas as specs) | Acesso | ✅ |
| **RN-44** | Operações sobre **dado sensível** de paciente exigem **trilha de auditoria** (LGPD). | LGPD; inv; `01-domain-overview.md` "restrições" | Auditoria | 🟡 |
| **RN-45** | O **Monitor** alerta **ANTES** de a janela de envio expirar (alerta proativo) — converte o monitoramento reativo de hoje (7,7%/mês perdidos por "janela expirou") em ação preventiva. | D-013; D-019; `monitor-integracao/ui.md`; `05-processo-manual-excel.md` §4 | Monitor | 🟡 |
| **RN-46** | O **funil de integração** mostra a conversão por etapa (capturados → ... → integrados) e a **queda** em cada etapa; distingue **recuperáveis** (dá para salvar) de **perdidos** (janela expirou). | `monitor-integracao/ui.md`; `05-processo-manual-excel.md` §4 | Monitor | 🟡 |
| **RN-47** | Semáforo de situação por dia/escopo: **✅ Completo** quando não há pendências; **⚠️ N pendentes** quando há. | `painel/ui.md` EARS; `05-processo-manual-excel.md` §2 | Monitor | ✅ |
| **RN-48** | O **Painel** recalcula KPIs/blocos conforme o filtro Cliente/HC/período; "Todos os clientes" = visão **consolidada**. | D-018; `painel/ui.md` EARS | Monitor | ✅ |
| **RN-49** | Este sistema é um **produto/repo SEPARADO** que integra com a TC **como parceiro** (não um serviço dentro do monorepo da TC). | D-002 | Integração | ✅ |
| **RN-50** | Toda ação que conclui (simular/reservar/emitir/assumir/salvar/enviar) exibe **feedback** (toast de sucesso ou banner de erro). | `*/ui.md` EARS (todas as specs) | (transversal UI) | ✅ |

---

## 2. Mapa de invariantes-chave (do modelo de domínio)

Rastreabilidade direta com `01-domain-model.md` §3 (servem de âncora para as RN acima):

| Invariante | RN relacionadas | Fonte |
|---|---|---|
| INV-1 — alocação de médico é nossa (`preference_of_doctor_id`) | RN-16 | D-003 |
| INV-2 — estoque misto (calculado + ajuste manual auditável) | RN-08, RN-10 | D-005 |
| INV-3 — preferencial: retorno→último; senão escolhido; fallback = mesma especialidade | RN-28, RN-29 | D-011 |
| INV-4 — remanejamento por janela configurável, critério demanda não atendida, determinístico | RN-36, RN-37, RN-38 | D-013/D-006 |
| INV-5 — paciente associado no ato da assunção; lista vem da TC por HC | RN-26, RN-27 | D-009/D-012 |
| INV-6 — Reservar baixa estoque e bloqueia escala; não reservar além do disponível | RN-22, RN-23 | `01-domain-overview.md` ③ |
| INV-7 — idempotência de envio à TC por `external_id` | RN-33 | `04-integration-teleconsulta.md` |
| INV-8 — só 3 papéis logam; Doutor/Paciente são dados | RN-40, RN-41 | D-008/D-010 |

---

## 3. Perguntas abertas de negócio (não viram regra — não inferir)

> Estas são lacunas **reais** de regra. Enquanto não decididas, **não há regra implementável**; entram
> no board do Figma como cartões "ABERTO" e devem ser respondidas antes/durante o desenvolvimento da
> área correspondente.

### 🔴 Bloqueiam a área (regra inexistente)

| ID | Pergunta aberta | Área | Fonte |
|----|------------------|------|-------|
| **QA-01** | **Regra de prazo da "janela de envio"** que expira (causa de 7,7% de perda): qual o prazo? Por que casos chegam a 15 tentativas? Sem isso, o gatilho do alerta do Monitor **não pode** ser implementado (afeta RN-45). | Monitor | `monitor-integracao/ui.md` §8; `01-domain-model.md` §4; `05-processo-manual-excel.md` §8 |
| **QA-02** | **Fonte dos dados do funil/integração:** o "REGULA-HUB" do Excel é o mesmo sistema do projeto ou um produto anterior do AM (AM/SISReg vs HC-SP)? Define se o Monitor lê da **nossa** integração com a TC ou de um **hub externo** (afeta RN-45/RN-46). | Monitor/Integração | `monitor-integracao/ui.md` §8; `01-domain-model.md` §4 |

### 🟡 Importantes (princípio existe, detalhe em aberto)

| ID | Pergunta aberta | Área | Fonte |
|----|------------------|------|-------|
| **QA-03** | **Granularidade do estoque:** vaga = **contagem de capacidade** ou **horário concreto**? (recomendação interna: começar como contagem; horário concreto na assunção — a decidir antes de modelar a alocação). | Oferta/Alocação | `03-open-questions.md`; `medicos-escala/ui.md` §8; `disponibilizacao/ui.md` §8 |
| **QA-04** | **Fórmula exata de capacidade:** confirmar `(horas no dia × consultas/hora) × dias válidos no período` e tratar **intervalo (almoço)**, **duração fixa de consulta** e **feriados**. (Parâmetros do edital — 3 consultas/hora/especialista, plantão mín. 4h — são **referência, não regra confirmada**.) | Oferta | `03-open-questions.md`; `medicos-escala/ui.md` §8; `05-processo-manual-excel.md` §5 |
| **QA-05** | **Regra exata da flag ">30 dias":** a partir de qual data (data de atendimento prevista)? (afeta RN-21). | Alocação | `disponibilizacao/ui.md` §8 |
| **QA-06** | **Reversibilidade Reservar↔Emitir** e se **"Limpar" desfaz reserva** (transições de estado não fechadas). | Alocação | `disponibilizacao/ui.md` §8; `01-domain-model.md` §2 ④ |
| **QA-07** | **Em que etapa o médico é amarrado:** na Disponibilização ou na Assunção? D-003 diz "alocação nossa", mas o ponto de decisão não está confirmado. | Alocação/Agendamento | `disponibilizacao/ui.md` §8; `01-domain-model.md` §2 ④ |
| **QA-08** | **Auditoria do ajuste manual de estoque:** quem pode aplicar, o que se registra na trilha (LGPD) (afeta RN-10). | Oferta/Auditoria | `03-open-questions.md`; `medicos-escala/ui.md` §8 |
| **QA-09** | **Isolamento por escopo de dados:** Solicitante vê só o próprio estado/cliente? Gestor só a própria unidade? (provável, a confirmar — afeta RN-40/RN-42). | Acesso | `02-roles.md`; `03-open-questions.md`; `solicitacao/ui.md` §8; `clientes-hcs/ui.md` §8 |
| **QA-10** | **Resolução do `patient_id`** quando o paciente **não existe** na TC: criar? bloquear? por CPF/CNS? (afeta RN-05/RN-27). | Agendamento/Integração | `04-integration-teleconsulta.md`; `assuncao/ui.md` §8 |
| **QA-11** | **Como o sistema decide que uma vaga é "retorno"** (para pré-preencher o último doutor — afeta RN-28). | Agendamento | `assuncao/ui.md` §8 |
| **QA-12** | **Origem/escopo exato da lista de pacientes** do Gestor (D-012 diz "por health center"; endpoint exato a localizar no repo da TC). | Agendamento/Integração | `assuncao/ui.md` §8; `03-open-questions.md` |
| **QA-13** | **Regras/prioridades de destino do remanejamento:** ordem de HC? urgência? proximidade? data? (não definidas — afeta RN-37). | Remanejamento | `01-domain-overview.md` ④; `01-domain-model.md` §2 ⑦ |
| **QA-14** | **Relação entre o limiar de alerta do Monitor e a janela de remanejamento (D-013):** é a mesma janela? | Monitor/Remanejamento | `monitor-integracao/ui.md` §8; `01-domain-model.md` §2 ⑥ |
| **QA-15** | **Mapeamento de especialidades** entre os dois sistemas (texto / `internal_specialization_id` da TC). | Integração | `04-integration-teleconsulta.md`; `medicos-escala/ui.md` §8 |
| **QA-16** | **"Período" da Solicitação:** sempre mês-calendário ou intervalo livre? | Demanda | `solicitacao/ui.md` §8 |
| **QA-17** | **Solicitante pode editar/cancelar** uma solicitação já enviada? Em que estado isso é permitido? | Demanda | `solicitacao/ui.md` §8 |
| **QA-18** | **Origem da lista de especialidades por HC** (cadastro do HC? configuração global?). | Demanda/Cadastro | `solicitacao/ui.md` §8 |
| **QA-19** | **Campos do cadastro de Cliente** público vs privado (público: vínculo de governo/edital; privado: plano/CNPJ?) não confirmados. | Cadastro | `clientes-hcs/ui.md` §8 |
| **QA-20** | **Validação/origem do CNES:** digitado livre ou validado contra base externa? E se o HC não tiver CNES? | Cadastro | `clientes-hcs/ui.md` §8 |
| **QA-21** | **LGPD do paciente:** base legal, escopo de tratamento e retenção não definidos (afeta RN-44). | Auditoria | `01-domain-overview.md` "restrições"; `01-domain-model.md` §2 ⑨ |
| **QA-22** | **Definição de "integrado" no nosso sistema** e quais **KPIs exatos** entram na v1 do Painel (a planilha vem do hub AM; mesmo conceito?). | Monitor | `painel/ui.md` §8 |
| **QA-23** | **Histórico/diff entre períodos** (dor nº 1 do Excel: falta de diff) — está no escopo da v1? | Monitor | `painel/ui.md` §8 |

> Nota de governança: mudanças nas regras ✅ após congelamento passam pelo controle de mudança (a
> definir na Fase 4), conforme `decisions-log.md`.
