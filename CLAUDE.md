# ptm-platform — Spec Hub da Plataforma (constituição)

> **Este repositório é o spec-hub** da plataforma interna da empresa (análogo ao
> `../teleconsulta`): guarda **especificações, regras e governança** — **não** código de app.
> O código vive em `services/` (repos git **separados**, gitignorados aqui). Todo agente de IA e
> todo humano DEVE ler e seguir esta constituição antes de qualquer ação.
>
> **1º produto: Doctor-Hub** (planejamento de capacidade médica) — services `doctor-hub-api`
> (.NET 10) e `doctor-hub-web` (React PWA). A plataforma nasce para servir produtos da empresa
> (Teleconsulta, Telediagnóstico, Dados…).

## 🏗️ Estrutura (spec-hub + services)

```
ptm-platform/
├── CLAUDE.md · README.md · Makefile         ← governança + entry point
├── docs/        ← discovery, decisions-log, design, glossary, architecture, research, security
├── specs/       ← specs por subdomínio (SDD) — caminho para PRDs
├── infrastructure/   ← docker-compose + envs
├── .claude/rules/    ← regras globais (SDD, security)
└── services/    (gitignored — cada um é repo git próprio)
    ├── doctor-hub-api/   (.NET 10 · EF Core+Dapper · Postgres)
    └── doctor-hub-web/   (React · Vite · Tailwind · PWA)
```

Cada service tem seu próprio `CLAUDE.md` (recorte da stack) apontando de volta para esta constituição.

---

## 🧭 Diretriz Suprema (Prime Directive)

**NÃO INFERIR REGRA DE NEGÓCIO. NA DÚVIDA, PERGUNTAR.**

1. Nenhuma regra de negócio é inventada, deduzida ou "preenchida por bom senso".
   Se não está escrito em `docs/discovery/` ou em uma spec aprovada, **não existe ainda** — pergunte.
2. Toda suposição vira uma **pergunta aberta** em `docs/discovery/open-questions.md`,
   não uma decisão silenciosa no código.
3. Toda decisão de negócio confirmada pelo humano vira um **registro** (ver "Como registrar" abaixo).
4. Em saúde pública lidamos com **dado sensível (LGPD)** e **dinheiro público** — o custo de
   uma regra errada é alto. Prefira perguntar duas vezes a assumir uma vez.

Se um agente perceber que está prestes a "achar" algo sobre o negócio: **pare e pergunte.**

---

## 🎯 O que é este projeto

Sistema de **planejamento de capacidade médica** (oferta × demanda) para health centers (HCs)
de governos. Fica **a montante** do produto de Teleconsulta existente
(`/home/alessandro/ptm/teleconsulta`) e **alimenta** a Teleconsulta com agendamentos prontos —
não a substitui.

Pipeline: **Oferta (escala dos médicos) → Demanda (solicitação dos governos) →
Alocação (disponibilização: simular/reservar/emitir) → Remanejamento → Agendamento → Teleconsulta.**

Detalhe verificado do domínio: `docs/discovery/01-domain-overview.md`.

---

## 🔬 Método de trabalho

- **Double Diamond / Design Thinking**: entender o PROBLEMA antes de pensar em solução.
- **SDD (Spec-Driven Development)**: nada é codificado sem uma spec aprovada.
- **TDD (Test-Driven Development)**: nada é codificado sem teste antes.

### Gate de fase (atualizado 2026-06-16)
A descoberta essencial está fechada e o Alessandro optou por **CONSTRUIR um protótipo funcional**
(D-030) — então **já estamos na Fase 6 (Construir)**. O gate "não escrever código" foi **superado por
D-030**. O que **continua valendo sempre**: a Diretriz Suprema (não inferir regra de negócio), **SDD+TDD**
(spec/teste antes), lotes pequenos e os princípios de risco abaixo. O produto foi reposicionado para
**"Doctor-Hub" — gestão de médicos** (D-055), com a **1ª entrega = Fase 1 do roadmap da diretoria: escala
médica + cadastro-dono do médico** (D-052), rodando sobre **dados reais de produção** (médicos via sync RO).

| Fase | Foco | Saída | Status |
|------|------|-------|--------|
| 1. Descobrir & Definir | Entender o problema | Domínio, papéis, perguntas, critérios | 🟢 Fechada |
| 2. Pesquisar | Frameworks AI-coding, SDD, segurança | Decisão de método/ferramental | 🟢 Feita (`docs/research/`) |
| 3. Arquitetura de contexto | Agents, skills, MCP, RAG, docs | Pasta pronta pra IA | 🟢 Fundação feita |
| 4. Estimar & Contratar | Escopo congelado, horas, custo, gates | Proposta aprovada | 🔵 Rascunho em `docs/product/` |
| 5. Desenhar (Figma) | Telas | Protótipo | ⚪ Pulada — optou-se por protótipo funcional (D-030) |
| 6. Construir | Front, back, banco | Sistema | 🟢 **EM ANDAMENTO** — build real em `services/doctor-hub-api` (.NET 10) + `services/doctor-hub-web` (React PWA); walking skeleton verde (D-109/D-110) |

---

## ⚠️ Princípios de risco (do relatório de pesquisa — `docs/research/`)

Para 1 dev + IA em sistema de saúde, estes não são opcionais:

1. **Lacuna de superconfiança (risco nº 1).** Estudos (Stanford 2023, METR 2025) mostram que você
   vai *sentir-se* mais rápido e seguro do que está. **A spec e a suíte de testes são a ÚNICA verdade
   de campo** — não a sensação, não "parece certo".
2. **Segurança inegociável (healthcare).** IA gera código inseguro ~45% das vezes, dobra vazamento de
   segredo e sugere ~20% de dependências inexistentes. Baseline: scanning de segredo em camadas,
   **zero segredo em `.mcp.json`/settings**, verificar todo pacote sugerido, least-privilege.
   Detalhe em `docs/security/security-baseline.md` (a criar).
3. **Núcleo crítico à mão.** As invariantes médicas (alocação, capacidade, elegibilidade, fairness)
   são escritas/revisadas por humano e cercadas de testes — não delegadas cegamente à IA.
4. **Lotes pequenos.** A IA amplifica suas práticas (DORA 2025): mudanças pequenas, testadas, frequentes.

Hipótese atual, **nomes provisórios** dados pelo Alessandro: Admin, Demandas, Solicitante,
Doutor, Paciente, Gestor. Detalhe e perguntas: `docs/discovery/02-roles.md`.

---

## 📂 Como trabalhar nesta pasta

- **Onde LER o que já sabemos:** `docs/discovery/`.
- **Onde ESCREVER dúvidas:** adicione em `docs/discovery/open-questions.md` (nunca decida sozinho).
- **Ubiquitous Language (glossário):** `docs/discovery/glossary.md` — use exatamente esses termos.
- **Como registrar uma decisão de negócio confirmada:** mova a pergunta de `open-questions.md`
  para o doc de domínio correspondente, com a marca `✅ Confirmado por Alessandro em <data>`.

### Integrações disponíveis (verificadas 2026-06-13)
- **ClickUp**: MCP funciona (leitura+escrita) no workspace `9013772753`.
  ⚠️ Conteúdo VISUAL de whiteboard não sai por MCP — precisa do browser (Claude-in-Chrome).
- **Figma, Slack, Google Drive, Gmail/Calendar**: MCP disponível, ainda não exercitado.
- **Browser (Claude-in-Chrome)**: abre em janela separada com sessão própria (login não é
  herdado da janela principal do usuário).

---

## ⛔ O que continua valendo (não relaxar nunca)
- **Não inferir regra de negócio.** Dúvida → `docs/discovery/03-open-questions.md` + `// PROVISÓRIO` no código.
- **SDD+TDD:** spec/teste antes; cada invariante médica/financeira cercada de teste (`services/doctor-hub-api` xUnit, `services/doctor-hub-web` Vitest).
- **Segurança/LGPD:** zero segredo no código; least-privilege/RBAC. **Sync com a TC = via banco (D-069):**
  PULL é RO; **PUSH (escrita) só via credencial dedicada + allowlist tabela:colunas + dry-run + `--apply` + log**,
  nunca DELETE/DROP/TRUNCATE, UPDATE sempre com WHERE por `external_id`, **mapeamento confirmado pelo humano**.
- Não tratar nenhum nome de papel/regra/campo como definitivo sem `✅ Confirmado` (decisions-log).
- **Stack decidido** (D-109, atualiza D-049): **.NET 10 + EF Core 10 + Dapper + Postgres** (`services/doctor-hub-api`); **React + Vite + TS + Tailwind + PWA mobile-first** (`services/doctor-hub-web`); infra **GCP** (Cloud Run + Cloud SQL + Secret Manager — a confirmar c/ infra da Portal). Estrutura **spec-hub + services** = **D-110**. Reabrir só por decisão registrada.
- **🧩 COERÊNCIA DO PROTÓTIPO (regra dura, 2026-06-20).** Todo dado de demo vem da **fixture canônica** (`docs/product/22-demo-fixtures.md`) — **nunca digitar dados à mão por tela**. Variantes/filtros são **subconjuntos derivados** (ex.: Com escala + Sem escala = Todos, por construção). **Antes de entregar QUALQUER conjunto de telas, rodar a REVISÃO DE COERÊNCIA:** (a) invariantes (união dos filtros = total; mesma entidade = mesmos atributos em todas as telas; todo link leva a um destino coerente; o fluxo continua de uma tela à seguinte); (b) **agente revisor adversarial** que navega como usuário cético e reporta furos; (c) **LINTER DE NAVEGAÇÃO** (`docs/product/23-navegacao-contrato.md`, D-106) — roda sobre o grafo do Figma e exige **isolamento de persona** (troca de persona só pelo avatar→Seletor; nenhum botão cruza Demandas↔Gestor Geral↔Gestor Regional), **alcançabilidade** (toda tela a partir do Login), **0 clicks mortos**, **0 órfãs**; (d) **CICLO DE VIDA DE TELA** (`docs/product/24-registro-telas.md`, D-108) — **1 tela canônica por intenção**; ao superar uma tela, **APAGAR a antiga e REPONTAR todas as referências** (nunca "v2" convivendo com "v1"); rodar os 2 detectores (inventário de duplicatas/PROVISÓRIO/órfãs + consistência de clique: mesmo rótulo → destinos diferentes). **Não dizer "pronto" sem isso.** O usuário não deve precisar caçar furo de coerência (nem de dados, nem de navegação, nem de tela duplicada/desatualizada).

## 📌 Onde está o estado atual
- Decisões: `docs/decisions/decisions-log.md` (D-001..D-110). Início do build real: **D-109**; estrutura ptm-platform: **D-110**.
- Protótipo Figma (homologação visual, ainda referência de produto): fileKey `snTNGRUJO2GwoKpXTHCBjf`.
- Perguntas abertas: `docs/discovery/03-open-questions.md`.

_Última atualização: 2026-06-23 (ptm-platform criado; walking skeleton api+web verde; Fase 6 — build real)._
