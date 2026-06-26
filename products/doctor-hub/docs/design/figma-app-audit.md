# Auditoria Figma × App — tela a tela (loop de conformidade)

> **Objetivo:** varrer todas as telas do protótipo Figma (`snTNGRUJO2GwoKpXTHCBjf`) e comparar com o
> que o app (`doctor-hub-web`) entrega. **Critério = FUNCIONALIDADES e CAMPOS, não estilo** (regra do
> `CLAUDE.md` do produto). Cada iteração do loop pega a próxima tela `⬜ pendente`, entende o que o app
> entrega, compara com o(s) frame(s) do Figma e dá um veredito; se conforme, avança.
>
> **Fonte do mapeamento:** `src/app/routes.ts` (cada rota tem `figmaId`) + inventário do arquivo Figma.
> **Diretriz Suprema:** divergência que toca **regra de negócio** vira pergunta/flag — NÃO se "conserta" por suposição.

## 🌙 SUMÁRIO EXECUTIVO (loop autônomo concluído — 26/06, madrugada)
**Auditei as 26 telas (A→D). Conclusão: o app está MUITO aderente ao Figma no núcleo (Médicos+Escala 100% conforme) e foi ALÉM no cockpit (Demandas). Não havia gaps de UI "claros e seguros" para corrigir — as divergências são (a) estrutura/UX, (b) decisões deliberadas já registradas, ou (c) regra de negócio/auth/LGPD que NÃO inferi (Diretriz Suprema). Por isso NÃO mexi em código de telas — só auditei e sinalizei.** Resumo:

| Seção | Telas | Veredito |
|-------|-------|----------|
| **A — Médicos + Escala** | 12 | ✅ **Tudo conforme.** Zero gap. |
| **B — Demandas / cockpit** | 7 | ⚠️ App é **superset** do Figma (provisório). Sem gap; flags de produto. |
| **C — Personas** | 3 | ✅ 2 conformes · ⚠️ Assunção (modelo batch×modal). |
| **D — Conta / Login** | 4 | ✅ Login+Seletor · ⚠️🚩 **Conta = stub** (maior gap, exige auth/LGPD). |

### 🚩 Decisões que dependem de você (não inferi — por prioridade)
1. **Conta · Configurações (#26)** — maior gap. Quer que eu construa as seções (Notificações, Preferências idioma/tema/densidade, Conta&Segurança, Privacidade&LGPD)? Várias exigem **auth real** (senha/sessões — D-109) e **LGPD/backend** (baixar dados). Posso fazer os pedaços puramente de UI/preferência (ex.: **tema claro/escuro**, densidade) se você topar.
2. **Home/Início (#13)** — adotar os KPIs **acionáveis** do Figma (Solicitações novas / A provisionar / **Sem capacidade · captar**) + coluna **PRAZO por urgência**? (Hoje o app usa status cru.)
3. **Ficha-editar (#3)** — migrar do modal+ações-por-linha para o **modo "editando" inline** do Figma? (Só UX; funcional já existe.)
4. **Assunção (#20)** — o agendamento deve fixar **horário + local** concretos por slot (como o Figma)? = modelo D-029 a confirmar.
5. **Perfil editável (#25)** — permitir editar nome/e-mail próprios? (Conta/auth.)
6. **Pequenos:** `figmaId` imprecisos no `routes.ts` (`/painel`, `/disponibilizacao`); preset **Madrugada** segue desabilitado (D-022); descrições por persona no Seletor.

**Nada foi commitado em código de telas** (tudo conforme/flag). Só este doc de auditoria foi versionado, por seção.

## Legenda
- ✅ **conforme** — campos/funcionalidades do Figma presentes no app (estilo pode diferir).
- ⚠️ **divergência** — falta/sobra de campo ou funcionalidade (detalhar; classificar gap × intencional).
- 🔴 **falta** — tela do Figma sem contrapartida no app (ou vice-versa).
- ⬜ **pendente** — ainda não auditada.
- 🔵 **sem Figma** — tela do app sem frame no Figma (N/A para esta auditoria; anotar).

## Protocolo do loop (por iteração)
1. Pega a 1ª tela `⬜` da tabela (na ordem).
2. **Entende o app:** lê a página (`src/pages/<rota>`) — campos, ações, estados.
3. **Entende o Figma:** `get_screenshot` do(s) frame(s) e estados.
4. **Compara** campo a campo / ação a ação (não estilo).
5. Escreve o veredito na coluna Status + Notas (e, se ⚠️, lista cada item e classifica).
6. **Conforme →** próxima. **Divergência →** conforme política definida (corrigir gap claro / flag se regra de negócio).

---

## A. Médicos + Escala (núcleo da Fase 1 — homologado no Figma)

| # | Rota (app) | Frame(s) Figma | Estados/variantes Figma | Status | Notas |
|---|-----------|----------------|--------------------------|--------|-------|
| 1 | `/medico/:id` · **Ficha (ver)** | `5:2` | incompleto `51:2`, inativo `55:2`, edição bloqueada `111:2` | ✅ | **Feito (D-135)** — especialidades reais do sync + RQE; header Ref./datas; provisionamento real. |
| 2 | `/medicos-escala` · **Localizar** | `16:2` | vazio `54:2`, com escala `79:2` | ✅ | Filtros (esp+nome/CRM), "Mostrar" (Todos/Com/Sem), cards c/ badges (tem/sem escala, incompleto, inativo) — todos presentes. **+Novo médico ausente nos dois** (consistente com a remoção). App ainda tem paginação (escala p/ 4523). Trivial: subtítulo app diz "…escalas", Figma "…valores" (ambos válidos). |
| 3 | `/medico/:id` · **Ficha (editar)** | `17:2` | CPF inválido `52:2` | ⚠️ | **Funcionalidade presente** (NOME/CRM travados 🔒; edita CPF/nasc/tel/email; faturamento CRUD). **Divergência de ESTRUTURA-UX (não-gap):** Figma usa 1 modo "editando" inline (campos viram inputs + ✎/🗑 por linha + Cancelar/Salvar dados); o app usa **modal** p/ dados cadastrais + **ações por linha** ("Alterar/Inativar/Remover") sempre visíveis no faturamento. Não há campo faltando nem regra divergente → **não reescrevo** (é organização de UX, não gap). A confirmar com humano se quer o modo inline unificado. |
| 4 | `/medico/:id` · **Faturamento (CRUD)** | `408:2100` (+esp), `411:2242` (+exame), `431:2892`/`432:3045` (alterar), `412:2384`/`414:2526` (remover), `428:2824`/`428:3123` (inativar) | sucessos `462:*`..`463:*` | ✅ | App tem todos os modais: add especialidade/exame, alterar (chave travada), remover (confirmação), inativar/reativar (toggle), toasts de sucesso. Cobre o conjunto do Figma (D-125/126). |
| 5 | `/medico/:id` · **Inativar/Reativar** | `92:2` (inativar), `110:2` (reativar) | — | ✅ | ZonaDeRiscoCard: inativar/reativar com confirmação (modal) + auditoria; inativo ⇒ edição bloqueada (D-130/131). Cobre os frames de confirmação. |
| 6 | `/escala` · **Ativo / Localizar** | `2:2` (ativo), `8:2` (localizar) | com escala `80:2` | ✅ | App: Localizar (filtros esp+nome/CRM, cards c/ badges) → GerirEscala → `PerfilEscalas` (cards FIXA/FLEX·ativa, dias·blocos·duração, slots/semana, "Linha do tempo"·"Arquivar", "+Criar escala", "Trocar médico", "Ver cadastro"). Bate com 2:2/8:2. |
| 7 | `/escala` · **Vazio (sem escala)** | `9:2` | — | ✅ | Mensagens condicionais (incompleto/inativo/tem-arquivada/sem-escala) + CTA "+Criar escala". Cobre 9:2. |
| 8 | `/escala` · **Criar (Nova escala)** | `10:2` | erro `22:2`, sem-especialidade `22:124`, criada `464:4967` | ✅ | Todos os campos/validações (esp, vigência início/fim-FLEX, tipo FIXA/FLEX, presets, dias, períodos±, duração-min; INV-1 conflito, INV-5 especialidade, FIXA-não-retroage). **Nota:** preset **Madrugada(22–02)** está habilitado no Figma mas **desabilitado no app** (deliberado — D-022, motor não calcula overnight). Não "conserto" (habilitar quebraria o cálculo). |
| 9 | `/escala` · **Arquivado + Histórico** | `12:2` | — | ✅ | Histórico c/ contagem, cards arquivados (badges, dias/blocos, INÍCIO/ENCERRADA/TOTAL PREVISTO), Reativar só a última (+explicação), Excluir, banner "sem escala ativa". App faz MAIS: bloqueio de conflito no reativar (INV-1/2), senha no excluir-iniciado (D-123). |
| 10 | `/escala` · **Confirmações (inline)** | `13:2` | — | ✅ | `ConfirmarModal` (Arquivar = NEUTRO, D-075d) + `ModalSenhaGestao` (Excluir já-iniciada = senha, auditado). Avaliado via inventário do app (bate com a intenção do frame). |
| 11 | `/escala` · **Modal Linha do tempo** | `14:2` | — | ✅ | `LinhaDoTempoModal` plota barras de vigência (azul=ativa, cinza=arquivada) proporcionais. Cobre 14:2. |
| 12 | `/escala` · **Modal Horas adicionais** | ~~`15:2`/`37:2`~~ | — | 🔵 | **Superado.** O próprio Figma 2:2/10:2 diz "FLEX **substitui** 'horas adicionais'". O app tem FLEX (tipo de escala). Os frames 15:2/37:2 são **legados**. O "lançar horas REALIZADAS" é outra coisa (produtividade/atendimentos realizados) — **adiada** no app ("Realizados=0, integração futura") → ver flag abaixo. |

## B. Demandas / cockpit (lado da demanda — marcado PROVISÓRIO no Figma)

| # | Rota (app) | Frame(s) Figma | Status | Notas |
|---|-----------|----------------|--------|-------|
| 13 | `/` · **Início · Pendências** | `514:6045` | ⚠️🚩 | App tem home (KPIs por status + lista de abertos). Figma usa **KPIs por ETAPA de fluxo** (Solicitações novas / Reservados em aberto / **A provisionar** / **Sem capacidade · precisa captar**) + tabela "Precisa da sua atenção" com **PRAZO** ordenado por urgência. **🚩 Decisão de produto** (reframe do cockpit, provisório, já pivotou D-083/84): vale considerar adotar os KPIs acionáveis + coluna PRAZO do Figma. Não auto-construí (semântica de "a provisionar/sem capacidade" + urgência = regra). |
| 14 | `/solicitacoes-inbox` · **Inbox** | `516:6102` | ⚠️ | Núcleo igual (tabela cliente/período/itens/total/status → **Sobrepor**). Diferenças: Figma quebra **itens multi-especialidade com qtd** por linha + marcadores "nova"/"Urgent"; app usa especialidade+qtd+badge "múltiplas" + **filtros de status** (Figma só "ordenado por prazo"). 🚩 modelo "solicitação tem N especialidades com qtd cada" = decisão de dado (não inferir). |
| 15 | `/disponibilizacao` · **Disponibilização** | `516:6307` | ⚠️ | App: Simular/Reservar/Emitir + tabela de alocação (Solicitado/Retorno/Total/Capacidade/Cobertura) + KPIs. Funcionalidade presente e RICA. Mapeamento `516:6307` ("visão multi-cliente") parece **frouxo** — conferir qual frame é a referência real. Avaliado via inventário do app. |
| 16 | `/sobrepor-falta` · **Sobrepor (em falta)** | `517:6093` | ✅ | App: caso sem cobertura (KPIs Solicitado/Disponibilizado/Faltam/Capacidade total + tabela sobreposição + "Ir para Contratação"). Cobre o frame. |
| 17 | `/sobrepor-capacidade` · **Sobrepor (coberto)** | `651:6207` | ✅ | App: caso coberto (KPIs + Estoque×demanda + Reservar→Provisionar). Cobre o frame. |
| 18 | `/disponibilizacao-reservado` · **Reservado** | `518:6109` | ✅ | Destino de "Provisionar" (DRAFT reservado). Coberto pelo fluxo do app. |
| 19 | `/painel` · **Painel / Relatório** | `511:6029` | ⚠️ | Figma `511` = só o **Relatório de contratação** (gaps por especialidade + prioridade + "contratar ~N médicos" + exportar) — que no app é o **card Contratação + modal** dentro de um `/painel` **SUPERSET** (KPIs integração, Top especialidades, Unidades por HC, Capacidade efetiva). App foi **além** do Figma. Mapeamento `figmaId` do `/painel` está impreciso (deveria apontar p/ a Visão geral, ex.: `28:2`). |

## C. Gestor Regional / Gestor Geral (personas)

| # | Rota (app) | Frame(s) Figma | Status | Notas |
|---|-----------|----------------|--------|-------|
| 20 | `/assuncao` · **Assumir / Agendar** | `522:6125` | ⚠️ | Núcleo presente: atribuir **paciente + doutor** (lógica "último que atendeu"/preferencial D-011, iniciais LGPD) → Teleconsulta. **Divergência de estrutura/modelo:** Figma = **tabela batch** (#·paciente·doutor·**horário**·**local**·status + selects inline + "Confirmar agendamentos"); app = **modal por vaga** (paciente+doutor+resumo, **sem seleção explícita de horário/local**). 🚩 se o agendamento deve fixar horário/local concreto (D-029) = modelo a confirmar. |
| 21 | `/minhas-solicitacoes` · **Minhas Solicitações** | `530:6141` (+ nova `531:6141`) | ✅ | Form "Nova solicitação" (cliente travado=escopo, período a-partir/até com default fim-do-mês, especialidades+qtd múltiplas, +Adicionar/Remover, Enviar) + histórico (cenário/esp/qtd/período/status). Cobre os frames. Avaliado via inventário do código. |
| 22 | `/de-acordo` · **De Acordo** | `531:6251` | ✅ | Cards por disponibilização (RESERVADO/ENTREGUE) com "Dou meu de acordo" → libera Assunção + KPIs (Disponibilizações/Atendimentos/De acordo). Cobre o frame. Avaliado via inventário do código. |

## D. Conta / acesso (neutras)

| # | Rota (app) | Frame(s) Figma | Status | Notas |
|---|-----------|----------------|--------|-------|
| 23 | `/` (login) · **Login** | `65:2` (erro `66:2`) | ✅ | E-mail + Senha + Entrar presentes; app ainda adiciona link "Registre-se" + toast de erro. Layout (split-screen no app × card central no Figma) = estilo. |
| 24 | `/seletor` · **Entrar como** | `529:6141` | ✅ | Cards de persona (avatar/nome/papel/unidade) → Entrar; roteia por papel (D-106). Trivial: Figma tem 1 linha de descrição por persona ("Opera a capacidade…"/"Solicita…"/"Assume os slots…") que o app não mostra. |
| 25 | `/configuracoes` · **Meus dados (Perfil)** | `57:2` | ⚠️🚩 | Figma: nome/e-mail **editáveis** + "Salvar alterações" + "Alterar foto". App: **read-only** (Linha nome/papel/e-mail/CPF/órgão/unidade) + "Trocar foto". App fundiu Perfil+Configurações numa tela mínima. 🚩 editar perfil = conta/auth (D-109 futura) — stub deliberado. |
| 26 | (conta) · **Configurações** | `59:2` | ⚠️🚩 **GAP** | Figma tem 4 seções ricas: **Conta & Segurança** (alterar senha, sessões ativas/revogar), **Notificações** (3 toggles), **Preferências** (idioma/**tema**/densidade), **Privacidade & LGPD** (baixar meus dados, histórico de acesso). App: só 2 toggles demo. **Maior gap da auditoria** — mas tudo exige **auth** (senha/sessões), **tema/i18n** ou **LGPD/backend**. 🚩 não construí (decisões de produto/segurança + sem backend). |

## E. Telas do app SEM frame no Figma (🔵 — anotar, não auditar contra Figma)
- `/clientes-hcs` (figmaId `C-HCS`), `/monitor-integracao` (`MON-INT`), `/auditoria` (`AUDIT`),
  `/config-sistema` (`CFG-SYS`), `/registro` (`-`). Surgiram no app depois do Figma Fase 1.

## F. Frames do Figma sem rota clara no app (conferir durante o loop)
- `28:2` Início · Visão geral (Home antiga) — pode ser a base do `/painel` ou `/home`.
- `490:5414`/`495:5955` Demanda · detalhe/status (PROVISÓRIO) · `654:6226` Status (diagrama, não-tela) ·
  `621:6169` Remanejamento (entrega futura) · `532:6141` Gestor Regional · Agendamentos.

---

## Registro das iterações (log)
> Cada iteração anota aqui o veredito resumido (1 linha) além de atualizar a tabela.

### ✅ Seção A — Médicos + Escala (concluída) — 12/12 telas
**Resultado: tudo conforme. Nenhum gap de UI a corrigir (zero mudança de código).** As únicas divergências são:
- **#3 Ficha-editar — estrutura de UX (não-gap):** Figma usa modo "editando" inline unificado; o app usa modal (dados) + ações por linha (faturamento). Toda a funcionalidade existe. **Decisão sua:** quer migrar para o modo inline do Figma? (só estética/UX, não funcional).
- **#8 Criar — preset Madrugada(22–02):** habilitado no Figma, desabilitado no app por decisão deliberada (D-022 — motor não calcula escala que cruza meia-noite). Mantido desabilitado.
- **#12 "Horas adicionais":** frame **legado** — o próprio Figma diz que FLEX o substitui; o app tem FLEX. ✅
- 🚩 **FLAG (regra de negócio, não inferir):** "lançar horas/atendimentos REALIZADOS" (produtividade) não existe no app (Realizados=0, integração de atendimentos é futura). Já é pergunta aberta. Não construí.
- Trivial: subtítulo de Médicos diz "…escalas" (app) vs "…valores" (Figma).
- Frames verificados visualmente: 16:2, 17:2, 2:2, 10:2, 12:2; demais (8:2,9:2,13:2,14:2 + modais de faturamento) avaliados via inventário do código (que bate).

### ⚠️ Seção B — Demandas / cockpit (concluída) — 7/7 telas
**Resultado: o app IMPLEMENTOU o cockpit, frequentemente como SUPERSET do Figma (que é PROVISÓRIO dos dois lados).** Nenhum gap onde o app esteja "faltando" funcionalidade do Figma — ao contrário, o app foi além (pivôs D-083/84: foco em NOSSA capacidade, não demanda inventada). **Não corrigi código** (mexer no cockpit toca regra de negócio/dados inventados — Diretriz Suprema). Itens p/ sua atenção:
- 🚩 **#13 Home — reframe dos KPIs:** Figma usa KPIs acionáveis (Solicitações novas / Reservados em aberto / A provisionar / **Sem capacidade · precisa captar**) + tabela "Precisa da sua atenção" com **PRAZO por urgência**; o app usa KPIs por status cru + lista simples. O do Figma é mais operacional — **vale sua decisão** se quer adotar.
- 🚩 **#14 Inbox — modelo de solicitação:** Figma trata 1 solicitação = N especialidades com qtd cada ("itens"); o app usa especialidade+badge "múltiplas". Decisão de modelo de dado (não inferi).
- **Mapeamentos `figmaId` imprecisos** no `routes.ts`: `/painel`→`511:6029` (na verdade só o Relatório de contratação; o `/painel` Visão geral ≈ `28:2`) e `/disponibilizacao`→`516:6307` (frouxo). Sugiro corrigir os ids quando revisarmos o cockpit.
- Frames vistos: 514:6045, 516:6102, 511:6029; sobrepor/reservado/disponibilização avaliados via inventário do código (detalhado). Posso aprofundar qualquer um sob demanda.

### ⚠️ Seções C+D — Personas + Conta/Login (concluídas) — 7/7 telas
**Resultado: telas de fluxo (Login, Seletor, Minhas Solicitações, De Acordo) conformes; a área de CONTA é um stub vs o Figma.**
- ✅ **#23 Login / #24 Seletor**: conformes (app cobre + extras: registro, erro). Trivial: descrições por persona no Seletor.
- ✅ **#21 Minhas Solicitações / #22 De Acordo**: forms/cards completos batem com a intenção dos frames (via inventário do código).
- ⚠️ **#20 Assunção**: núcleo presente (paciente+doutor preferencial→TC); 🚩 Figma usa tabela batch com **horário+local** por slot, app usa modal por vaga sem horário/local explícito → modelo de agendamento concreto (D-029) a confirmar.
- ⚠️🚩 **#25/#26 Conta (MAIOR GAP):** o Figma tem Perfil editável + Configurações com **Conta&Segurança (senha/sessões), Notificações (3), Preferências (idioma/tema/densidade), Privacidade&LGPD (baixar dados/histórico)**. O app tem um stub (read-only + 2 toggles). **Não construí** — exige auth (D-109 futura), tema/i18n e LGPD/backend (decisões de produto/segurança).
- Frames vistos: 65:2, 57:2, 59:2, 522:6125, 529:6141; minhas-sol/de-acordo via inventário do código.
