---
id: UI-SOLICITACAO
title: Solicitação
status: draft
area: Demanda (solicitação do governo)
last_update: 2026-06-14
---

# UI-spec — Solicitação

> Etapa ② Demanda do pipeline (`01-domain-overview.md`). Tela Figma de fluxo: **Solicitações**
> (`docs/design/figma-prototipo.md`), papel no topo **Sec. Saúde**.

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** hoje a demanda é só um agregado de export (`TOP ESPECIALIDADES`, `VOLUME POR DIA`) lido
  num painel estático do Excel — não é uma **entidade do sistema** (`05-processo-manual-excel.md` §7).
- **De quem:** Solicitante (**Secretário de Saúde estadual**, D-008).
- **Evidência:** D-019 + §7 da análise de planilha.
- **Sucesso = quando:** o Secretário registra uma solicitação (especialidades × quantidade × período,
  por HC) que vira **dado consultável** e entra na Disponibilização como demanda.

## 2. Layout
**Shell:** `.sidebar` (nav "Solicitações" `.nav-item--active`) + `.topbar` (**Sec. Saúde · <UF>**).

Seções:
1. **Cabeçalho** — título + `.btn--primary` ("Nova solicitação").
2. **Formulário de solicitação** (`.card`):
   - **Cliente** (`.select`, multi-cliente — D-018) → **HC** (`.select`, filtrado pelo cliente).
   - **Período / mês** (`.select` ou date — "período (mês)", `01-domain-overview.md` ②).
   - **Linhas por especialidade** — lista editável: Especialidade (`.select`) + Quantidade
     (`.input` number). `.btn--subtle` ("Adicionar especialidade").
   - Identificação + data da solicitação (auto: solicitante + data).
3. **Solicitações recentes** (`.table`) — Cliente/HC · Período · Nº especialidades · Total qtd ·
   Status · Data. Linha `.table__row--interactive` abre detalhe (read-only para o Solicitante).
4. Ações: `.btn--primary` ("Enviar solicitação") · `.btn--secondary` ("Cancelar").

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| solicitacao.cliente_id | ref | tela Clientes & HCs (D-018) |
| solicitacao.hc_id | ref | HC do cliente (D-018) |
| solicitacao.periodo (mês) | mês/ano | preenchido pelo Solicitante (`01-domain-overview.md` ②) |
| item.especialidade | texto/ref | lista de especialidades daquele HC |
| item.quantidade | inteiro | preenchido pelo Solicitante |
| solicitacao.solicitante | ref usuário | sessão (papel Solicitante, D-008) |
| solicitacao.data | data | sistema |
| solicitacao.status | enum | sistema (ex.: enviada / em disponibilização) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** formulário + solicitações recentes.
- **Vazio:** `.empty-state` em "Solicitações recentes" — "Você ainda não abriu nenhuma solicitação".
- **Loading:** `.skeleton` na tabela; spinner no `.btn--loading` ao enviar.
- **Erro:** erro de formulário (quantidade ≤ 0, sem especialidade, sem HC) com `--color-danger`;
  `.error-state` 403 (papel errado) / 500.
- **Sucesso:** `.toast` "Solicitação enviada" + nova linha em "Solicitações recentes".

## 5. Comportamento responsivo (D-015)
- **≥ lg:** formulário (esquerda) + recentes (direita) ou empilhados conforme largura.
- **md–lg:** `.sidebar` em rail; 1 coluna.
- **< md:** top app bar + `.drawer`; tabela de recentes → cards; formulário 1 coluna; linhas de
  especialidade empilhadas; `.select`/`.input` com `font-size:16px`; alvos ≥44px.

## 6. Regras de negócio
- **D-008** — Quem abre a solicitação é o **Solicitante (Secretário estadual)**, escopo do seu estado.
- **D-018** — Solicitação é por **Cliente → HC** (multi-cliente; HC pertence a um cliente).
- Demanda = lista de especialidades × quantidade × período (mês) por HC (`01-domain-overview.md` ②).
- **D-019** — substitui o agregado de export do Excel por demanda como entidade.

## 7. Critérios de aceite (EARS)
- QUANDO o Solicitante seleciona um Cliente, O SISTEMA DEVE restringir o seletor de HC aos HCs daquele cliente (D-018).
- QUANDO o Solicitante adiciona uma linha de especialidade com quantidade menor ou igual a zero, O SISTEMA DEVE bloquear o envio e exibir erro na linha.
- QUANDO a solicitação é enviada, O SISTEMA DEVE registrar solicitante e data automaticamente e exibi-la em "Solicitações recentes".
- QUANDO o Solicitante não tem nenhuma solicitação, O SISTEMA DEVE exibir o estado vazio na lista de recentes.
- QUANDO um usuário fora do papel Solicitante acessa a abertura de solicitação, O SISTEMA DEVE responder com erro 403 (D-008).
- QUANDO a solicitação é enviada com sucesso, O SISTEMA DEVE exibir um toast de confirmação.

## 8. Perguntas abertas
- 🟡 Escopo de dados do Solicitante (vê só o próprio estado/cliente?) — provável, a confirmar (`02-roles.md`).
- 🟡 O Solicitante pode editar/cancelar uma solicitação já enviada? Em que estado isso é permitido?
- 🟡 "Período" é sempre mês-calendário ou intervalo livre? (`01-domain-overview.md` diz "mês").
- 🟡 Origem da lista de especialidades por HC (cadastro do HC? configuração global?).
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
