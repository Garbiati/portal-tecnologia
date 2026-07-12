# Teleconsulta (legado) — mapa do ecossistema que o doctor-hub reescreve

> **Nível PLATAFORMA** (não é doc do doctor-hub — é a realidade do sistema que ele reescreve; D-209).
> Síntese para a reescrita; o detalhe vivo mora no próprio Teleconsulta: `workspace/teleconsulta/docs/`
> (`architecture/service-map.md`, `architecture/white-label.md`, `business/glossary.md`) e
> `.claude/rules/multi-tenancy.md`. **Aqui: o essencial + a fronteira doctor-hub↔Teleconsulta.** Só estrutura, zero PII.

## Topologia (26 serviços; `ptm-core-api` é o coração)
- **`ptm-core-api`** concentra ~39% da lógica (paciente, médico, HC, agendamento/ExternalAppointment, especialidade, reminder) — **bus factor 1** (risco). 2 bancos: **CORE** (negócio) e **AUTH** (identidade, no `ptm-auth-server`).
- Backend .NET (19): core-api, auth-server, **matching-api** (fila SOS/pareamento), **time-slots-service** (vagas), videoconference (Agora), **messaging-service** (RabbitMQ), chat-api (Spanner), push-notification, address, query-logger, measurements (Python), doctors-reports (Python), memed-api (prescrição), audit (Mongo), shared…
- Node (support): **template-manager** (templates de mensagem, Mongo), html-renderer, socket-sos.
- Front: ptm-web (Angular), ptm-web-react (white-label), saude-digital-admin (Vue). Mobile: ptm-mobile (RN).
- **Comunicação:** REST ponto-a-ponto (core↔auth/matching/time-slots/memed) + **RabbitMQ** (eventos) + WebSocket (SOS) + Spanner (chat). Infra dev: docker-compose; prod GCP (Cloud SQL + Secret Manager).

## Distribuição de dados (quem é dono do quê)
| Domínio | Dono | Banco | Tabelas-chave |
|---|---|---|---|
| Paciente (LGPD) | core-api | CORE | `patient_profiles`, `health_center_patient_profiles` (CPF por HC, sem unicidade global — débito D-191) |
| Médico | core-api | CORE + AUTH | `doctor_profiles` (+ licenses) · identidade partida em 2 bancos |
| Health Center (=tenant) | core-api | CORE | `health_centers` |
| Unidade | core-api | CORE | `profile_tags` (CNES) |
| Especialidade | core-api | CORE | `specialties` (InternalSpecializationId) |
| Agendamento | core-api | CORE | `appointments`, **`external_appointments`** (parceiros via API), status_history |
| Vagas/slots | time-slots-service | CORE | `time_slots`, `doctor_availability` |
| Fila SOS/matching | matching-api | CORE | `live_queue`, `pairings` |
| Reminder | core-api | CORE | `reminder_jobs` |
| WhatsApp (log) | core-api | CORE | `whats_app_message_logs` |
| Auth/identidade | auth-server | AUTH | `users`, `roles`, `permissions`, `session_tokens` |
| Chat | chat-api | Spanner | (isolado — não segue o multi-tenant por-row) |
| Auditoria | audit | Mongo | eventos imutáveis |
| Templates | template-manager | Mongo | por HC |

## Multi-tenancy do legado (valida/ajusta o nosso D-197..D-211)
- **`HealthCenter` = o tenant.** NÃO há nível acima — "Domain" no HC é só um campo de URL/branding, não agrupador. (Nosso modelo ADICIONA `Tenant` acima do Cliente/HC — para a coopetição/D-211 — e `Unidade` = `ProfileTag`.)
- **Isolamento = `WHERE health_center_id` OBRIGATÓRIO** em toda query multi-tenant (schema + repository + service + controller + cache-key + log). É o "isolamento por-row". O `health_center_id` vem do **claim JWT** (Keycloak/auth-server) via `SessionContextAuthorizationFilter`.
- **Doutor é N:N com HC** (`DoctorProfile` global + `HealthCenterDoctorProfile` com status/flags por HC) — já é um **catálogo compartilhado com status por HC**. Valida a nossa visão "Netflix de doutores" (D-211): o legado já faz doctor↔HC N:N; nós formalizamos com golden record + vínculo.
- **Débitos conhecidos:** BUG-005 (UPDATE sem filtro HC contaminou HCs), BUG-006 (race no matching cross-HC), CPF sem unicidade + identidade em 2 bancos (D-191). ⇒ o nosso isolamento fail-closed (D-200/D-206) e o EMPI (D-191) **corrigem exatamente esses**.

## Reminder + WhatsApp (o que replicar)
- **Reminder:** agendado por **Hangfire** no core-api (`ReminderHangfireClient` → `BackgroundJob.Schedule` em `MessageTime = start - offset`). Persistido em `reminder_jobs`. Gatilhos no `ExternalAppointmentService`: criar → agenda; reagendar → cancela+recria; cancelar/expirar → deleta.
- **WhatsApp:** provedor **Infobip** (`InfobipService`) — templates (via template-manager) com botões (CONFIRMO/NÃO PRECISO/…), + SMS failover. Logs em `whats_app_message_logs` (status sent/delivered/read/failed + ação do paciente), sincronizados via SFTP.
- **Fronteira p/ nós:** quando o doctor-hub for dono do agendamento, o **reminder+WhatsApp** é uma das funcionalidades a **importar** (Hangfire+Infobip ou equivalente) — ver `teleconsulta-rewrite-progress.md`.

## A fronteira doctor-hub ↔ Teleconsulta (hoje)
- **`external_appointments`** é a porta: o Teleconsulta **recebe** agendamentos de parceiros por API (é o alvo do nosso pull+ack/write-back, D-196).
- **Lookup de paciente por CPF** (D-002) e **sync de médicos** (D-133, RO) já ligam o doctor-hub ao core-api.
- O detalhe do que já importamos × ainda integramos: `teleconsulta-rewrite-progress.md`.
