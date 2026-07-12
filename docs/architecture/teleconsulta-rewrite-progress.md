# Reescrita da Teleconsulta — rastreador de integração × importação

> **Nível PLATAFORMA** (D-209: doctor-hub reescreve progressivamente a Teleconsulta). Rastreia, por
> funcionalidade: **INTEGRAMOS** (o doctor-hub chama o Teleconsulta) × **IMPORTAMOS** (reescrito, mora
> no doctor-hub) × **AINDA NÃO** (nem toca). Mapa da fonte: `teleconsulta-legado.md`. Atualizar quando um item mudar.

## Legenda
- 🟢 **Importado** — reescrito, fonte-da-verdade é o doctor-hub.
- 🟡 **Integrado** — o doctor-hub chama a Teleconsulta (RO ou write-back).
- 🔵 **Em obra** — decidido/na fila (ver horizonte no `products/doctor-hub/docs/roadmap-horizontes.md`).
- 🔴 **Ainda não** — mapeado, não tocado.
- ⚪ **Fora de escopo (por ora)** — sistema próprio/paralelo.

## Rastreador
| Funcionalidade | Status | Onde / como | Ref |
|---|---|---|---|
| **Especialidade** | 🟢 Importado | seed mapeado por `InternalSpecializationId` | mapa-fontes |
| **Cliente/HC · Unidade** | 🟢 Importado (modelo) | `Cliente`(+ExternalId) · `Unidade`(+CNES); hierarquia Tenant›Cliente›Unidade | D-197/D-207 |
| **Médico (cadastro)** | 🟢 casa nova + 🟡 sync RO | `Doctor`(ExternalId); sync TC→doctor-hub | D-133 |
| **Paciente (identidade)** | 🟢 EMPI + 🟡 lookup CPF | golden record (`PacienteCanonico`) + lookup por CPF na TC | D-191/D-002 |
| **Escala** | 🟢 casa nova | não existe na TC; modelo próprio (blocos/vigência/pool×dedicada) | fundação |
| **Agendamento** | 🟢 casa nova | state machine + outbox (Pendente→Confirmado…); isolamento por ClienteId | D-192/D-197 |
| **Vínculo médico↔cliente + vaga-por-vínculo** | 🟢 casa nova | DoctorVinculo N:N; "Netflix de doutores" formalizado | D-198/D-202/D-211 |
| **Isolamento multi-tenant** | 🟢 casa nova (mais rígido) | global query filter fail-closed (corrige BUG-005/006 da TC) | D-200/D-206 |
| **Write-back agendamento (pull+ack)** | 🔵 Em obra | alvo = `external_appointments` da TC | D-196 |
| **Migração do histórico (SOS Gestor)** | 🔵 Em obra | ingestor da API do SOS Gestor (+ snapshot) | D-209 |
| **Reminder (lembrete)** | 🔴 Ainda não | TC: Hangfire no core-api (`reminder_jobs`) | legado |
| **WhatsApp (envio + log)** | 🔴 Ainda não | TC: Infobip + templates + `whats_app_message_logs` | legado |
| **Fila/matching (SOS)** | 🔴 Ainda não | TC: `matching-api` (`live_queue`, `pairings`) | legado |
| **Vagas/slots** | 🔴 Ainda não (temos escala própria) | TC: `time-slots-service` | legado |
| **Faturamento/ROI** | 🟢 parcial (casa nova) | `DoctorFaturamento` por tipo de serviço | D-169 |
| **Regulação SISReg** | ⚪ Sistema próprio | `regula-hub`/`regula-sisreg` (bypass SOS Gestor) | D-209 |
| **Videoconferência (Agora)** | 🔴 Ainda não | TC: `videoconference-service` | legado |
| **Chat** | 🔴 Ainda não | TC: `chat-api` (Spanner, isolado) | legado |
| **Prescrição (Memed) · Transcrição · Medições · Relatórios** | 🔴 Ainda não | TC: memed-api · transcription · measurements · doctors-reports | legado |
| **Auth/identidade** | 🟡 Integrado (Keycloak próprio) | `portal-identity` (Keycloak) — paralelo ao `auth-server` da TC | P-003 |
| **Auditoria** | 🟢 casa nova (parcial) | `Auditoria` (LGPD, só iniciais) | D-123 |

## Leitura rápida (o quanto já está em casa)
- **Núcleo de gestão (oferta/escala/agendamento/vínculo/isolamento) = 🟢 em casa nova** — é o que a reescrita atacou primeiro (o que mais causa registro paralelo).
- **Identidade (médico/paciente/cliente/unidade/especialidade) = 🟢 modelo importado**, ainda 🟡 hidratando da TC (sync/lookup) até a migração real.
- **Comunicação (reminder/WhatsApp), fila SOS, vídeo, chat, prescrição = 🔴 ainda na TC** — próximos alvos da reescrita progressiva, por horizonte.
- **Regulação (SISReg) = ⚪ sistema próprio** (regula-hub), não é reescrita do core da TC.
