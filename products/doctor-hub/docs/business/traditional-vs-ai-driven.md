---
title: "Desenvolvimento Tradicional × AI-Driven (AI Coding + SDD+TDD)"
subtitle: "Comparativo honesto para o projeto Saúde Digital — Demandas"
status: draft
date: 2026-06-14
author: Staff Architect (agente)
rastreabilidade: >
  docs/method/ai-coding-sdd-report.md (METR, DORA, GitClear, Veracode, Stanford CCS, GitGuardian, USENIX);
  products/doctor-hub/docs/architecture/03-sdd-tdd-e-agentes-paralelos.md; docs/method/spec-first-hook.md;
  CLAUDE.md (Diretriz Suprema + princípios de risco); decisions-log.md (M-001..M-004)
tags: [negocio, custo, governanca, seguranca, sdd, tdd, ai-coding, previsibilidade]
---

# Desenvolvimento Tradicional × AI-Driven (AI Coding + SDD+TDD)

> **Tese, sem hype.** A IA **não é mágica** e a pesquisa é explícita nisso (ver
> `docs/method/ai-coding-sdd-report.md`): isolada, ela acelera boilerplate mas **introduz
> riscos reais** — código inseguro por padrão, vazamento de segredo, dependências
> inexistentes, dívida técnica acelerada e uma perigosa **lacuna de superconfiança**. O que
> torna o modelo **AI-Driven** vantajoso **neste projeto** não é a IA sozinha; é o **arcabouço
> que a cerca**: **spec como fonte da verdade + testes como guardrails + enforcement
> determinístico por hooks + validação humana no núcleo crítico**. Esse arcabouço **mitiga**
> os riscos conhecidos e converte velocidade bruta em **previsibilidade, governança e
> segurança**. Sem ele, "AI-Driven" é só "vibe coding" — e aí o tradicional é mais seguro.

Neste documento, **"AI-Driven"** significa sempre **AI Coding sob a disciplina SDD+TDD com
enforcement**, exatamente como descrito em `products/doctor-hub/docs/architecture/03-sdd-tdd-e-agentes-paralelos.md`
e `docs/method/spec-first-hook.md`. Não é AI Coding cru.

---

## 1. Tabela comparativa

| Dimensão | Tradicional (humano-centrado, sem IA estruturada) | AI-Driven (AI Coding + SDD+TDD + enforcement + validação humana) |
|---|---|---|
| **Custo** | Custo dominado por **horas-pessoa**. Para 1 dev, throughput limitado pela capacidade humana de digitar/refatorar. Sem custo de tokens, mas sem alavanca de escala. | **Tokens substituem parte das horas** em boilerplate, CRUD, testes, UI a partir de tokens de design. Estimativa oficial ~$13/dev/dia ativo, ~$150–250/mês (Claude Code costs). **Custo escondido: "verification tax"** (DORA) — tempo poupado é re-gasto verificando. Líquido positivo **só** com testes/specs que automatizam essa verificação. |
| **Tempo / Velocidade** | Previsível-porém-linear. Sem ganho em tarefas repetitivas. Risco baixo de "sentir-se rápido sem ser". | Rápido em boilerplate; **paralelização real** (vários agentes, 1 por bounded context — §3 da arquitetura). **Cautela honesta (METR 2025):** em código maduro e familiar, devs experientes ficaram **19% mais lentos** com IA, ainda achando-se mais rápidos. O ganho concentra-se em greenfield/boilerplate, **não** no núcleo médico que o Staff já domina. |
| **Previsibilidade** | Boa em times maduros; depende da disciplina individual. A "verdade" mora na cabeça do dev. | **Maior — por construção.** A spec (EARS) + suíte de testes são o **contrato**; o hook `Stop` impede fechar com árvore vermelha; o hook spec-first impede codificar sem spec `specified`. O resultado é **derivável da spec**, não da sensação de progresso (mitiga a lacuna de superconfiança Stanford 2023 / METR 2025). |
| **Governança** | Informal para 1 dev: depende de code review (que aqui **não existe** — sem segundo par de olhos). Decisões podem ficar implícitas. | **Forte e explícita.** Constituição (`CLAUDE.md`, Diretriz Suprema) + `decisions-log.md` (M-001..M-004, D-xxx) + hooks determinísticos + anti-inferência automatizada (Regra 4 do hook). Toda regra confirmada vira registro **antes** de virar código. Governança é **executada pela máquina**, não confiada à memória. |
| **Segurança** | Risco "normal": o dev escreve o que entende. Sem amplificação de risco por geração automática. | **Risco bruto MAIOR** se crua: IA escolhe implementação insegura ~45% das vezes (Veracode 2025), ~dobra vazamento de segredo (GitGuardian 2026), ~20% das deps podem ser inexistentes/slopsquatting (USENIX 2025), devs com assistente escrevem código menos seguro **e acham-no seguro** (Stanford CCS 2023). **Mitigado** por baseline de segurança em camadas + scanning como gate de CI + núcleo crítico à mão. |
| **Qualidade / Manutenibilidade** | Depende do dev; refatoração é decisão humana consciente. | **Risco bruto de dívida** (GitClear 2025: duplicação ~8×, copy/paste 8,3%→12,3%, refatoração 25%→<10% entre 2021–2024). **Mitigado** por TDD (testes antes), lotes pequenos (DORA), testes de contrato e lint de fronteira que impedem acoplamento acidental. Spec vira **documentação viva** rastreável. |
| **Escalabilidade** | Limitada à largura de banda de 1 humano. Não paraleliza. | **Escala por paralelização governada:** 1 agente = 1 módulo, atrás de contrato testado; kernel compartilhado humano-led; gates de CI como "arquitetura executável". 14 telas / vários módulos em ondas paralelas (§3 arquitetura) sem quebrar fronteiras — **desde que** os contratos estejam `specified`/`tested`. |

> **Leitura honesta da tabela:** quase toda vantagem do AI-Driven depende da palavra
> **"mitigado"**. Remova o SDD+TDD+enforcement e as colunas de Segurança, Qualidade e
> Previsibilidade **invertem** — o tradicional passa a ser mais seguro. O diferencial **não é a
> IA; é o arcabouço de controle**.

---

## 2. Narrativa por dimensão

### 2.1 Custo
O modelo tradicional troca dinheiro por **horas-pessoa**; para 1 dev solo, isso é um teto rígido
de throughput. O AI-Driven troca parte dessas horas por **tokens** (~$13/dia ativo, ~$150–250/mês
em médias oficiais de deployments — `costs` do Claude Code), com forte alavanca em boilerplate,
CRUD, testes e UI gerada a partir de `design/tokens`. **Mas o custo não é só o token.** O DORA 2025
nomeia a **"verification tax"**: o tempo poupado na escrita é re-gasto verificando a saída da IA.
O custo líquido só cai quando **a verificação é automatizada** — e é exatamente o que a suíte de
testes + specs EARS fazem aqui: o teste é o verificador, não o humano relendo linha a linha.
Sem isso, o AI-Driven pode sair **mais caro** que o tradicional.

### 2.2 Tempo / Velocidade
A velocidade do AI-Driven é **real, mas não uniforme**. O METR (RCT, jul/2025) é o dado mais
desconfortável e mais relevante para este projeto: **16 devs experientes em repositórios maduros
que eles conheciam ficaram 19% mais lentos** com IA — enquanto previam +24% e, mesmo depois,
ainda acreditavam ter sido +20% mais rápidos. O perfil do projeto (Staff Engineer no sistema que
ele mesmo arquitetou) é **justamente** o perfil onde o ganho some e a percepção engana. A
conclusão de design não é "não usar IA"; é **direcionar a IA para onde ela ganha** (boilerplate,
casca de UI, módulos novos, testes) e **manter o núcleo de invariantes médicas à mão**
(`CLAUDE.md` princípio nº 3). A velocidade que importa aqui vem da **paralelização governada**
(§3), não de digitar mais rápido o código crítico.

### 2.3 Previsibilidade — o maior diferencial
No tradicional solo, a "fonte da verdade" é a cabeça do dev; a previsibilidade depende da
disciplina pessoal e é frágil sob pressão. No AI-Driven **deste projeto**, a previsibilidade é
**estrutural**: cada critério de aceitação em **EARS** (`QUANDO <gatilho>, O SISTEMA DEVE
<resposta>`) vira teste; o estado da spec percorre `draft → specified → tested → implemented`
(M-001); e os hooks tornam o caminho **não-opcional**. O resultado de uma sessão é **derivável do
contrato escrito**, não da sensação de progresso — que a pesquisa prova ser enganosa (a "lacuna de
superconfiança": Stanford CCS 2023 + METR 2025). Previsibilidade aqui = "o que a spec e os testes
dizem é o que o sistema faz".

### 2.4 Governança
Esta é a fraqueza estrutural do **tradicional solo**: sem um segundo par de olhos, governança vira
"confiar na memória do dev". O AI-Driven inverte isso ao tornar a governança **explícita e
executável**: a constituição (`CLAUDE.md`) com a **Diretriz Suprema** ("NÃO INFERIR REGRA DE
NEGÓCIO. NA DÚVIDA, PERGUNTAR"), o `decisions-log.md` (M-001..M-004 e D-xxx), e a **anti-inferência
automatizada** (Regra 4 do hook: não promover `draft→specified` com 🔴 aberto). Em domínio com
**dado sensível (LGPD)** e **dinheiro público**, onde o custo de uma regra errada é alto, ter a
governança **na máquina** em vez de na boa-fé é uma vantagem decisiva — e o tradicional, sem isso,
fica para trás.

### 2.5 Segurança
Aqui é preciso ser **brutalmente honesto**: AI Coding cru é **menos seguro** que o tradicional. A
pesquisa não deixa dúvida — Veracode 2025 (implementação insegura escolhida ~45% das vezes, **sem
melhora entre gerações**), Stanford CCS 2023 (dev assistido escreve código **menos seguro e o julga
mais seguro**), GitGuardian 2026 (IA **~dobra** a taxa de vazamento de segredo; 24.008 segredos em
arquivos de config MCP), USENIX 2025 (**~20%** das saídas referenciam pacotes inexistentes,
"slopsquatting", com alucinações **repetíveis**). A análise mais perigosa para este projeto é a
**alucinação de regra de negócio / API interna** — não há registry público para pegá-la; só **spec,
testes e revisão humana** pegam. O AI-Driven só vence em segurança **porque** envelopa a IA num
**baseline em camadas** (§3): sem essa camada, escolha o tradicional.

### 2.6 Qualidade / Manutenibilidade
GitClear (2025, 211M linhas) mostra a dívida técnica que a IA **acelera** quando descontrolada:
duplicação de blocos ~8× em 2024, copy/paste subindo de 8,3% (2021) para 12,3% (2024) — o primeiro
ano em que copy/paste superou código refatorado — e refatoração caindo de 25% para <10%. (Caveat de
honestidade: GitClear é fornecedor e o dado é **correlacional**.) A contramedida do projeto é o
próprio TDD (o teste vem antes, forçando design testável), **lotes pequenos** (DORA: "IA amplifica
suas práticas"), testes de contrato entre módulos e lint de fronteira de import. Bônus: a spec não é
descartada — vira **documentação viva** rastreável (M-001..M-004), o que é mais manutenível que o
conhecimento tácito do tradicional solo.

### 2.7 Escalabilidade
O tradicional solo **não escala**: é a largura de banda de uma pessoa. O AI-Driven escala por
**paralelização governada** (§2–3 da arquitetura): **um agente é dono de exatamente um bounded
context**, edita só dentro do seu módulo e consome os outros **apenas pela porta/contrato testado**;
o **kernel compartilhado** é humano-led (mudança rara e revisada); e os **gates de CI** (testes de
contrato, lint de dependência, suíte de aceite, verde obrigatório) funcionam como **"arquitetura
executável"** que os agentes respeitam por construção. Assim, módulos e telas independentes avançam
em **ondas paralelas** sem deriva de regra — desde que seus contratos já estejam `specified`/`tested`.

---

## 3. Como governamos os riscos

Esta seção é o coração do argumento: **os ganhos do AI-Driven existem porque os riscos conhecidos
são governados por mecanismos concretos**, não por otimismo. Cada controle abaixo ataca um risco
nomeado na pesquisa.

### 3.1 Constituição / Diretriz Suprema (governa: alucinação de regra de negócio)
`CLAUDE.md` é a **constituição** carregada em toda sessão. A **Diretriz Suprema** — *"NÃO INFERIR
REGRA DE NEGÓCIO. NA DÚVIDA, PERGUNTAR"* — proíbe a IA de "preencher por bom senso" o que não está
escrito. Toda suposição vira **pergunta aberta**; toda regra confirmada vira **registro** (D-xxx)
**antes** de virar código. É a resposta direta ao risco de **alucinação de regra** (o análogo
interno do slopsquatting, sem registry para pegar).

### 3.2 Hooks spec-first / TDD (governa: superconfiança, código sem contrato)
Os hooks de `docs/method/spec-first-hook.md` são **determinísticos** — `CLAUDE.md` é conselho
(advisory), hooks são **executados** (exit 2 = bloqueia):
- **Regra 1 — sem spec validada ⇒ não codifica** (`PreToolUse` bloqueia Edit/Write de código quando
  não há `spec.md` `specified`).
- **Regra 2 — teste antes do código** (sem teste correspondente ⇒ bloqueia).
- **Regra 3 — não fechar sessão com árvore vermelha** (`Stop` roda a suíte).
- **Regra 4 — anti-inferência** (não promover `draft→specified` com 🔴 aberto — **pergunte ao
  humano**).

Isso transforma a frase "a spec é a fonte da verdade" em **regra da máquina**, e neutraliza a
**lacuna de superconfiança**: a IA (e o humano) **não conseguem** avançar fora do fluxo
dor → spec → validação humana → teste → código.
> *Nota de honestidade:* a implementação real dos hooks depende da stack (D-001 em aberto); o que
> existe hoje é o **desenho** do comportamento. O argumento vale na medida em que esse enforcement
> for de fato implementado.

### 3.3 Baseline de segurança (governa: código inseguro, segredos, dependências fantasma)
Resposta direta a Veracode/Stanford/GitGuardian/USENIX, conforme `CLAUDE.md` princípio nº 2
(detalhe em `docs/security/security-baseline.md`, **a criar**):
- **Scanning de segredo em camadas**: Gitleaks no pre-commit + TruffleHog/push-protection no CI.
- **Zero segredo em `.mcp.json`/settings** (24.008 segredos vazados em configs MCP — GitGuardian).
- **Verificar todo pacote sugerido** pela IA antes de instalar (anti-slopsquatting; pin/lock de deps).
- **Least-privilege do agente** (read-only por padrão; nunca `--dangerously-skip-permissions` fora de
  sandbox); scanning como **gate de CI** (bloqueia em falha).

### 3.4 Gates de validação humana (governa: erro em domínio regulado, núcleo crítico)
O humano permanece **no loop** onde o custo do erro é alto:
- **Núcleo crítico à mão** (`CLAUDE.md` nº 3): invariantes médicas/financeiras — alocação,
  capacidade, elegibilidade, **fairness/remanejamento** (INV do `01-domain-model.md`) — são
  **escritas/revisadas por humano** e cercadas de testes, não delegadas cegamente.
- **Kernel humano-led**: mudança no kernel compartilhado é rara e revisada (afeta todos os módulos);
  agentes **propõem**, humano **aprova**.
- **Gate de fase** (`CLAUDE.md`): nada de stack/código de aplicação enquanto a fase de descoberta não
  fechar — evita construir sobre regra não confirmada.

### 3.5 Paralelização com contratos testados (governa: acoplamento acidental, deriva de regra)
O risco de "N agentes mexendo no mesmo sistema" é **acoplamento acidental** e **deriva de regra**.
Contido por (§2 da arquitetura): 1 agente = 1 bounded context atrás de **contrato testado**; consumo
de outros módulos **só pela porta publicada**; **testes de contrato** + **lint de fronteira de
import** como gates de CI; **verde obrigatório** antes de merge. A fronteira de propriedade **é** o
contrato testado — a arquitetura vira teste automatizado.

| Risco conhecido (pesquisa) | Controle que o governa |
|---|---|
| Alucinação de regra de negócio | Diretriz Suprema + anti-inferência (Regra 4) + `decisions-log` |
| Lacuna de superconfiança (Stanford/METR) | Hooks spec-first/TDD + spec e testes como única verdade |
| Código inseguro ~45% (Veracode) / menos seguro (Stanford) | Baseline de segurança + núcleo crítico à mão + SAST em CI |
| Vazamento de segredo ~2× (GitGuardian) | Gitleaks + TruffleHog/push-protection + zero segredo em MCP |
| Dependências inexistentes ~20% (USENIX) | Verificar todo pacote + pin/lock + SCA |
| Dívida técnica acelerada (GitClear) | TDD + lotes pequenos + testes de contrato + lint de fronteira |
| Acoplamento entre agentes paralelos | 1 agente/módulo + contratos testados + gates de CI |

---

## 4. Conclusão — por que AI-Driven é mais previsível, governável, seguro e econômico **neste projeto**

Sem hype, e amarrado à evidência:

- **Mais previsível** porque a **spec EARS + a suíte de testes são o contrato**, e os hooks tornam o
  fluxo dor → spec → validação → teste → código **não-opcional**. O resultado deixa de depender da
  *sensação* de progresso — que a pesquisa (Stanford 2023, METR 2025) prova ser enganosa — e passa a
  ser **derivável do que está escrito e testado**.

- **Mais governável** porque a governança é **executável**, não confiada à memória de 1 dev solo (que
  não tem code review): constituição + Diretriz Suprema + `decisions-log` + anti-inferência
  automatizada. Em um sistema com **LGPD e dinheiro público**, governança na máquina vale mais que
  boa-fé.

- **Mais seguro** **— com a ressalva honesta de que isso só é verdade COM o baseline**. AI Coding cru
  é comprovadamente **menos** seguro (Veracode, Stanford, GitGuardian, USENIX). O que vira o jogo é o
  envelope de segurança em camadas + o **núcleo crítico médico escrito à mão** + scanning como gate de
  CI. É o arcabouço, não a IA, que entrega a segurança.

- **Mais econômico** porque a velocidade em boilerplate/UI/testes e a **paralelização governada**
  reduzem horas-pessoa, **e** porque a "verification tax" (DORA) é paga por **testes automatizados** em
  vez de releitura humana. Sem os testes/specs automatizando a verificação, o ganho econômico
  evaporaria.

**A frase honesta de fechamento:** a IA **não** é a fonte da vantagem — é um **amplificador** (DORA:
"a IA amplifica suas práticas; práticas fortes melhoram, fracas pioram"). Neste projeto, ela é
amplificada por **práticas fortes**: spec como fonte da verdade, TDD, enforcement por hooks,
validação humana no núcleo crítico e contratos testados na paralelização. **É esse conjunto** que
torna o AI-Driven mais previsível, governável, seguro e econômico que o desenvolvimento tradicional
**para este caso específico** (1 Staff Engineer + Claude Code, saúde digital, sem segundo par de
olhos). Tire o arcabouço, e a recomendação se inverte.

---

> **Fontes** (todas em `docs/method/ai-coding-sdd-report.md`, recuperadas 2026-06-14): METR RCT
> (slowdown 19%), DORA 2025 (verification tax, "amplifica práticas"), GitClear 2025 (dívida técnica),
> Veracode 2025 (45% inseguro), Stanford CCS 2023 (menos seguro + superconfiança), GitGuardian 2026
> (~2× vazamento de segredo, 24.008 segredos em MCP), USENIX 2025 (~20% deps alucinadas). Preços e
> números degradam com o tempo — ver caveats na pesquisa.
