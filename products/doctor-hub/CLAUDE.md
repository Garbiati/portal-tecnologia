# Doctor-Hub — Constituição do Produto

> **Recorte de produto.** Esta é a constituição do **Doctor-Hub**, o 1º produto da plataforma.
> A **constituição-mãe** (Diretriz Suprema, método SDD/TDD, segurança/LGPD, princípios de risco)
> está na raiz: [`../../CLAUDE.md`](../../CLAUDE.md) — **leia-a primeiro**. Aqui ficam só os
> recortes **específicos do Doctor-Hub** (domínio, papéis, fases, regras do protótipo).
>
> Caminhos neste arquivo: `docs/…` = docs **deste produto** (`products/doctor-hub/docs/…`);
> `../../docs/…` = governança de plataforma.

## 🎯 O que é o Doctor-Hub

Sistema de **planejamento de capacidade médica** (oferta × demanda) para health centers (HCs) de
governos. Fica **a montante** do produto de Teleconsulta existente (`/home/alessandro/ptm/teleconsulta`)
e **alimenta** a Teleconsulta com agendamentos prontos — **não a substitui**.

Pipeline: **Oferta (escala dos médicos) → Demanda (solicitação dos governos) →
Alocação (disponibilização: simular/reservar/emitir) → Remanejamento → Agendamento → Teleconsulta.**

Detalhe verificado do domínio: [`docs/discovery/01-domain-overview.md`](docs/discovery/01-domain-overview.md).

## 👥 Papéis (hipótese — nomes provisórios)

Admin, Demandas, Solicitante, Doutor, Paciente, Gestor. Só 3 papéis logam (Admin/Demandas,
Solicitante, Gestor); Doutor/Paciente são dados. Detalhe e perguntas: [`docs/discovery/02-roles.md`](docs/discovery/02-roles.md).
**Nada é definitivo sem `✅ Confirmado`** no [`docs/decisions/decisions-log.md`](docs/decisions/decisions-log.md).

## 🚦 Gate de fase (atualizado 2026-06-16)

Descoberta essencial fechada; Alessandro optou por **CONSTRUIR um protótipo funcional** (D-030) →
estamos na **Fase 6 (Construir)**. Produto reposicionado para **"Doctor-Hub" — gestão de médicos**
(D-055); **1ª entrega = Fase 1 do roadmap da diretoria: escala médica + cadastro-dono do médico**
(D-052), sobre **dados reais de produção** (médicos via sync RO).

| Fase | Foco | Saída | Status |
|------|------|-------|--------|
| 1. Descobrir & Definir | Entender o problema | Domínio, papéis, perguntas, critérios | 🟢 Fechada |
| 2. Pesquisar | Frameworks AI-coding, SDD, segurança | Método/ferramental | 🟢 Feita (`../../docs/method/`) |
| 3. Arquitetura de contexto | Agents, skills, MCP, RAG, docs | Pasta pronta pra IA | 🟢 Fundação feita |
| 4. Estimar & Contratar | Escopo congelado, horas, custo, gates | Proposta | 🔵 Rascunho em `docs/product/` |
| 5. Desenhar (Figma) | Telas | Protótipo | ⚪ Pulada — protótipo funcional (D-030) |
| 6. Construir | Front, back, banco | Sistema | 🟢 **EM ANDAMENTO** — `services/doctor-hub-api` (.NET 10) + `services/doctor-hub-web` (React PWA); walking skeleton verde (D-109/D-110) |

## 🧱 Stack (D-109, adota o baseline da plataforma)

**.NET 10 + EF Core 10 + Dapper + Postgres** (`services/doctor-hub-api`, xUnit); **React + Vite + TS
+ Tailwind + PWA mobile-first** (`services/doctor-hub-web`, Vitest); infra **GCP** (Cloud Run + Cloud
SQL + Secret Manager — a confirmar c/ infra da Portal). Reabrir só por decisão registrada.

## 🔁 Sync com a Teleconsulta (D-069) — específico do Doctor-Hub

Segue o baseline de plataforma ([`../../docs/security/security-baseline.md`](../../docs/security/security-baseline.md)):
PULL é **read-only**; **PUSH só via credencial dedicada + allowlist tabela:colunas + dry-run +
`--apply` + log**, nunca DELETE/DROP/TRUNCATE, UPDATE sempre com WHERE por `external_id`,
**mapeamento confirmado pelo humano**.

## 🧩 COERÊNCIA DO PROTÓTIPO (regra dura, 2026-06-20)

Todo dado de demo vem da **fixture canônica** ([`docs/product/22-demo-fixtures.md`](docs/product/22-demo-fixtures.md))
— **nunca digitar dados à mão por tela**. Variantes/filtros são **subconjuntos derivados** (ex.: Com
escala + Sem escala = Todos, por construção). **Antes de entregar QUALQUER conjunto de telas, rodar a
REVISÃO DE COERÊNCIA:**

(a) **invariantes** — união dos filtros = total; mesma entidade = mesmos atributos em todas as telas;
   todo link leva a destino coerente; o fluxo continua de uma tela à seguinte;
(b) **agente revisor adversarial** — navega como usuário cético e reporta furos;
(c) **LINTER DE NAVEGAÇÃO** ([`docs/product/23-navegacao-contrato.md`](docs/product/23-navegacao-contrato.md), D-106) —
   **isolamento de persona** (troca só pelo avatar→Seletor; nenhum botão cruza Demandas↔Regulação↔Gestor),
   **alcançabilidade** (toda tela a partir do Login), **0 clicks mortos**, **0 órfãs**;
(d) **CICLO DE VIDA DE TELA** ([`docs/product/24-registro-telas.md`](docs/product/24-registro-telas.md), D-108) —
   **1 tela canônica por intenção**; ao superar uma tela, **APAGAR a antiga e REPONTAR todas as
   referências** (nunca "v2" convivendo com "v1"); rodar os 2 detectores (duplicatas/PROVISÓRIO/órfãs +
   consistência de clique: mesmo rótulo → destinos diferentes).

**Não dizer "pronto" sem isso.** O usuário não deve precisar caçar furo de coerência (de dados,
navegação, ou tela duplicada/desatualizada).

## 📌 Estado atual (Doctor-Hub)
- **Decisões:** [`docs/decisions/decisions-log.md`](docs/decisions/decisions-log.md) (D-001..D-110).
  Início do build real: D-109; estrutura do hub: D-110 (renomeado **portal-platform** em P-002).
- **Protótipo Figma** (homologação visual, referência de produto): fileKey `snTNGRUJO2GwoKpXTHCBjf`.
- **Perguntas abertas:** [`docs/discovery/03-open-questions.md`](docs/discovery/03-open-questions.md).

_Última atualização: 2026-06-23 (movido p/ products/doctor-hub sob a governança multi-produto — P-001)._
