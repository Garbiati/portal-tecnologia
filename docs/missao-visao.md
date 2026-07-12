# ⭐ Missão · Visão · Objetivo · Premissas — Portal Tecnologia (Doctor-Hub)

> **A ESTRELA-GUIA.** Toda decisão e entrega valida contra isto. **Portal Tecnologia** é o braço de
> tecnologia do **Grupo Portal** (saúde), nascendo dentro da **Portal Telemedicina**. **Doctor-Hub** é
> o 1º produto. Distinção: **Missão** = por que existimos (agora) · **Visão** = onde chegamos (futuro) ·
> **Objetivo** = metas concretas/mensuráveis · **Premissas** = verdades inegociáveis que filtram cada escolha.

## 🎯 Missão (por que / agora)
Provar o desenvolvimento **AI-Driven com o método DDD2** — a documentação no centro, validada com o
C-level e virando protótipo homologável no **mesmo ambiente/usuário de produção** — construindo a
plataforma de gestão médica do Grupo Portal com um time **enxuto** (humano + agents especialistas),
não 100 desenvolvedores. Provar o DDD2 a ponto de virar **método replicável** (cursos/livros).

## 🔭 Visão (futuro / aspiracional)
**Reescrever, progressivamente, TODA a Teleconsulta** — o produto de hoje ("doctor-hub") é **nome ALPHA**
do veículo dessa reescrita AI-first (pode mudar; o objetivo é constante). O fim: **a barreira da
tecnologia deixar de existir** — doutores focam em **salvar vidas**, e a equipe de saúde **não-médica**
fica **exponencialmente eficiente**.
Unir **tecnologia e medicina** e criar o **médico tecnológico** — que documenta suas próprias
necessidades (validadas por agents) e é **premiado** (dinheiro/saldo) quando sua ideia reduz custo ou
atrai clientes. Ser a **primeira plataforma onde o usuário também co-constrói o sistema** — homologando
e melhorando de dentro, em vez de migrar pro concorrente. (O concorrente pensa: "pra que começar do
zero, se posso contribuir e ser recompensado pela minha ideia?")

## 📊 Objetivo (concreto / mensurável)
**Doctor-Hub** — plataforma **white-label** de gestão médica: **escalas · agendamentos · saldo
(solicitado × disponibilizado) · disponibilização de vagas · faturamento e ROI do cliente em tempo
real**. O ROI evolui do simples (custo de doutores, reembolso de implantação) ao complexo (equipamento,
treinamento, manutenção, folha de funcionários e terceiros) — sempre por cliente. Atender **toda a
necessidade da área médica**, **começando pela gestão** (o que HOJE alimenta a Teleconsulta), rumo à
reescrita completa (Visão). **Estratégia de ataque:** priorizar o que **mais causa REGISTRO PARALELO**
(planilha/papel/WhatsApp) — onde o sistema atual não atende, ou atende de forma complexa/lenta/burocrática
e não reflete a realidade.

## ⛓️ Premissas (inegociáveis — o filtro de cada decisão)
1. **White-label** (multi-tenant) — toda tela/feature nasce assim.
2. **AI-first + DDD2** — a doc é o sistema; o código é derivado; agents/especialistas fazem o técnico
   (segurança, arquitetura, algoritmos, performance, LGPD…), refinados por humanos.
3. **Homolog = produção** enquanto fora de uso (mesmo usuário) — até existir o sandbox dedicado.
4. **Segurança/LGPD · resiliente · escalável · barato** — não relaxar. **Infra proporcional ao uso**
   (100 usuários hoje ≠ infra pra 100 mil), mas **arquitetura que escala sem reescrever do zero**. E:
   **o código é COLATERAL** — descartável, gerado da doc; válido se atende de forma eficiente e lucrativa.
5. **Autonomia gradual + guardrails que evoluem.** A confiança na IA começa **baixa** e cresce conforme
   o humano ensina o que pode/não pode — cada decisão humana vira um **guardrail documentado** (regra
   da máquina). **Operações perigosas** (alterar **direto em produção**, deletar dado, comprometer custo
   real, tocar segredo/LGPD) → **o humano decide**. **Sandbox (clone de produção) → SEM burocracia:**
   agents movem livre. A fronteira do que a IA faz sozinha **se expande** com o tempo.
6. **ROI do cliente rastreável em tempo real.**

## ✅ Mecanismo — como isto orienta (não é decoração)
Ao fechar uma decisão (`D-xxx`/`P-xxx`) ou entrega, valida contra o farol:
- Serve a **Missão/Visão/Objetivo**? Respeita as **Premissas**?
- É **white-label**? A **doc veio primeiro** (DDD2)?
- Toca **produção / custo / dado / segredo** → **perguntei ao humano**? *(sandbox não burocratiza.)*
- **Reduz custo / atrai cliente / melhora ROI?** (o "porquê" da entrega.)

## 🗂️ Classificação por HORIZONTE (toda decisão/requisito leva um)
A doc mistura desejos de futuro com coisas prontas pra entregar — então **cada item se classifica**:
- **🎯 AGORA** — regras da realidade **capturadas e VALIDADAS** pelo humano; buildable. (ex.: fundação de multi-tenancy.)
- **⏭️ PRÓXIMO** — **decidido**, mas aguarda um pré-requisito ou discovery curta. (ex.: pull+ack, migração SOS Gestor.)
- **🔭 FUTURO/VISÃO** — **desejo**; regras a construir juntos, não agora. (ex.: reagendamento por ausência — D-210.)
- **🔍 DISCOVERY/ABERTO** — regras **ainda não confirmadas** (perguntas abertas).

**A régua que move um item de horizonte:** o humano **VALIDA que as regras documentadas refletem a
realidade e o problema**. Validou → sobe (FUTURO/DISCOVERY → PRÓXIMO → AGORA) → constrói-se. É o gate
`specified` do SDD, dito em linguagem de horizonte. Índice vivo: `products/doctor-hub/docs/roadmap-horizontes.md`.

_Última atualização: 2026-07-12 (reescrita-de-toda-a-Teleconsulta como Visão + nome Alpha; registros
paralelos; infra proporcional/escalável; código colateral; classificação por horizonte — D-209/D-210).
Nascimento: 2026-07-10._
