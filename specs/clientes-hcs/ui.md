---
id: UI-CLIENTES-HCS
title: Clientes & HCs
status: draft
area: Cadastro base (Cliente / Health Center)
last_update: 2026-06-14
---

# UI-spec — Clientes & HCs

> Tela Figma de referência: **Clientes & HCs** (id `38:2`, `design/BUILD-PROGRESS.md`).
> Conceito introduzido por **D-018** (cliente público/privado acima do HC).

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** hoje não existe a noção de "Cliente" agrupando HCs; o controle por Excel mistura
  unidades de contextos diferentes (capital/interior, AM/SISReg) sem hierarquia, e o cadastro de
  unidade solicitante é inconsistente (ora nome, ora CNES numérico — `05-processo-manual-excel.md` §6, dor 4).
- **De quem:** Admin/Demandas (operador interno PTM).
- **Evidência:** D-018; achado [LITERAL] da planilha sobre inconsistência de unidade solicitante.
- **Sucesso = quando:** o operador cadastra/edita um Cliente (público ou privado), associa seus HCs
  com CNES, e todas as demais telas (Solicitação, Disponibilização, Painel) passam a filtrar por
  Cliente → HC de forma consistente, sem ambiguidade de identificação de unidade.

## 2. Layout
**Shell** (`design-system.md` §7): `.sidebar` (248px, item de nav "Clientes & HCs" em estado
`.nav-item--active`) + `.topbar` (64px, mostra papel logado: **Admin · PTM**).

Seções do conteúdo:
1. **Cabeçalho da página** — título `2xl/semibold` ("Clientes & HCs") + `.btn .btn--primary`
   ("Novo cliente").
2. **Segmented control** (`.chip` toggle / segmented) — filtro **Todos · Público · Privado** (D-018).
3. **Tabela de Clientes** (`.table`) — colunas: Nome do cliente · Tipo (`.badge`: público=info,
   privado=neutral) · Nº de HCs · Status. Linha `.table__row--interactive` → seleciona o cliente.
4. **Painel "HCs do cliente"** (à direita em desktop / abaixo em mobile) — `.card` com `.table`
   dos HCs do cliente selecionado: Nome do HC · CNES · Cidade/UF · Status; `.btn .btn--secondary`
   ("Adicionar HC").
5. **Drawer/Modal de edição** (`.drawer` / `.modal`) — formulário Cliente (tipo público/privado,
   nome, vínculo de governo) ou HC (nome, CNES, cidade/UF, ativo).

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| Cliente.nome | texto | cadastro próprio (Admin) |
| Cliente.tipo | enum (público \| privado) | cadastro próprio — **D-018** |
| Cliente.vinculo_governo | texto/ref | cadastro próprio (só para tipo público — ex.: estado/órgão, D-018) |
| Cliente.status | enum (ativo/inativo) | cadastro próprio |
| HC.nome | texto | cadastro próprio |
| HC.cnes | texto (código CNES) | cadastro próprio — casa com `ProfileTag`/`group_id` da TC por CNES (**D-018**, `04-integration-teleconsulta.md` §🧩-2) |
| HC.cidade_uf | texto | cadastro próprio |
| HC.cliente_id | ref | vínculo HC→Cliente (D-018: cada cliente agrupa HCs) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** lista de clientes + painel de HCs do primeiro/selecionado.
- **Vazio:** `.empty-state` — "Nenhum cliente cadastrado ainda" + ação "Novo cliente"; no painel de
  HCs: "Este cliente ainda não tem HCs" + "Adicionar HC".
- **Loading:** `.skeleton` nas linhas da tabela; spinner no `.btn--loading` ao salvar.
- **Erro:** `.error-state` 403 (sem permissão — só Admin, D-008) / 500; erro de formulário com
  borda `--color-danger` + mensagem `xs` (CNES inválido/duplicado).
- **Sucesso:** `.toast` de sucesso após salvar cliente/HC ("Cliente salvo", "HC adicionado").

## 5. Comportamento responsivo (D-015)
- **≥ lg (1024):** shell completo; lista de clientes (esquerda) + painel de HCs (direita) lado a lado.
- **md–lg (768–1023):** `.sidebar` colapsa em rail de ícones; lista e painel empilham em 1 coluna.
- **< md (mobile):** top app bar + hamburger/`.drawer`; `.table` de clientes/HCs vira **cards
  empilhados**; edição em **bottom-sheet**; inputs `font-size:16px`; alvos ≥44px.

## 6. Regras de negócio
- **D-018** — Cliente pode ser **público** (estado/órgão, ex.: Piauí) ou **privado** (clínica/plano).
  Cada cliente **agrupa HCs**; visões por HC e consolidada (todos os clientes).
- **D-008** — Cadastro/configuração é do **Admin/Demandas** (global). Solicitante e Gestor **não**
  acessam esta tela.
- HC identificável por **CNES** para casar com a TC (`group_id`/`ProfileTag`) — D-018,
  `04-integration-teleconsulta.md`.
- **D-019** — esta tela existe para internalizar a hierarquia que o Excel não tem (sair do Excel).

## 7. Critérios de aceite (EARS)
- QUANDO o usuário seleciona o segmento "Público", O SISTEMA DEVE listar apenas clientes de tipo público (D-018).
- QUANDO o usuário seleciona uma linha de cliente, O SISTEMA DEVE exibir no painel lateral os HCs daquele cliente.
- QUANDO o usuário salva um HC sem CNES ou com CNES já existente, O SISTEMA DEVE bloquear o salvamento e exibir erro de formulário no campo CNES.
- QUANDO não há nenhum cliente cadastrado, O SISTEMA DEVE exibir o estado vazio com a ação "Novo cliente".
- QUANDO um usuário sem papel Admin acessa esta tela, O SISTEMA DEVE responder com o estado de erro 403 (D-008).
- QUANDO um cliente/HC é salvo com sucesso, O SISTEMA DEVE exibir um toast de confirmação.

## 8. Perguntas abertas
- 🟡 Campos exatos do cadastro de Cliente público vs privado (ex.: para público — vínculo de
  governo/edital; para privado — plano/CNPJ?) não estão confirmados em `decisions-log`.
- 🟡 Validação/origem do CNES: digitado livre ou validado contra base externa? E se o HC não tiver CNES?
- 🟡 Escopo de dados por cliente/estado (isolamento) — provável, a confirmar (`02-roles.md`, `03-open-questions.md`).
- 🟢 A pasta `design/components/components.css` ainda não existe; classes aqui seguem o UI Kit (id `24:2`) e §5 do design-system.
