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

> **Base:** D-192 (regra fundadora) · conecta DEP-TC-1 (integração real que estava pendente),
> D-069 (sync ao cliente nunca destrutivo) e D-191/EMPI (o `PacienteId` resolvido entra no pacote).
> **Rascunho — NÃO implementar.** Enquanto houver 🔴 na seção 8, a spec não vira `specified`.

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

- 🔴 **Contrato do PUSH ao cliente:** qual é a API/interface de "criar agendamento" no sistema do
  cliente (na TC, é o `ptm-core-api`?), como ela sinaliza **conflito** vs **indisponível**, e qual a
  **credencial** (D-069)? Sem isso, o entregador não tem alvo.
- 🔴 **UX do REJEITADO:** o que o operador vê e faz quando uma solicitação volta rejeitada? Reabre o
  modal na mesma vaga? É empurrado para outra vaga? Notificação assíncrona (a solicitação pode ser
  rejeitada minutos depois, com o operador já em outra tela)?
- 🔴 **Quem pode agendar** (herdado D-011): Gestor, Operador, ou ambos? (o mapa D-187 hoje dá a
  Gestor/Demandas; o Operador ainda não existe no Keycloak).
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
