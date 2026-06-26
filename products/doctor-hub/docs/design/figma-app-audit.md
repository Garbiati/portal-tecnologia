# Auditoria Figma × App — tela a tela (loop de conformidade)

> **Objetivo:** varrer todas as telas do protótipo Figma (`snTNGRUJO2GwoKpXTHCBjf`) e comparar com o
> que o app (`doctor-hub-web`) entrega. **Critério = FUNCIONALIDADES e CAMPOS, não estilo** (regra do
> `CLAUDE.md` do produto). Cada iteração do loop pega a próxima tela `⬜ pendente`, entende o que o app
> entrega, compara com o(s) frame(s) do Figma e dá um veredito; se conforme, avança.
>
> **Fonte do mapeamento:** `src/app/routes.ts` (cada rota tem `figmaId`) + inventário do arquivo Figma.
> **Diretriz Suprema:** divergência que toca **regra de negócio** vira pergunta/flag — NÃO se "conserta" por suposição.

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
| 13 | `/` · **Início · Pendências** | `514:6045` | ⬜ | Home da persona Demandas. |
| 14 | `/solicitacoes-inbox` · **Inbox** | `516:6102` | ⬜ | Inbox de solicitações. |
| 15 | `/disponibilizacao` · **Disponibilização** | `516:6307` (multi-cliente) | ⬜ | ⚠ id Figma nomeado "visão multi-cliente" (conferir). |
| 16 | `/sobrepor-falta` · **Sobrepor (em falta)** | `517:6093` | ⬜ | Solicitação × capacidade. |
| 17 | `/sobrepor-capacidade` · **Sobrepor (coberto)** | `651:6207` | ⬜ | Caso com capacidade. |
| 18 | `/disponibilizacao-reservado` · **Reservado** | `518:6109` | ⬜ | DRAFT reservado. |
| 19 | `/painel` · **Painel / Relatório** | `511:6029` | ⬜ | Relatório de contratação (+ exportar `641:6188`). |

## C. Gestor Regional / Gestor Geral (personas)

| # | Rota (app) | Frame(s) Figma | Status | Notas |
|---|-----------|----------------|--------|-------|
| 20 | `/assuncao` · **Assumir / Agendar** | `522:6125` | ⬜ | Gestor Regional. |
| 21 | `/minhas-solicitacoes` · **Minhas Solicitações** | `530:6141` | ⬜ | Gestor Geral. |
| 22 | `/de-acordo` · **De Acordo** | `531:6251` | ⬜ | Gestor Geral (disponibilização de acordo). Nova solicitação `531:6141` (conferir). |

## D. Conta / acesso (neutras)

| # | Rota (app) | Frame(s) Figma | Status | Notas |
|---|-----------|----------------|--------|-------|
| 23 | `/` (login) · **Login** | `65:2` | login·erro `66:2` | ⬜ |
| 24 | `/seletor` · **Entrar como** | `529:6141` | ⬜ | Seletor de persona (única ponte). |
| 25 | `/configuracoes` · **Meus dados** | `57:2` | ⬜ | Conta · Meus dados. |
| 26 | (conta) · **Configurações** | `59:2` | ⬜ | Conta · Configurações (menu avatar `683:6241`). |

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
