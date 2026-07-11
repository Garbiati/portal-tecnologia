---
id: SPEC-AGENDAMENTO-RESILIENTE
title: Agendamento resiliente — solicitação local + confirmação assíncrona
status: draft            # draft | specified | tested | implemented
owner: Alessandro
area: Agendamento
clickup: ""
figma: ""
validated_by: ""         # preenchido quando humano confirma (status: specified)
validated_at: ""
last_update: 2026-07-10
---

# Agendamento resiliente — solicitação local + confirmação assíncrona

> **Base:** D-192 (regra fundadora) + **D-193** (Fase 1 = só a nossa parte; saída ao cliente atrás de
> porta abstrata, adiada) + **D-194** (Central de Mensagens = canal do REJEITADO). Conecta DEP-TC-1
> (integração real que estava pendente), D-069 (sync ao cliente nunca destrutivo) e D-191/EMPI.
> **Fase 1 DESBLOQUEADA (D-193):** o único 🔴 que travava (contrato do cliente) foi adiado por decisão;
> outbox + state machine são nossos e testáveis sem cliente real. A **Fase 2** (adapter de PUSH real +
> pacote premium) e a **Central de Mensagens** (D-194) são trilhas próprias — seguem com 🔴 abaixo.
>
> **✅ Fase 1 CONSTRUÍDA (2026-07-10, doctor-hub-api @ commit a9c150b):** `StatusSolicitacao` +
> `AgendamentoOutbox` (gravado na mesma transação do POST) + `IAgendamentoSyncPort`/`StubAgendamentoSyncPort`
> + `EntregaAgendamentoRunner` + `EntregaAgendamentoBackgroundService` (**desligado por padrão** —
> `AgendamentoSync:Enabled=false`). 6 testes verdes (outbox atômico + as 4 transições + backoff +
> idempotência); revisor de segurança/LGPD aprovado. Migration `AddStatusAgendamentoEOutbox` com backfill
> de legado → `Confirmado`. **Comportamento em prod hoje:** todo agendamento novo nasce `Pendente` e
> **permanece Pendente** (não há destino real até a Fase 2 ligar o adapter + `Enabled=true`).

## 1. Problema / Dor  _(Definition of Success)_

- **Dor:** hoje o `POST /agendamentos` grava como fato consumado, **não valida se a vaga existe/está
  livre** e **nunca envia ao cliente** (`EnviadoTc=false` sempre). Consequências: (a) dois operadores
  podem assumir o **mesmo slot** sem que nada trave (duplo-agendamento); (b) se o sistema do cliente
  estiver fora, ou não há como agendar, ou agenda-se "no escuro" sem nunca reconciliar.
- **De quem:** operador/gestor que assume vaga; e o próprio negócio (um agendamento que não chega ao
  sistema do cliente não vira atendimento real).
- **Evidência:** recon do fluxo (2026-07-10) — `SolicitacaoEndpoints.cs:203–248` grava o `vagaId` como
  string sem checagem; `Agendamento.EnviadoTc` é sempre `false` (DEP-TC-1).
- **Sucesso = quando:** o operador consegue **registrar a intenção de agendar mesmo com o cliente
  offline**, e o sistema **reconcilia sozinho** quando o cliente volta — confirmando o que couber e
  **rejeitando explicitamente** o que conflitar, sem nunca sobrescrever a agenda do cliente.

## 2. Função  _(o "o quê")_

O DoctorHub deixa de tratar o agendamento como fato consumado e passa a tratá-lo como uma
**solicitação de agendamento** com ciclo de vida próprio:

1. O operador assume a vaga (tela **AssumirVaga**, já existente). A solicitação é **aceita na hora,
   localmente** — não depende do sistema do cliente estar no ar.
2. A solicitação entra em uma fila de **entrega assíncrona** ao sistema do cliente.
3. Quando o cliente responde: **CONFIRMADO** (a agenda dele aceitou) ou **REJEITADO** (a vaga já
   estava ocupada lá — conflito). Enquanto o cliente está fora, a solicitação fica **pendente** e é
   **retentada** automaticamente.
4. A tela reflete o status; no **REJEITADO**, o operador é avisado e escolhe outra vaga.

**Princípio inegociável (D-192):** o **sistema do cliente é sempre a fonte da verdade** da agenda.
Em conflito, quem "perde" é o DoctorHub. Nunca sobrepomos/forçamos no cliente.

## 3. Regras de negócio  _(somente CONFIRMADAS)_

- ✅ **A realidade do cliente é a fonte da verdade da vaga/agenda.** — _Confirmado por Alessandro em 2026-07-10 (D-192)_
- ✅ **A solicitação de agendamento é aceita localmente mesmo com o sistema do cliente offline**;
  a confirmação vem depois, quando integra. — _Confirmado por Alessandro em 2026-07-10 (D-192)_
- ✅ **Em conflito, a solicitação volta REJEITADA para nós** (nós reagimos do nosso lado). — _Confirmado por Alessandro em 2026-07-10 (D-192)_
- ✅ **Não existe "sobrepor no cliente".** A ideia de um toggle/feature de override está **descartada**
  (destrutivo + violaria D-069). — _Confirmado por Alessandro em 2026-07-10 (D-192)_
- ✅ **A entrega ao cliente é idempotente** (retry não pode duplicar o agendamento no sistema do
  cliente; chave = id da solicitação). — _Confirmado por Alessandro em 2026-07-10 (D-192, "sync … idempotente")_
- ✅ **O PUSH ao cliente segue o baseline D-069** (credencial dedicada, nunca DELETE/DROP/TRUNCATE,
  `UPDATE` só com `WHERE` por `external_id`). — _Confirmado (herdado de D-069)_
- ✅ **Quem pode agendar = AMBOS (Gestor e Operador).** — _Confirmado por Alessandro em 2026-07-10 (D-193)_
- ✅ **A saída ao cliente fica atrás de uma porta abstrata** (`IAgendamentoSyncPort`). A Fase 1 não
  integra com cliente real (entregador stub). — _Confirmado por Alessandro em 2026-07-10 (D-193)_
- ✅ **O modelo default de integração é PULL+ACK, não push:** o CLIENTE **vem buscar** as solicitações
  pendentes (pull) e/ou é **notificado por webhook** para buscar; ele **pega e confirma que pegou e deu
  certo** (ack), **assíncrono**. **Nós expomos o contrato** que o cliente consome — não precisamos
  conhecer a API dele. A confirmação do cliente dirige o estado (Pendente→Confirmado; conflito→Rejeitado).
  — _Confirmado por Alessandro em 2026-07-10 (D-195)_
- ✅ **O "pacote premium" é serviço OPCIONAL** (a Portal adapta o sistema do cliente), **não** a fase nem
  pré-requisito. — _Confirmado por Alessandro em 2026-07-10 (D-195, corrige D-193)_
- ✅ **O REJEITADO é comunicado ao usuário pela Central de Mensagens** (inbox in-app + e-mail), não por
  erro síncrono na modal (a rejeição pode chegar depois). — _Confirmado por Alessandro em 2026-07-10 (D-194)_

## 4. Critérios de aceite  _(a fonte do teste — Gherkin/BDD)_

> Cobrem apenas o comportamento das regras já confirmadas (seção 3). Os cenários que dependem de
> pergunta aberta estão marcados `# BLOQUEADO por 🔴` e não viram teste até a decisão.

```gherkin
Cenário: assumir vaga cria uma solicitação PENDENTE mesmo com o cliente offline
  Dado uma vaga livre e o sistema do cliente indisponível
  Quando o operador confirma o agendamento
  Então a solicitação é gravada com status PENDENTE
  E a resposta ao operador é de sucesso (a intenção foi registrada)
  E nada foi escrito no sistema do cliente ainda

Cenário: a entrega assíncrona confirma quando o cliente aceita
  Dada uma solicitação PENDENTE
  Quando o entregador envia ao cliente e o cliente aceita
  Então a solicitação passa a CONFIRMADO
  E o agendamento fica vinculado ao id externo devolvido pelo cliente

Cenário: conflito no cliente rejeita a solicitação (cliente é a fonte da verdade)
  Dada uma solicitação PENDENTE para uma vaga que, no cliente, já está ocupada
  Quando o entregador envia ao cliente e o cliente recusa por conflito
  Então a solicitação passa a REJEITADO
  E o DoctorHub NÃO tenta sobrescrever a agenda do cliente
  E o operador é notificado para escolher outra vaga

Cenário: cliente fora do ar não perde a solicitação (retry)
  Dada uma solicitação PENDENTE e o cliente temporariamente indisponível
  Quando a entrega falha por indisponibilidade
  Então a solicitação continua pendente (FALHA_TEMP) e é retentada com backoff
  E nenhuma solicitação é descartada silenciosamente

Cenário: idempotência — retry não duplica no cliente
  Dada uma solicitação já entregue ao cliente
  Quando o entregador reenvia a mesma solicitação (mesma chave)
  Então o cliente reconhece a chave e NÃO cria um segundo agendamento

Cenário: atomicidade (outbox) — agendamento e evento de sync vivem/morrem juntos
  Quando a solicitação é gravada
  Então o evento de entrega é gravado na MESMA transação
  E se a transação falha, nem o agendamento nem o evento existem
```

## 5. Definition of Done

- [ ] Todos os cenários (não-bloqueados) da seção 4 passam como teste automatizado (xUnit)
- [ ] Sem perguntas abertas 🔴 pendentes
- [ ] Validado por humano (preencher `validated_by`)
- [ ] `Agendamento` com state machine persistida + migration versionada
- [ ] Entrega assíncrona (outbox + entregador) com retry/backoff e idempotência, coberta por teste
- [ ] Tela AssumirVaga reflete o status (pendente/confirmado/rejeitado) — coerência D-106/D-108
- [ ] Revisão de segurança/LGPD do diff (o pacote de PUSH respeita D-069; PII só o necessário)

## 6. Fora de escopo

- **Sobrepor/forçar no cliente** — descartado por decisão (D-192). Não é "fora de escopo temporário",
  é regra: não existe.
- **Saldo/pool × teto** (D-190) — a reconciliação com saldo é fase própria; ver pergunta aberta 🟡.
- **Resolução automática do EMPI (`PacienteId`) no POST** — Fase 2 do D-191; aqui só entra se/quando
  já resolvido (o pacote de sync carrega o que houver).
- **Adapters reais por cliente** — esta spec desenha o mecanismo; o adapter de PUSH real de cada
  cliente (contrato/credencial) é onboarding separado.

## 7. Dependências & Integrações

- **DEP-TC-1** — esta spec É a integração real de saída que estava pendente (`EnviadoTc` deixa de ser
  sempre `false`).
- **D-069** — o PUSH ao cliente segue o baseline (credencial dedicada, allowlist, nunca destrutivo,
  `WHERE` por `external_id`).
- **D-191/EMPI** — `PacienteId` (golden record) e/ou `PacienteIdTc` compõem a identidade do paciente
  no pacote de sync.
- **Arquitetura recomendada (a validar):** **Transactional Outbox** no Postgres (Cloud SQL) +
  **entregador com retry/backoff**; no GCP, **Cloud Tasks** é o encaixe natural. Kafka/RabbitMQ são
  overkill para o volume/contexto de um dev solo — reabrir só se um requisito concreto pedir
  (fan-out multi-consumidor, alto throughput, replay).

## 8. Perguntas abertas  _(NÃO INFERIR — perguntar)_

- ✅ **RESOLVIDO (D-193) — Quem pode agendar:** ambos (Gestor e Operador).
- ✅ **RESOLVIDO (D-195) — Direção da integração:** default é **pull+ack** (o cliente busca e confirma,
  assíncrono); nós expomos o contrato. Isso **dissolve** o antigo 🔴 "contrato do PUSH ao cliente" — não
  precisamos da API do cliente. O push (`IAgendamentoSyncPort`) fica como transporte alternativo.
- 🔴 **Fase 2 (endpoints pull+ack) — SEGURANÇA, superfície externa autenticada expondo agendamento.**
  Decidir com humano ANTES de construir: (1) **auth do cliente** — credencial/API key dedicada por
  cliente, isolamento por tenant (nunca um cliente vê o do outro); (2) **escopo** do que ele busca (só
  as solicitações do próprio cliente); (3) **semântica do ack** — uma confirmação "peguei+deu certo" ou
  duas fases ("peguei" → depois "processei: ok|conflito"); (4) **LGPD** — o que pode ser exposto ao
  cliente (iniciais? ids? external_id?); (5) **idempotência do pull** (buscar o mesmo lote 2x sem
  duplicar/pular).
- 🟡 **Trilha própria (D-194) — Central de Mensagens:** direção confirmada (inbox in-app + e-mail);
  detalhes abertos (quais eventos, entrega, lido/não-lido, destinatário por papel, retenção, tempo
  real vs. polling). A Fase 1 do agendamento só precisa **definir o estado REJEITADO**, não a UI.
- 🟡 **Reconciliação com o SALDO (D-190):** a solicitação decrementa saldo na criação (otimista) ou só
  na confirmação? E se rejeitar depois de ter decrementado?
- 🟡 **Concorrência local:** duas solicitações locais para o mesmo `vagaId` — deixamos as duas irem ao
  cliente e ele arbitra, ou barramos a segunda já no DoctorHub? (D-192 permite "ambas viram
  solicitação"; confirmar se há alguma trava local desejável mesmo assim).
- 🟡 **Janela de expiração:** uma solicitação PENDENTE que nunca confirma (cliente fora por dias) —
  expira? Após quanto tempo? Alguém é avisado?
- 🟢 **Transporte definitivo:** começar com Outbox + Cloud Tasks e migrar para Pub/Sub/broker só se
  necessário — confirmar que essa progressão está ok.
- 🟢 **Observabilidade:** painel de solicitações por status (fila/confirmadas/rejeitadas) —
  provavelmente encaixa no `monitor-integracao` existente.
