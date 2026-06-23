---
id: UI-MONITOR-INTEGRACAO
title: Monitor de Integração / Janela
status: draft
area: Visibilidade + SLA (funil de integração · alerta de janela)
last_update: 2026-06-14
---

# UI-spec — Monitor de Integração / Janela

> Tela Figma: **Monitor de Integração** (id `40:2`) — alerta proativo + KPIs + funil 30d + tabela
> "em risco" (`design/BUILD-PROGRESS.md`). **Diferencial proposto** a partir da análise da planilha
> (`05-processo-manual-excel.md` §4): converter monitoramento reativo em alerta **antes** da janela expirar.

## 1. Propósito / Dor _(Definition of Success)_
- **Dor:** **7,7%/mês perdido por "janela de envio expirou"** (420 casos no mês, até 15 tentativas),
  visível só **depois** de perdido — a falha mais cara e reativa (`05-processo-manual-excel.md` §4 e
  §6, dor 3; `BUILD-PROGRESS.md` "Achados da planilha").
- **De quem:** Admin/Demandas.
- **Evidência:** [LITERAL] aba `Perdidos` (424 linhas, motivo dominante "Janela de envio expirou") +
  aba `Dashboard` (funil de 8 etapas).
- **Sucesso = quando:** o operador é **alertado antes** da janela expirar, vê o funil de conversão
  (onde os agendamentos caem) e trabalha a fila de **recuperáveis** antes que virem **perdidos**.

## 2. Layout
**Shell:** `.sidebar` (nav "Monitor de Integração" `.nav-item--active`) + `.topbar` (**Admin · PTM**).

Seções:
1. **Banner de alerta proativo** (`.card` com `.badge--warning`/`--danger`) — "N agendamentos com
   janela expirando em < Xh" + ação `.btn--primary` ("Ver em risco"). É o diferencial (alerta ANTES).
2. **Faixa de KPIs** (`.kpi`) — Capturados · **Integrados (% sucesso)** (`.kpi--success`) ·
   Recuperáveis (`.kpi--warning`) · **Perdidos (% irreversível)** (`.kpi--danger`). (Espelha aba `Dashboard`.)
3. **Funil de conversão** (`.card` com etapas) — 8 etapas do pipeline do hub: capturado → ficha →
   ingestão → paciente OK → doutor encontrado → procedimento mapeado → unidade mapeada → **integrado**
   (cada etapa com Quantidade · % · Queda). (Aba `Dashboard` §4.)
4. **Tabela "em risco / recuperáveis"** (`.table`) — Caso · Especialidade · Unidade · Situação
   (`.badge`) · Tempo até expirar · **O que fazer** (ação textual) · Tentativas. Espelha abas
   `Recuperáveis` (fila de trabalho) e `Perdidos`.

## 3. Dados & campos
| Campo | Tipo | Origem |
|---|---|---|
| alerta.qtd_em_risco | inteiro | agendamentos com janela próxima de expirar (regra de janela) |
| alerta.tempo_ate_expirar | duração | derivado da janela configurável (relaciona-se a D-013) |
| kpi.capturados / integrados / recuperaveis / perdidos | inteiro + % | funil de integração (aba `Dashboard`, §4) |
| funil[].etapa / qtd / pct / queda | linhas | 8 etapas do pipeline do hub (§4) |
| risco[].situacao | enum | ex.: "Aguardando revisão", "Janela perdida" (abas `Recuperáveis`/`Perdidos`) |
| risco[].o_que_fazer | texto | ação sugerida (coluna "O que fazer" do Excel) |
| risco[].tentativas | inteiro | nº de tentativas (Excel: 2–15) |

## 4. Estados (board "Estados" id `36:2`)
- **Default:** banner (se houver risco) + KPIs + funil + tabela.
- **Vazio:** `.empty-state` — "Nenhum agendamento em risco no momento" (estado saudável).
- **Loading:** `.skeleton` em KPIs, funil e tabela.
- **Erro:** `.error-state` 403/500; banner de erro se a fonte de integração estiver indisponível.
- **Sucesso:** `.toast` ao concluir uma ação de recuperação (ex.: "Caso reenviado / dados corrigidos").

## 5. Comportamento responsivo (D-015)
- **≥ lg:** banner full + KPIs em linha + funil + tabela.
- **md–lg:** `.sidebar` em rail; **KPIs 2 colunas**; funil vertical; tabela com scroll.
- **< md:** top app bar + `.drawer`; banner full prioritário no topo; **KPIs 1–2 col**; funil
  vertical compacto; **tabela → cards empilhados** com "tempo até expirar" e "o que fazer" em destaque.

## 6. Regras de negócio
- **D-019** — internaliza a camada de monitoramento/triagem de exceções do Excel (sair do Excel).
- **D-013** — janela configurável (ex.: 24h/48h) é o conceito que dispara o alerta; o operador pode
  agir manualmente na v1 (não precisa ser automático). _O alerta de janela desta tela é a leitura
  proativa dessa janela._
- O alerta **antecipa** o que hoje só é visto depois (janela perdida = 7,7%) — diferencial registrado
  em `BUILD-PROGRESS.md` "Achados da planilha".
- **D-008** — operação é do **Admin/Demandas**.

## 7. Critérios de aceite (EARS)
- QUANDO existem agendamentos com janela expirando dentro do limiar configurado, O SISTEMA DEVE exibir o banner de alerta proativo com a contagem e a ação "Ver em risco".
- QUANDO o operador aciona "Ver em risco", O SISTEMA DEVE filtrar a tabela para os casos recuperáveis/em risco ordenados por tempo até expirar.
- QUANDO um caso é recuperável, O SISTEMA DEVE exibir a ação sugerida ("O que fazer") e o número de tentativas.
- QUANDO o funil é exibido, O SISTEMA DEVE mostrar a quantidade e a queda em cada uma das etapas de integração.
- QUANDO não há nenhum caso em risco, O SISTEMA DEVE exibir o estado vazio (saudável) sem banner de alerta.
- QUANDO um usuário sem papel Admin acessa o monitor, O SISTEMA DEVE responder com erro 403 (D-008).

## 8. Perguntas abertas
- 🔴 **Regra de prazo da "janela de envio"** que expira (causa de 7,7% de perda) não está definida —
  qual o prazo, por que casos chegam a 15 tentativas (`05-processo-manual-excel.md` §8;
  `03-open-questions.md`). Sem isso, o gatilho do alerta não pode ser implementado.
- 🔴 **Fonte dos dados do funil/integração:** o "REGULA-HUB" do Excel é o mesmo sistema do projeto ou
  um produto anterior do AM (outro cliente/contexto AM/SISReg vs HC-SP)? (`05-processo-manual-excel.md`
  §8). Define se este monitor lê da nossa integração com a TC ou de um hub externo.
- 🟡 As 8 etapas do funil pertencem ao hub do AM; quais etapas se aplicam ao nosso fluxo
  (`POST /integration/appointment` é síncrono, sem fila — `04-integration-teleconsulta.md`)?
- 🟡 Como o limiar de alerta se relaciona com a janela de **remanejamento** (D-013) — é a mesma janela?
- 🟢 Classes em `design/components/components.css` ainda não materializadas (seguem UI Kit `24:2`).
