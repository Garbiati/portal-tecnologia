---
title: "Desenvolvimento AI-Native com SDD + TDD para Saúde Digital"
subtitle: "Relatório de pesquisa para um Staff Engineer construindo sozinho + Claude Code"
status: research
date: 2026-06-14
author: pesquisa assistida (deep-research)
tags: [sdd, tdd, claude-code, living-documentation, bdd, saude-digital, teleconsulta]
contexto: "Sistema de alocação de capacidade médica que alimenta produto de Teleconsulta. 1 dev + Claude Code, spec como fonte da verdade."
---

# Desenvolvimento AI-Native com SDD + TDD para um Sistema de Saúde Digital

> **Escopo.** Como um Staff engineer pode construir, **sozinho + Claude Code**, um sistema de alocação de capacidade médica (que alimenta Teleconsulta) usando **Spec-Driven Development (SDD) + TDD**, com a **especificação como fonte da verdade**, de forma segura, escalável, arquiteturalmente correta e mantível.
>
> **Honestidade sobre datas e incerteza.** Pesquisa consolidada em **2026-06-14**. Preços e limites de uso mudam com frequência — todo número está marcado com fonte e data, ou explicitamente como **A VERIFICAR**. A área de SDD é jovem (a maior parte das ferramentas surgiu em 2025); várias afirmações vêm de fontes primárias dos próprios fornecedores (first-party) e estão sinalizadas como tal.

---

## 1. Sumário Executivo — 10 bullets acionáveis

1. **Adote SDD como disciplina, não como ferramenta.** Empreste os conceitos (constitution, EARS, requirements→design→tasks) sem necessariamente instalar Spec-Kit/Kiro inteiros. A análise mais neutra (Birgitta Böckeler, martinfowler.com, 2025-10-15) alerta: para problemas pequenos as ferramentas viram "marreta para quebrar uma noz", e specs verbosas são tediosas de revisar ([fonte](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)).
2. **Escreva critérios de aceitação em notação EARS** (`QUANDO <gatilho>, O SISTEMA DEVE <resposta>`) — é livre, agnóstica de ferramenta, e transforma requisito vago em critério testável, ideal para guiar a IA e virar teste ([EARS](https://alistairmavin.com/ears/), [Kiro docs](https://kiro.dev/docs/specs/)).
3. **Use o par "spec como fonte da verdade + testes como guardrails".** Cada capacidade da spec aponta para um teste; regenere o código contra esse contrato. É o que Tessl formaliza com anotações `@generate`/`@test`/`@use` ([Tessl](https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry/)) e o que a evidência de IA recomenda contra "alucinação de regra de negócio".
4. **Não adote Cucumber/Gherkin pela cerimônia.** O valor do Gherkin é ser *lido por não-desenvolvedores* (Fowler) e ter comportamento estável. Sozinho, você é o único leitor — prefira testes com nomes claros em arrange/act/assert e reserve Gherkin só onde a IA é o "segundo leitor" ([Fowler](https://martinfowler.com/bliki/BusinessReadableDSL.html), [Ranorex](https://www.ranorex.com/blog/dont-need-cucmber-bdd/)).
5. **Configure a arquitetura de contexto do Claude Code em camadas:** `CLAUDE.md` curto (<200 linhas) + Skills sob demanda + Subagents para isolar contexto + Hooks determinísticos para *forçar* TDD/spec-first ([docs oficiais](https://code.claude.com/docs/en/memory)).
6. **Use hooks `PreToolUse` para enforcement real.** Um script que sai com **exit 2** (ou retorna JSON `permissionDecision: "deny"`) bloqueia a edição de código-fonte sem teste/spec correspondente — isso é determinístico, ao contrário do CLAUDE.md que é só "conselho" ([Hooks](https://code.claude.com/docs/en/hooks)).
7. **Para o portal "estado vivo do sistema": Obsidian + Dataview** (dashboard local que consulta o frontmatter das specs) **ou MkDocs Material** (site publicável com busca embutida e Mermaid em uma linha). Evite Backstage para 1 dev (exige Postgres, Docker, ~6 GB RAM e "muito React") ([MkDocs](https://squidfunk.github.io/mkdocs-material/), [Dataview](https://blacksmithgu.github.io/obsidian-dataview/), [Backstage](https://backstage.io/docs/getting-started/)).
8. **Trate a lacuna de superconfiança como risco nº 1.** Estudos (Stanford CCS 2023; METR 2025) mostram que você vai *sentir-se* mais rápido e mais seguro enquanto mede o contrário — sem revisor humano, **spec + suíte de testes são sua única verdade de campo** ([METR](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/), [Stanford](https://arxiv.org/abs/2211.03622)).
9. **Blinde segredos e dependências.** IA ~dobra a taxa de vazamento de segredo (GitGuardian 2026) e ~20% do código gerado referencia pacotes inexistentes ("slopsquatting"). Use Gitleaks no pre-commit + TruffleHog/push-protection no CI, **sem segredos em `.mcp.json`**, e verifique todo pacote sugerido ([GitGuardian](https://www.helpnetsecurity.com/2026/04/14/gitguardian-ai-agents-credentials-leak/), [USENIX 2025](https://arxiv.org/abs/2406.10279)).
10. **Atenção à mudança de billing de 15/06/2026 do Agent SDK.** A partir dessa data, uso de Agent SDK / `claude -p` / GitHub Actions sai dos limites da assinatura e passa a consumir **créditos mensais separados** cobrados a preço de API; uso interativo de Claude Code no terminal/IDE **continua** na assinatura ([suporte oficial Anthropic](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan)).

---

## 2. Spec-Driven Development — estado da arte (2025/2026)

**O que SDD significa.** Böckeler (ThoughtWorks/Fowler) define três níveis de ambição ([fonte, 2025-10-15](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)):
- **Spec-first** — a spec guia o início e é descartada depois.
- **Spec-anchored** — a spec persiste pela evolução/manutenção da feature.
- **Spec-as-source** — a spec é o artefato primário; humanos nunca editam o código gerado (visão da Tessl).

Padrões comuns às três ferramentas (Böckeler): specs em Markdown como artefato primário; documentos de contexto "memory bank" (constitution, steering files); workflows estruturados com etapas de revisão; e uso de janelas de contexto grandes. **Cautelas dela:** sobredimensionamento para problemas pequenos, fardo de revisão de Markdown verboso, "falso controle" (agentes ignoram/superinterpretam instruções mesmo com spec detalhada), e o paralelo histórico com o fracasso do Model-Driven Development.

### 2.1 GitHub Spec-Kit

**O que é.** Toolkit CLI open-source (`specify`) que instala um workflow SDD no repo e conduz um agente por fases, em vez de prompt único. O próprio GitHub o descreve como "experimento" com lacunas reconhecidas. Repo: [github.com/github/spec-kit](https://github.com/github/spec-kit); docs: [github.github.com/spec-kit](https://github.github.com/spec-kit/quickstart.html); post oficial GitHub Blog (2025-09-02, Den Delimarsky): [link](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/).

**Instalação:** `uvx --from git+https://github.com/github/spec-kit.git specify init <PROJ>` (também via pipx/`uv tool install`).

**Slash commands** (builds novas usam namespace `/speckit.*`), em ordem estrita de dependência ([repo](https://github.com/github/spec-kit)):
- `/speckit.constitution` — princípios não-negociáveis do projeto
- `/speckit.specify` — requisitos + user stories (o "quê"/"porquê", sem escolhas técnicas)
- `/speckit.plan` — abordagem técnica, stack, arquitetura (o "como")
- `/speckit.tasks` — quebra do plano em tarefas ordenadas
- `/speckit.implement` — executa as tarefas
- auxiliares: `/speckit.clarify` (perguntas para remover ambiguidade), `/speckit.analyze` (consistência entre artefatos), `/speckit.checklist`

**Estrutura `.specify/`:** `memory/constitution.md`, `scripts/bash/`, `templates/` (plan/spec/tasks). A "**constitution**" é um `memory/constitution.md` permanente com princípios não-negociáveis (testing, arquitetura, stack), referenciado por todos os comandos seguintes ([MS dev blog, 2025-09-15](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)).

**Integrações:** agnóstico — docs citam **30+ agentes** (Claude Code, Copilot, Gemini CLI, Cursor, Codex, etc.) ([repo](https://github.com/github/spec-kit)).

**Prós (1 dev):** gratuito, open-source, sem lock-in; torna a intenção arquitetural explícita e versionável; permite gerar múltiplas implementações de uma spec.

**Contras (1 dev).** O sinal mais honesto vem da discussão **#1784 do próprio repo** ("SpecKit creates the illusion of work"): documentação excessiva que afoga o LLM em contexto, ~**4:1 de overhead de tokens** vs. prompt ad-hoc, volume sobre fidelidade em sistemas brownfield, horas corrigindo specs auto-geradas ([discussão #1784](https://github.com/github/spec-kit/discussions/1784); [comparativo Somnio](https://somniosoftware.com/blog/spec-driven-development-in-practice-github-spec-kit-openspec-and-gsd-compared)). Consenso: melhor para greenfield/protótipo; para features pequenas, o **Plan Mode** nativo do Claude Code é mais rápido e previsível.

**O que emprestar sem adotar:** um `constitution.md` curto no repo; a separação mental **specify → plan → tasks → implement**; os passos `/clarify` e `/analyze` como padrões de prompt; templates Markdown versionados.

### 2.2 Amazon Kiro

**O que é.** IDE agêntico da AWS (derivado de VS Code) centrado em SDD. **Preview em jul/2025**, crise de cota/waitlist em out/2025, **GA em nov/2025** (>250k devs citados) ([GA blog](https://kiro.dev/blog/general-availability/), [InfoWorld](https://www.infoworld.com/article/4026642/aws-imposes-caps-on-kiro-usage-introduces-waitlist-for-new-users/)). Modelo padrão: Anthropic Claude Sonnet 4 (a versão exata varia entre fontes — tratar como aproximada).

**Workflow de spec — três artefatos** em `.kiro/specs/<feature>/` ([docs](https://kiro.dev/docs/specs/)):
1. `requirements.md` — user stories + critérios de aceitação em **EARS**
2. `design.md` — arquitetura, diagramas de sequência, fluxo de dados, estratégia de teste
3. `tasks.md` — tarefas discretas e rastreáveis

Fluxo em três fases com **gates de aprovação** (Requirements → Design → Tasks), variantes Requirements-First / Design-First, e um **Quick Plan** sem gates. "Run all Tasks" agrupa tarefas independentes em "waves".

**EARS (Easy Approach to Requirements Syntax)** — criado por Alistair Mavin et al. na Rolls-Royce ([ref](https://alistairmavin.com/ears/)). Padrões:
- Event-driven: `WHEN <gatilho>, THE SYSTEM SHALL <resposta>`
- Ubiquitous: `THE <system> SHALL <comportamento>`
- Outros: `IF/THEN`, `WHILE`, `WHERE`

**Steering files** (`.kiro/steering/`): `product.md`, `tech.md`, `structure.md`, com modos de inclusão Always/Conditional/Manual/Auto ([docs](https://kiro.dev/docs/steering/)). **Agent hooks** disparam prompt/shell em eventos do IDE (save, create, before/after spec tasks) ([docs](https://kiro.dev/docs/hooks/)). GA adicionou property-based testing para checar se o código bate com a spec, checkpoints e um **Kiro CLI** ([GA blog](https://kiro.dev/blog/general-availability/)).

**Preços — ⚠️ A VERIFICAR em [kiro.dev/pricing](https://kiro.dev/pricing/)** (fontes secundárias + um blog oficial): tier Free perpétuo (~50 créditos/mês); Pro $20, Pro+ $40, Pro Max $100, Power $200/mês; overage ~$0,04/crédito. Notavelmente, **requisições em spec-mode custam ~5× o vibe-mode** (~$0,20 vs $0,04) — fator relevante de custo para 1 dev. *Trate todos esses números como não confirmados.*

**Prós (1 dev):** a experiência SDD mais polida e integrada; EARS força requisitos testáveis; steering files dão contexto durável com baixo esforço.

**Contras (1 dev):** pricing por crédito + multiplicador 5× de spec-mode podem encarecer uso pesado (verificar); turbulência de cota no fim de 2025; é outro IDE a adotar (não é drop-in no seu editor); algum lock-in AWS.

**O que emprestar:** **EARS** (livre); o trio **product/tech/structure** mapeia direto em `CLAUDE.md`; a tríade requirements→design→tasks; hooks de evento replicáveis via git hooks.

### 2.3 Tessl

**O que é.** Empresa "AI-native" de **Guy Podjarny** (fundador da Snyk). Tese: virar de code-centric para **spec-centric** — a spec é a fonte da verdade e o código é um artefato de build regenerável ([site](https://tessl.io/); [launch blog 2025-09-23](https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry/)).

**Dois produtos:** (1) **Tessl Framework** — framework SDD, em **closed beta**; specs persistem como documentação + memória de longo prazo, pareadas com testes contra regressão. (2) **Tessl Registry** — **open beta, grátis**; **10.000+ specs** prontas descrevendo como usar libs open-source para evitar alucinação de API.

**Estrutura da spec:** descrição + lista de capacidades (com testes linkados) + definição de API, dirigida por anotações: `[@generate](...)`, `@describe`, `[@test](...)`, `[@use](...)` ([blog](https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry/)).

**Status 2026:** Framework closed beta, Registry open beta, sem GA. Financiamento reportado de forma **inconsistente** (~$125M total; um sumário citou valuation de $750M) — **tratar valuation e datas como não verificados** ([Series A](https://tessl.io/blog/announcing-our-series-a-for-ai-native-software-development/), [Calcalist](https://www.calcalistech.com/ctechnews/article/i7ucn8teu)).

**Prós (1 dev):** a visão mais ambiciosa; Registry usável hoje para reduzir alucinação de API; o modelo de anotações é uma forma elegante de amarrar spec↔código↔teste.

**Contras (1 dev):** Framework é gated (você provavelmente não consegue adotar ainda); menos maduro e menos revisado independentemente; "código descartável" é não comprovado em escala e arriscado para healthcare que você precisa certificar.

**O que emprestar:** o par **spec-as-source + tests-as-guardrails**; **anotações inline** ligando seções da spec a arquivos de código/teste (convenção Markdown em qualquer repo); separar **component specs** de **usage specs**; usar o **Registry grátis** já como redutor de alucinação.

### 2.4 Ranking de maturidade (2026)

Kiro (GA, mais polido, pago) > Spec-Kit (grátis, aberto, agnóstico, "experimento") > Tessl (visão mais ambiciosa, ainda beta-gated, menos verificável).

---

## 3. Living Documentation / Specification by Example / BDD

### 3.1 Gojko Adzic — Specification by Example & Living Documentation

Livro de 2011 (Manning, Jolt Award 2012): exemplos realistas viram **especificações executáveis**, que viram **documentação viva** — um único artefato que é spec, teste de aceitação e doc sempre-atual ([gojko.net](https://gojko.net/books/specification-by-example/)). Sete process patterns, incluindo "automatizar validação **sem alterar** a especificação" e "evoluir um sistema de documentação viva" ([Manning](https://www.manning.com/books/specification-by-example), [InfoQ](https://www.infoq.com/articles/specification-by-example-book)). **Caveat honesto:** o método pressupõe **colaboração entre devs e usuários** — premissa que muda quando você é solo (ver 3.3).

### 3.2 BDD / Gherkin / Cucumber — mecânica e história

- **Dan North** criou o BDD no início dos anos 2000 na ThoughtWorks; artigo canônico "Introducing BDD" (2006) ([dannorth.net](https://dannorth.net/introducing-bdd/)). O template **Given/When/Then** foi co-desenvolvido com Chris Matts (~2004), inspirado em DDD e nas user stories da Connextra ([Cucumber history](https://cucumber.io/docs/bdd/history/)).
- **Cucumber** (Aslak Hellesøy) tem como alvo o time inteiro, incluindo não-técnicos; **Gherkin** é sua DSL Given/When/Then. Os arquivos `.feature` viram teste via **step definitions** (glue code). Ferramentas: Cucumber (Ruby/JS/Java), SpecFlow/**Reqnroll** (.NET), **Behave** e **pytest-bdd** (Python).
- North enquadra: "BDD é sobre design, não teste" e "o poder do BDD é o foco na colaboração entre papéis" ([Avanscoperta, 2018](https://blog.avanscoperta.it/2018/03/07/second-generation-agile-methodology-dan-norths-bdd-tales/)).

### 3.3 O debate — quando vale vs. quando é overhead

Esta é a seção mais importante para 1 dev, e as fontes são notavelmente consistentes:

- **Martin Fowler — "Business Readable DSL"** ([2008-12-15](https://martinfowler.com/bliki/BusinessReadableDSL.html)): o sweet spot é tornar DSLs **legíveis** por negócio, não escrevíveis. **O valor é o canal de comunicação com stakeholders — é colaborativo, não técnico.**
- **"You Don't Need Cucumber for BDD"** ([Ranorex, 2025-11-25](https://www.ranorex.com/blog/dont-need-cucmber-bdd/)): engenheiros acabam mantendo regex/glue complexos (o "Gherkin tax"); stakeholders não engajam com os arquivos Gherkin; o autor já migrou suítes Cucumber **de volta para código simples** várias vezes. BDD é metodologia, não ferramenta — nomes claros + arrange/act/assert dão a mesma clareza com menos complexidade.
- **"Is the juice worth the squeeze?"** ([QualityWorks](https://qualityworkscg.com/cucumber-for-bdd-is-the-juice-worth-the-squeeze/)): vale em projeto novo, com lacuna real de colaboração cross-funcional; é overhead quando usado só como wrapper de automação, ou quando **"times já comunicam requisitos efetivamente (comum em orgs pequenas com papéis sobrepostos)"**.
- Split recorrente: "**Gherkin (formato legível) é bom; Cucumber (a maquinaria de glue) é o custo**" ([testzeus](https://testzeus.com/blog/why-gherkin-is-good-and-cucumber-is-not), [agileway](https://agileway.substack.com/p/a-practical-advice-on-rejecting-gherkin)). Gherkin "churna" mal enquanto regras/fluxos ainda são instáveis.

**Regra de decisão:** Gherkin/Cucumber se paga só quando (a) um não-dev realmente lê os cenários e (b) o comportamento é estável. Para 1 dev, (a) costuma ser falso — **a não ser que você trate o agente de IA como esse "segundo leitor"**, que é o argumento genuinamente novo de 2025-26.

### 3.4 Conexão com desenvolvimento assistido por IA (2025/2026)

> Caveat: discurso emergente e majoritariamente vendor-driven. A evidência mais forte é um estudo industrial no arXiv.

- **Estudo industrial arXiv** ([2504.07244, abr/2025](https://arxiv.org/abs/2504.07244)): pipeline GPT-4-Turbo gera cenários Gherkin a partir de user stories (úteis 95% das vezes) e scripts de teste (úteis 92%; **60% usáveis as-is**). Conclusão: LLMs ajudam o processo de teste de aceitação **com tooling e supervisão apropriados**.
- **Mecanismo emergente — specs executáveis como guardrails** da IA: [Augment Code "Living Specs"](https://www.augmentcode.com/guides/living-specs-for-ai-agent-development) (2026) propõe specs como "executable blueprints" com limites allowed/approval/prohibited e versionamento junto ao código para evitar "spec drift". [Wolff (2026)](https://www.blog-des-telecoms.com/en/blog/specification-executable-gherkin-proprietes/): o gargalo da IA é **precisão da especificação, não geração de código** — modelos completam padrões bem, mas inferem intenção mal; sem ela, "preenchem as lacunas com padrões aprendidos em outro lugar". Propõe escada de formalização por custo do bug (prosa → Gherkin → propriedades/contratos).
- **ThoughtWorks Tech Radar Vol. 33 (2025):** SDD em "Assess", com antipattern explícito: "viés a especificação pesada antecipada e releases big-bang".

### 3.5 Bottom line para o seu caso (healthcare/teleconsulta, solo)

- **Onde paga (fazer):** capturar as **regras do domínio como exemplos concretos / testes de aceitação executáveis** — a *substância* da Specification by Example. Em domínio regulado (alocação de capacidade, elegibilidade, fairness), os exemplos *são* o requisito e a trilha de auditoria, e dobram como **guardrails de IA**. Versione as specs junto ao código.
- **Onde é overhead (pular):** a maquinaria completa Cucumber/Gherkin adotada por si só; especificação pesada antecipada de tudo enquanto o produto ainda é instável.
- Reserve a maior formalidade para a lógica de maior custo (limites de capacidade, fairness, edge cases que afetam acesso do paciente).

---

## 4. Claude Code como motor de desenvolvimento

> Fontes oficiais: `code.claude.com/docs`. Padrões de comunidade sinalizados como tal. A distinção crítica é **conselho (advisory) vs. determinístico**: CLAUDE.md/Skills são lidos e *podem* ser ignorados; Hooks/Permissions são *executados* em pontos fixos do ciclo de vida.

### 4.1 CLAUDE.md — memória persistente

Hierarquia (carrega por precedência) ([memory docs](https://code.claude.com/docs/en/memory)):
- Managed/enterprise: `/etc/claude-code/CLAUDE.md`
- User: `~/.claude/CLAUDE.md`
- Project: `./CLAUDE.md` ou `./.claude/CLAUDE.md` (versionado em git)
- Local: `./CLAUDE.local.md` (gitignored)

Carregado no início de cada sessão (~2–5K tokens). **Mantenha <200 linhas**: comandos não-óbvios, regras de estilo que diferem do default, instruções de teste, decisões arquiteturais, gotchas. Suporta **imports `@`** (`@docs/architecture.md`, até 4 níveis).

### 4.2 Subagents

`./.claude/agents/<nome>.md` ([sub-agents docs](https://code.claude.com/docs/en/sub-agents)). Preservam o contexto principal (cada um roda em janela isolada), permitem isolar escopo de ferramentas (ex.: um `security-reviewer` só com Read/Grep, sem Edit) e rotear tarefas simples para modelos mais baratos (Haiku). Frontmatter define `name`, `description`, `tools`, `model`.

### 4.3 Skills

`./.claude/skills/<nome>/SKILL.md` ([skills docs](https://code.claude.com/docs/en/skills)). **Progressive disclosure:** em vez de inflar o CLAUDE.md, ponha uma referência curta nele e o detalhe na skill, carregada só quando relevante. Skills diferem de subagents (rodam no contexto principal, não isolado) e de slash commands (podem auto-disparar por descrição).

### 4.4 Slash commands

`./.claude/commands/*.md` — comandos customizados com argumentos. Ex.: `/spec-new`, `/tdd-cycle`.

### 4.5 Hooks — enforcement determinístico (o coração do TDD/spec-first)

Configurados em `settings.json` ([hooks-guide](https://code.claude.com/docs/en/hooks-guide), [hooks reference](https://code.claude.com/docs/en/hooks)). **Por que hooks e não regras no CLAUDE.md:** CLAUDE.md é conselho; hooks são determinísticos e disparam sempre.

Eventos relevantes (confirmados na reference oficial):
- `PreToolUse` — **antes** de um tool call; **pode bloquear**
- `PostToolUse` / `PostToolUseFailure` — após sucesso/falha do tool
- `Stop` / `SubagentStop` — quando Claude/subagente termina
- `UserPromptSubmit`, `SessionStart`, `ConfigChange`, etc.

**Mecânica de bloqueio (oficial, verificada):**
- **Exit 2** = bloqueia a ação; o stderr vira feedback para o Claude se ajustar. (Ex. oficial: bloquear edição de `.env`/`package-lock.json` checando o path e saindo com exit 2.)
- Alternativa estruturada: **exit 0 + JSON** no stdout com `hookSpecificOutput.permissionDecision: "deny"` e `permissionDecisionReason` — cancela o tool call e devolve a razão ao Claude. (Não misture: com exit 2 o JSON é ignorado.)
- Em múltiplos hooks no mesmo evento, **a decisão mais restritiva vence** (ordem deny > defer > ask > allow). Regras `deny` de managed settings sempre têm precedência sobre `allow` de hook.

**Padrões de enforcement para seu projeto:**
- **TDD gate (`PreToolUse`, matcher `Write|Edit`):** se o alvo é `src/**`, um script verifica se existe (e/ou falha) um teste correspondente; senão **exit 2** com mensagem "escreva o teste primeiro". (Padrão de comunidade: [TDD enforcement com hooks](https://thepromptshelf.dev/blog/claude-code-tdd-enforcement/).)
- **Spec-first gate:** bloquear criação de código novo sem uma spec `.md` correspondente.
- **Quality `PostToolUse`:** rodar formatter/linter/`gitleaks` após cada edição ([padrões CI/CD](https://www.pixelmojo.io/blogs/claude-code-hooks-production-quality-ci-cd-patterns)).
- **`Stop` gate:** ao finalizar, rodar a suíte e bloquear se vermelha.

### 4.6 MCP servers

`.mcp.json` (projeto) ou config de usuário ([mcp docs](https://code.claude.com/docs/en/mcp)). Conectam issue trackers, DBs, monitoring, code-search. **Atenção de segurança:** GitGuardian encontrou 24.008 segredos únicos em arquivos de config MCP — **nunca** ponha credenciais em `.mcp.json`/settings; use env vars/secrets manager (ver §6 do tema 5).

### 4.7 settings.json — precedência

Managed (`/etc/claude-code/settings.json`, não sobrescrevível) > CLI flags > Local (`.claude/settings.local.json`, gitignored) > Project (`.claude/settings.json`) > User (`~/.claude/settings.json`) ([settings docs](https://code.claude.com/docs/en/settings)). Inclui `permissions` (allow/ask/deny), `env`, `model`, `hooks`.

### 4.8 "Quanto mais a IA usa, mais aprende o negócio"

Loop sugerido:
1. **Sessão 1 (aprendizado):** Claude faz perguntas, escreve a spec, implementa+testa; você corrige 2–3 vezes.
2. **Entre sessões:** extraia padrões recorrentes → adicione ao `CLAUDE.md` ou crie uma skill; se Claude repete o mesmo erro → adicione um hook `PreToolUse` que o bloqueia; post-mortems viram regras/skills.
3. **Sessão 2+:** CLAUDE.md + skills + hooks já dão o contexto; o repo fica "mais inteligente" a cada ciclo.

> Nota: a pesquisa mencionou um recurso "Auto Memory" (`~/.claude/projects/.../MEMORY.md`) como mecanismo de auto-aprendizado. **A VERIFICAR** na doc oficial de memória antes de depender dele — o mecanismo central confirmado é a curadoria manual de CLAUDE.md/skills/hooks descrita acima.

### 4.9 Estrutura de repo canônica (ponto de partida)

```
projeto/
├── CLAUDE.md                       # orientação raiz (<200 linhas)
├── constitution.md                 # princípios não-negociáveis (emprestado do Spec-Kit)
├── .claude/
│   ├── settings.json               # permissions, hooks, model
│   ├── skills/<skill>/SKILL.md
│   ├── agents/security-reviewer.md
│   └── hooks/{require-test.sh, run-tests.sh, gitleaks.sh}
├── .mcp.json                       # MCP (sem segredos!)
├── docs/
│   ├── specs/<feature>/{requirements.md, design.md, tasks.md}  # EARS + design + tasks
│   └── research/
└── src/ ...  tests/ ...
```

---

## 5. Portal visual de documentação ("estado vivo do sistema")

Objetivo: transformar uma pasta de specs `.md` com frontmatter num portal navegável que mostra o estado vivo do sistema.

| Opção | Frontmatter | Busca | Mermaid | Esforço solo | Hospedagem |
|---|---|---|---|---|---|
| **MkDocs + Material** | YAML metadata | **Embutida (client-side)** | **1 linha** (superfences) | **Baixo** (1 `mkdocs.yml`) | GitHub Pages / RTD ([fonte](https://squidfunk.github.io/mkdocs-material/reference/diagrams/)) |
| **Astro Starlight** | Type-safe (schema) | **Pagefind zero-config** | add-on `astro-mermaid` | Baixo-médio (JS/Astro) | qualquer host estático ([busca](https://starlight.astro.build/guides/site-search/)) |
| **Docusaurus** | First-class | Algolia (externo) | add-on (theme-mermaid) | Médio (config JS multi-arquivo) | host estático ([diagramas](https://docusaurus.io/docs/markdown-features/diagrams)) |
| **Backstage** | catalog-info.yaml | (plataforma) | (plataforma) | **Alto** (Postgres, Docker, ~6 GB RAM, "muito React") | servidor ([getting-started](https://backstage.io/docs/getting-started/)) |
| **Obsidian + Dataview** | YAML Properties | vault + queries | **nativo** | **Mais baixo** (abre a pasta) | **Local** (publish é pago) |

**Recomendação para 1 dev.** Há duas respostas conforme a necessidade:

- **Dashboard privado, dirigido por query → Obsidian + Dataview é o mais leve.** Zero build: aponte para a pasta, adicione frontmatter e escreva queries `TABLE`/`LIST` que leem `status`, `owner`, `last_updated` e renderizam um "estado do sistema" auto-atualizável; o graph view dá o mapa visual. Casa literalmente com "estado vivo" (re-query a cada mudança). Ressalva: é local/single-user, sem site público nativo ([Dataview](https://blacksmithgu.github.io/obsidian-dataview/)).
- **Site publicável, navegável → MkDocs + Material é o mais leve:** um `mkdocs.yml` legível, busca embutida (sem Algolia/API key), Mermaid em uma linha, nav automática, hospedagem grátis no GitHub Pages ([Material](https://squidfunk.github.io/mkdocs-material/)). Starlight é vice próximo e até mais "batteries-included" se você é confortável em JS/Astro ([Starlight](https://starlight.astro.build/)).

**Híbrido pragmático:** use **Obsidian + Dataview** como ambiente de autoria/consulta do dia a dia e aponte **MkDocs/Starlight para a mesma pasta** quando quiser publicar — os arquivos `.md` + frontmatter são compatíveis com todos, sem lock-in.

**Não recomendado para 1 dev:** Backstage (custo operacional desproporcional). A ideia do *catalog como estado do sistema* é conceitualmente a mais próxima, mas o "imposto" operacional é grande.

> Ressalvas: o status exato de busca local embutida no Docusaurus deve ser confirmado em docusaurus.io/docs/search. O Dataview é comunitário (não first-party); o Obsidian recente tem um recurso first-party "Bases" que pode ser alternativa — **a verificar**.

---

## 6. Desenvolvimento assistido por IA seguro e mantível

> Filtro: solo, healthcare, sem segundo par de olhos. Achados contestados sinalizados.

### 6.1 Riscos conhecidos

**(a) Alucinação de pacote / "slopsquatting".** Estudo USENIX Security 2025: 2,23M amostras, **19,7% continham ≥1 pacote alucinado**; open-source 21,7% vs comercial 5,2%; e as alucinações são **repetíveis** (43% reaparecem em todas as 10 execuções), o que viabiliza pré-registro malicioso ([arXiv 2406.10279](https://arxiv.org/abs/2406.10279), [Aikido](https://www.aikido.dev/blog/slopsquatting-ai-package-hallucination-attacks)). Caso real: `huggingface-cli` alucinado, registrado no PyPI, **30k+ downloads em 3 meses** ([Trend Micro](https://www.trendmicro.com/vinfo/us/security/news/cybercrime-and-digital-threats/slopsquatting-when-ai-agents-hallucinate-malicious-packages)). O análogo mais perigoso para você é a **alucinação de regra de negócio / API interna** — sem registry para pegar, só seus testes e revisão pegam.

**(b) Dívida técnica acelerada (GitClear 2025, 211M linhas 2020–2024):** duplicação de blocos ~**8× em 2024**; copy/paste de 8,3% (2021) para 12,3% (2024); **2024 foi o 1º ano em que copy/paste superou código "movido" (refatorado)**; refatoração caiu de 25% (2021) para <10% (2024); churn de 3,1% para 5,7% ([GitClear](https://www.gitclear.com/ai_assistant_code_quality_2025_research)). *Caveat: GitClear é vendor e o dado é correlacional, não causal.*

**(c) DORA 2025 (Google):** 90% usam IA, >80% relatam ganho de produtividade, mas **~30% têm pouca/nenhuma confiança no código gerado**; maior adoção correlaciona com **mais throughput E mais instabilidade** — "velocidade sem estabilidade é caos acelerado". Tempo poupado é re-gasto em verificação ("verification tax"). **IA amplifica capacidades existentes**: práticas fortes (VCS, lotes pequenos, feedback rápido, automação de teste) melhoram; fracas pioram ([DORA](https://dora.dev/insights/balancing-ai-tensions/), [PDF](https://services.google.com/fh/files/misc/2025_state_of_ai_assisted_software_development.pdf)).

**(d) METR RCT (jul/2025):** 16 devs experientes em repos maduros que conheciam ficaram **19% mais lentos** com IA, apesar de preverem +24% e ainda acreditarem +20% depois ([METR](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/), [arXiv 2507.09089](https://arxiv.org/abs/2507.09089)). *Caveat dos próprios autores: efeito específico de experts em código familiar de alto padrão — não generaliza. Mas o seu perfil (staff em sistema que você arquitetou) é justamente esse, então a **lacuna de percepção** é real.*

**(e) Vazamento de segredo (GitGuardian 2026):** 28,65M segredos novos em commits públicos em 2025 (+34% YoY); **IA ~dobra a taxa de vazamento** (~3,2% vs 1,5% baseline; commits assistidos por Claude Code ~3,2%); leaks de credenciais de IA +81% YoY; **24.008 segredos em arquivos de config MCP** ([Help Net Security](https://www.helpnetsecurity.com/2026/04/14/gitguardian-ai-agents-credentials-leak/), [Security Boulevard](https://securityboulevard.com/2026/03/news-alert-gitguardian-study-shows-ai-coding-tools-double-leak-rates-as-29m-credentials-hit-github/)).

**(f) Vulnerabilidades em código gerado:** Veracode 2025 — modelos escolheram a implementação **insegura 45% das vezes**, **sem melhora entre gerações** ([Veracode](https://www.veracode.com/resources/analyst-reports/2025-genai-code-security-report/)). Stanford CCS 2023 — devs com assistente escreveram código **menos seguro** e **mais propensos a achá-lo seguro** ([arXiv 2211.03622](https://arxiv.org/abs/2211.03622)). NYU IEEE S&P 2022 — ~40% das saídas do Copilot com vulnerabilidade explorável ([arXiv 2108.09293](https://arxiv.org/pdf/2108.09293)).

### 6.2 Mitigações

- **Testes/specs como verdade de campo (maior alavanca solo):** DORA recomenda **automação de teste robusta** acima de otimizar revisão manual, e antecipar o feedback da IA ao autor durante a escrita ([DORA](https://dora.dev/insights/balancing-ai-tensions/)). Spec escrita + suíte = o contrato que a IA deve satisfazer.
- **Lotes pequenos + escrever à mão o núcleo crítico** (invariantes médicas de alocação) para preservar entendimento (DORA).
- **Scanning de segredos em camadas:** **Gitleaks** no pre-commit (offline, rápido) + **TruffleHog** no CI (verifica se a credencial é viva) + **GitHub secret scanning + push protection** como backstop. **Sem segredos em `.mcp.json`/settings** ([Gitleaks vs TruffleHog](https://appsecsanta.com/secret-scanning-tools/gitleaks-vs-trufflehog), [TruffleHog](https://github.com/trufflesecurity/trufflehog)).
- **Anti-slopsquatting:** pinar/lockar deps, **verificar que todo pacote sugerido existe e é o pretendido** antes de instalar, allowlist/registry privado, SCA (Snyk) ([Snyk](https://snyk.io/articles/slopsquatting-mitigation-strategies/)).
- **Least-privilege do agente (Claude Code):** read-only por default; regras allow/ask/deny por tool/path/domínio/MCP; **nunca `--dangerously-skip-permissions` fora de container isolado**; logging via OpenTelemetry ([General Analysis](https://generalanalysis.com/guides/anthropic-claude-code-security-best-practices), [Checkmarx](https://checkmarx.com/learn/ai-security/claude-code-security-top-6-risks-controls-and-best-practices/)).
- **Policy-as-code & evals:** hooks/CI gates bloqueando em falha de Gitleaks/SAST/testes; evals leves nos caminhos críticos do domínio (correção da alocação) para pegar regressão automaticamente.
- **OWASP LLM Top 10 2025** (para features de LLM do próprio app de teleconsulta, se houver): Prompt Injection (LLM01, incl. indireta) é #1; trate toda saída de LLM como entrada não-confiável (LLM05) ([genai.owasp.org](https://genai.owasp.org/llm-top-10/)).

### 6.3 Bottom line de segurança

As duas descobertas que mais devem moldar o workflow: (1) **a lacuna de superconfiança é robusta** (Stanford 2023 + METR 2025) — você vai *sentir-se* rápido/seguro sendo nenhum dos dois, e sem revisor, **spec + testes são sua única verdade**; (2) **as falhas concentram-se exatamente nas suas áreas de risco** — código inseguro por default (45%), vazamento de segredo (~2×), alucinação de dependência *e* de regra, dívida crescente. Defaults concretos: spec-and-test-first com evals de alocação; Gitleaks+TruffleHog/push-protection; verificar todo pacote; Claude Code least-privilege + sandbox + sem segredos em MCP; lotes pequenos; **escrever à mão o núcleo de invariantes médicas**.

---

## 7. Custo — tokens, billing, estimativa

> ⚠️ Preços mudam. Tudo abaixo com fonte e data (recuperado 2026-06-14) ou marcado **A VERIFICAR**. Não invente números.

### 7.1 Modelos de billing do Claude Code

**(a) Assinaturas que incluem Claude Code** ([claude.com/pricing](https://claude.com/pricing), 2026-06-14): Pro **$17/mês anual ou $20/mês mensal**; Max 5x **a partir de $100/mês**; Max 20x (mesmo tier, multiplicador maior — "5x ou 20x mais uso que Pro"); Team Standard $20/$25, Team Premium $100/$125; Enterprise (seat + uso a preço de API). **Limites:** janela móvel de 5h + caps semanais, compartilhados entre Claude Code e chat. Detalhes de limites por janela vêm de **fontes terceiras / A VERIFICAR**.

**(b) API key / pay-as-you-go** via Anthropic Console: cobra **por token** a preços de modelo (§7.2); cria automaticamente um workspace "Claude Code" para tracking; admins definem spend limits ([code.claude.com/docs/en/costs](https://code.claude.com/docs/en/costs)).

**(c) Créditos de Agent SDK + mudança de 15/06/2026 — CONFIRMADO** ([suporte oficial](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan), 2026-06-14):
- **A partir de 15/06/2026**, uso do Agent SDK **não conta mais nos limites da assinatura**; passa a consumir **créditos mensais separados de Agent SDK**, medidos a **preços de API**.
- **Afetado** (vai para o pool de créditos, preço de API): Agent SDK em seus projetos Python/TS, comando **`claude -p`** (headless), **Claude Code GitHub Actions**, apps de terceiros via Agent SDK.
- **Não afetado** (continua na assinatura): Claude Code **interativo** no terminal/IDE, Claude Cowork, conversas web/desktop/mobile.
- **Créditos mensais:** Pro **$20**, Max 5x **$100**, Max 20x **$200**, Team Standard **$20**, Team Premium **$100**, Enterprise usage-based **$20**, Enterprise seat Premium **$200**. **Sem rollover**; ao esgotar, overflow só a preço de API **se habilitado**, senão pausa até renovar. (Data do anúncio "14/05/2026" e claim de "Enterprise $0" vêm de terceiros — **A VERIFICAR**.)
- **`/usage-credits`** define limite mensal de gasto em usage credits.

### 7.2 Preço oficial dos modelos (por milhão de tokens — MTok, USD)

[platform.claude.com/docs/en/about-claude/pricing](https://platform.claude.com/docs/en/about-claude/pricing), 2026-06-14:

| Modelo | Input | Cache write 5min | Cache write 1h | Cache read | Output |
|---|---|---|---|---|---|
| Claude Opus 4.8 / 4.7 / 4.6 / 4.5 | $5 | $6,25 | $10 | $0,50 | $25 |
| Claude Opus 4.1 (deprecated) | $15 | $18,75 | $30 | $1,50 | $75 |
| Claude Sonnet 4.6 / 4.5 | $3 | $3,75 | $6 | $0,30 | $15 |
| Claude Haiku 4.5 | $1 | $1,25 | $2 | $0,10 | $5 |

- **Prompt caching:** cache read (hit) = **0,1× o input** (90% de desconto); paga-se após 1 leitura (5min) ou 2 (1h). Em Claude Code, **caching é automático**.
- **Batch API: 50% off** input e output.
- **Janela de 1M tokens** em Opus 4.6/4.7/4.8 e Sonnet 4.6 a preço padrão (sem sobretaxa).
- **Tokenizer:** Opus 4.7+ podem usar **até ~35% mais tokens** para o mesmo texto — relevante para estimativa.

### 7.3 Estimar custo no desenvolvimento

Médias oficiais (deployments enterprise, [code.claude.com/docs/en/costs](https://code.claude.com/docs/en/costs)): **~$13/dev/dia ativo**, **~$150–250/dev/mês**, **90% abaixo de $30/dia ativo**. (Figura antiga "$6/dia" parece refletir versão anterior da página — tratar como desatualizada.)

Alavancas (oficiais): **custo escala com o tamanho do contexto**; CLAUDE.md carrega no início sempre (mantenha <200 linhas; mova workflow para skills); leituras de arquivos grandes inflam input (delegue a subagents/hooks que pré-filtram); auto-compaction + caching reduzem; **escolha de modelo** (Sonnet para a maioria, Opus só para raciocínio difícil, Haiku para subagents simples); thinking conta como **output** (controle com `/effort`/`MAX_THINKING_TOKENS`); **agent teams usam ~7× mais tokens**. Tracking: **`/usage`** (estimativa local — pode diferir da fatura), `/context`, `/cost`; **OpenTelemetry** nativo (`CLAUDE_CODE_ENABLE_TELEMETRY=1`) emite `claude_code.token.usage` e `claude_code.cost.usage`.

### 7.4 Anedotas de gasto solo — **TODAS de terceiros / não-oficiais**

- "Resposta honesta 2026 para a maioria dos solo devs: **$20–100/mês em assinatura**; perfis de $1.000+/mês existem mas são raros (modelos high-end + automação pesada, ou agentes não-otimizados reenviando contexto de 200K sem caching)" ([morphllm](https://www.morphllm.com/ai-coding-costs), [ssdnodes](https://www.ssdnodes.com/blog/claude-code-pricing-in-2026-every-plan-explained-pro-max-api-teams/), 2026).
- Heurística de breakeven: Pro ≈ $0,67/dia, Max 5x ≈ $3,33/dia, Max 20x ≈ $6,67/dia equivalente; "se uso é bursty ou <~$1/dia, pay-as-you-go API ganha" ([morphllm](https://www.morphllm.com/claude-code-pricing), 2026).
- Simon Willison sobre a confusão da mudança de junho: [simonwillison.net/2026/apr/22/claude-code-confusion](https://simonwillison.net/2026/apr/22/claude-code-confusion/).

---

## 8. Livros, artigos e repos de referência

**Fundamentos (specs, exemplos, BDD):**
- *Specification by Example* — Gojko Adzic, 2011, Manning. [link](https://www.manning.com/books/specification-by-example)
- *Bridging the Communication Gap* — Gojko Adzic, 2009. [link](https://gojko.net/books/bridging-the-communication-gap/)
- *Living Documentation* — Cyrille Martraire, 2019, Addison-Wesley. [leanpub](https://leanpub.com/livingdocumentation)
- *Introducing BDD* — Dan North, 2006. [link](https://dannorth.net/introducing-bdd/)

**Engenharia assistida por IA:**
- *Beyond Vibe Coding* — Addy Osmani, 2025, O'Reilly. [beyond.addy.ie](https://beyond.addy.ie/) — quando "vibe code" vs. rigor de engenharia.
- *Leading Effective Engineering Teams in the Age of GenAI* — Addy Osmani, 2025. [substack](https://addyo.substack.com/p/leading-effective-engineering-teams-c9b) — "IA faz os primeiros 70%, humanos donos dos 30% difíceis".
- *Simon Willison's Weblog* — [simonwillison.net](https://simonwillison.net/) — melhor comentário corrente sobre LLMs/agentes/coding. ([Beyond Vibe Coding](https://simonwillison.net/2025/Sep/4/beyond-vibe-coding/), [2025: the year in LLMs](https://simonw.substack.com/p/2025-the-year-in-llms)).

**SDD canônico:**
- *GitHub Spec-Kit* — [repo](https://github.com/github/spec-kit), [docs](https://github.github.com/spec-kit/).
- *Spec-driven development with AI* — Den Delimarsky, GitHub Blog, 2025-09-02. [link](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- *Understanding SDD: Kiro, spec-kit, Tessl* — Birgitta Böckeler, martinfowler.com, 2025-10-15. [link](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) — **leia primeiro** para evitar cargo-cult.
- *Exploring Generative AI* (série) — Böckeler/Fowler. [link](https://martinfowler.com/articles/exploring-gen-ai.html)
- *AWS Kiro docs* — [link](https://kiro.dev/docs/specs/). *Tessl* — [tessl.io](https://tessl.io/).
- *Spec-Driven Development book* — [sddbook.com](https://sddbook.com/) — **A VERIFICAR** autor/status de publicação.

**Engenharia de agentes (Anthropic + comunidade):**
- *Building Effective AI Agents* — Anthropic, dez/2024. [link](https://www.anthropic.com/engineering/building-effective-agents) — workflows vs. agentes; "keep it simple". [Cookbook](https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents).
- *Claude Code: Best practices for agentic coding* — Anthropic, abr/2025 (URL redireciona para [docs](https://code.claude.com/docs/en/best-practices)).
- *Effective context engineering for AI agents* — Anthropic, 2025-09-29. [link](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- *awesome-claude-code* — comunidade. [repo](https://github.com/hesreallyhim/awesome-claude-code) — skills/hooks/slash commands prontos.

**Críticos/céticos (2025-2026):**
- *The Pragmatic Engineer* (Gergely Orosz) sobre limites do AI coding. [link](https://newsletter.pragmaticengineer.com/p/how-ai-will-change-software-engineering) — visão equilibrada.
- Peças de "vibe coding = tech debt" ([Pixelmojo](https://www.pixelmojo.io/blogs/vibe-coding-technical-debt-crisis-2026-2027) e Medium) — **vendor/opinião; estatísticas secundárias, verificar antes de citar**.

---

## 9. Recomendação para 1 dev + Claude Code

**Stack mínimo recomendado (tudo grátis/agnóstico, adotável já):**

1. **Disciplina SDD leve, não ferramenta pesada.** No repo: um `constitution.md` curto (princípios não-negociáveis, emprestado do Spec-Kit) + por feature uma pasta `docs/specs/<feature>/` com `requirements.md` (critérios em **EARS**), `design.md` e `tasks.md` (emprestado de Kiro). Não instale Spec-Kit/Kiro inteiros — o overhead supera o ganho para 1 dev (discussão #1784; Böckeler).

2. **Spec → teste → código, com TDD forçado por hook.** Cada critério EARS vira um teste. Um hook `PreToolUse` (matcher `Write|Edit`) sai com **exit 2** se você tentar editar `src/**` sem teste correspondente. Um hook `Stop` roda a suíte e bloqueia se vermelha. Sem Gherkin/Cucumber: use testes nativos com nomes Given/When/Then claros (arrange/act/assert), exceto onde tratar o agente como "segundo leitor" justifique o formato.

3. **Arquitetura de contexto Claude Code:** `CLAUDE.md` <200 linhas; Skills para domínio detalhado; um subagent `security-reviewer` (só Read/Grep); hooks `PostToolUse` rodando formatter + **gitleaks** a cada edição.

4. **Segurança em camadas (não-negociável em healthcare):** Gitleaks pre-commit + TruffleHog/push-protection no CI; **zero segredos em `.mcp.json`/settings**; Claude Code least-privilege (deny rules para paths sensíveis), sem `--dangerously-skip-permissions` fora de sandbox; verificar todo pacote sugerido; **escrever à mão o núcleo de invariantes de alocação** (fairness, limites de capacidade, elegibilidade) e cercá-lo de evals.

5. **Portal "estado vivo":** comece com **Obsidian + Dataview** (dashboard local que consulta `status`/`owner`/`last_updated` do frontmatter das specs). Quando precisar publicar, aponte **MkDocs Material** para a mesma pasta `.md` — sem migração, sem lock-in.

6. **Custo:** comece em assinatura **Max 5x** (a partir de $100/mês — verificar), use Sonnet como default e Opus só para raciocínio difícil, mantenha contexto enxuto (o caching automático ajuda), monitore com `/usage` e OpenTelemetry. **Lembre da mudança de 15/06/2026:** se você automatizar via Agent SDK/`claude -p`/GitHub Actions, isso passa a consumir créditos separados a preço de API — planeje.

7. **Loop de aprendizado do repo:** ao corrigir o agente, capture o padrão de volta em CLAUDE.md/skill/hook. Erro recorrente vira hook que o bloqueia; convenção aprendida vira skill. Assim "quanto mais usa, mais aprende o negócio".

**Mantras de risco (cole no CLAUDE.md):** você vai *sentir-se* mais rápido e mais seguro do que está (Stanford/METR) — a spec e a suíte de testes são a única verdade; IA amplifica suas práticas, então mantenha lotes pequenos e teste tudo (DORA).

---

## 10. O que ainda precisa ser confirmado

- **Preços do Kiro** e o multiplicador 5× de spec-mode (fontes secundárias) → confirmar em [kiro.dev/pricing](https://kiro.dev/pricing/).
- **Limites de uso de assinatura por janela** (prompts/5h, caps semanais) — só em fontes terceiras → confirmar nas páginas oficiais de suporte.
- **Mudança de billing do Agent SDK (15/06/2026):** confirmada no [suporte oficial](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan); **data do anúncio (14/05/2026)** e claim "Enterprise standard = $0 crédito" → **A VERIFICAR** (fontes terceiras).
- **Enquadramento "Max 20x = $200"** — a página oficial diz "a partir de $100"; o $200 aparece no artigo de suporte e em terceiros → confirmar no momento da compra.
- **"Auto Memory" do Claude Code** (`MEMORY.md` auto-gerado) → confirmar existência/comportamento atual na doc oficial de memória antes de depender; o mecanismo confirmado é curadoria manual de CLAUDE.md/skills/hooks.
- **Status de busca local embutida no Docusaurus** → docusaurus.io/docs/search.
- **Obsidian "Bases"** (alternativa first-party ao Dataview) → verificar capacidades na versão atual.
- **Tessl Framework hands-on** (CLI, comandos, acessibilidade solo) — closed beta, só fontes first-party; valuation ($750M) e datas de funding inconsistentes → não confirmados.
- **Versão exata do modelo Claude padrão no Kiro** (Sonnet 4 / 3.7 / 4.6 divergem entre fontes).
- **METR (slowdown de 19%)** e estatísticas de blogs de "tech debt" — finding do METR é primário e robusto, mas verifique percentuais secundários (Pixelmojo/Medium) na fonte primária antes de citar.

---

> **Nota metodológica.** Relatório produzido por pesquisa web multi-fonte (7 frentes paralelas, ~110 tool-uses), com verificação adversarial das afirmações mais carregadas (Böckeler SDD, mecânica de hooks via doc oficial, billing do Agent SDK via suporte oficial). Datas e preços referem-se a 2026-06-14 e degradam com o tempo. Onde só havia fonte first-party ou terceira, está sinalizado.
