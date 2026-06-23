# Glossário / Ubiquitous Language (RASCUNHO)

> Linguagem única do domínio. Agentes e código DEVEM usar exatamente estes termos.
> Cada termo nasce como rascunho e só estabiliza com `✅ Confirmado`.

| Termo | Significado (provisório) | Status |
|---|---|---|
| **HC (Health Center)** | Unidade de saúde do governo que recebe a oferta de atendimento | 🟡 |
| **Escala fixa** | Disponibilidade recorrente de um médico (dias, horários, período de validade) | ✅ |
| **Horas adicionais** | **Rótulo de UI** (D-075) para a *escala/disponibilidade adicional* (D-053): disponibilidade **excepcional por dia**, com **taxa própria**, sobre uma escala fixa ativa. Código permanece `additional_schedules`/`additional_hourly_rate` (D-057). Substitui o rótulo "Disponibilidade adicional" na UI. | ✅ |
| **Estoque** | Conjunto de vagas/slots disponíveis derivado das escalas (+ ajuste manual) | 🟡 |
| **Vaga / Slot** | Uma unidade de atendimento alocável (provavelmente = 1 consulta) | ❓ definir unidade |
| **Cobertura** | Mapa de quem atende o quê, quando (por especialidade/médico/dia) | ✅ |
| **Solicitação** | Pedido de um governo: especialidades × quantidade × período (mês) por HC | ✅ |
| **Disponibilização** | Processo de casar demanda × estoque e liberar vagas | ✅ |
| **Simular** | Calcular saldo (demanda × estoque) sem efetivar | ✅ |
| **Reservar** | Bloquear escalas e baixar do estoque (estado intermediário) | 🟡 |
| **Emitir** | Publicar a escala para o HC poder assumir | 🟡 |
| **Assumir** | Ação do HC de aceitar/efetivar uma vaga emitida | ❓ definir |
| **Retornos / Extras** | Ajuste manual de demandas médicas sobre o estoque | ❓ definir |
| **Remanejamento** | Realocar vagas não assumidas para outros HCs (regras determinísticas) | 🟡 |
| **Agendamento** | Resultado final: médico + paciente + especialidade + HC → enviado à Teleconsulta | ✅ |
| **Teleconsulta** | Produto existente; sistema de registro do atendimento (destino do agendamento) | ✅ |

---

## Mapa de Identificadores PT→EN — código & schema (D-057, 2026-06-15)

> **Regra:** **código/identificadores/tabelas/colunas/contrato-JSON = inglês `snake_case`** (Postgres)
> e `camelCase` (TS/JSON) / `PascalCase` (C#). **TEXTO de UI permanece em PORTUGUÊS** (produto BR de
> saúde pública). Este mapa é o **contrato canônico** — as 3 camadas (SQL, .NET, React) usam exatamente isto.

### Tabelas
| PT (atual) | EN (novo) |
|---|---|
| `health_centers` | `health_centers` (mantém) |
| `unidades` | `units` |
| `especialidades` | `specialties` |
| `doctors` | `doctors` (mantém) |
| `pacientes` | `patients` |
| `blocos_escala` | `schedule_blocks` |
| `escala_adicional` | `additional_schedules` |
| `solicitacoes` | `requests` |
| `pools` | `pools` (mantém) |
| `reservas` | `reservations` |
| `agendamentos` | `appointments` |
| `usuarios` | `users` |
| `hc_especialidades` | `health_center_specialties` |
| — (novo) | `doctor_external_refs` (vínculo médico↔destino) |

### Colunas / campos
| PT | EN |
|---|---|
| `nome` | `name` |
| `tipo` | `type` |
| `uf` | `uf` (mantém — sigla de estado BR) |
| `cnes_code` | `cnes_code` (mantém) |
| `profile_tag_type` | `profile_tag_type` (mantém) |
| `teto_diario` | `daily_cap` |
| `crm` | `crm` (mantém — registro profissional BR) |
| `especialidade_id` | `specialty_id` |
| `unidade_id` | `unit_id` |
| `dias` | `days` |
| `inicio` | `start_time` |
| `fim` | `end_time` |
| `duracao_min` | `duration_min` |
| `competencia` | `period` ('YYYY-MM') |
| `solicitado` | `requested` |
| `solicitante_nome` | `requester_name` |
| `quantidade` / `qtd` | `quantity` |
| `reserva_id` | `reservation_id` |
| `paciente_id` | `patient_id` |
| `paciente_nome` | `patient_name` |
| `scope_unidade_id` | `scope_unit_id` |
| `scope_health_center_id` | `scope_health_center_id` (mantém) |
| `is_active` | `is_active` (mantém) |
| `data` (dia) | `date` |
| `valor_hora` | `hourly_rate` (legado — ver D-085) |
| `valor_por_atendimento` | `fee_per_appointment` (**D-085** — modo "por consulta" do Teleconsulta) |
| `tempo_de_atendimento` | `appointment_duration_min` (**D-085** — por especialidade; define os slots) |
| `modo_de_cobranca` | `billing_mode` (**D-086** — Teleconsulta: `por_hora` \| `por_consulta`, por especialidade) |
| `valor_por_hora` (teleconsulta) | `hourly_fee` (**D-086** — quando modo = por hora) |
| `valor_por_laudo` | `fee_per_report` (**D-086** — Telediagnóstico, por tipo de exame) |
| `tipo_de_exame` / `modalidade` | `exam_type` / `modality` (**D-086** — chave do valor no Telediagnóstico) |
| `produto` | `product` (**D-086** — `teleconsulta` \| `telediagnostico`; faturamento separado) |
| `motivo` | `reason` |

### `doctors` como CADASTRO-DONO (D-055) — colunas novas
`name`, `crm`, `specialty_id` (mantém) + **novas:** `rqe`, `cpf`, `phone`, `email`,
`birth_date`, `fixed_hourly_rate` (valor hora fixa), `additional_hourly_rate` (valor hora adicional),
`active` (boolean), `source` (origem do registro, ex.: `teleconsulta-sync`), `synced_at`.
> A antiga coluna `external_id` **sai de `doctors`** e vira linha em `doctor_external_refs`.

### `doctor_external_refs` (vínculo por destino, D-057)
`id`, `doctor_id` → `doctors(id)`, `system` (`teleconsulta` | `telediagnostico` | futuro),
`external_id` (id do médico NO destino — distinto por sistema), `status`, `created_at`, `updated_at`.

### Papéis (role keys) — mantêm chave, label PT
`admin`, `demandas`, `solicitante`, `gestor` (chaves de código inalteradas; labels de UI em PT — ver D-048).
