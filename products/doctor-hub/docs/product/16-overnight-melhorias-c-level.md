# Backlog de melhorias C-level — cockpit Doctor-Hub (painel multi-agente, 2026-06-18)

> Gerado pela FASE 3.1 do loop overnight: 4 perspectivas independentes (COO de operações de saúde, Head de
> Dados/BI, Designer de produto, Cético de viabilidade-1-dev) + sintetizador (CPO). 32 propostas → 20 priorizadas.
> Revisa a visão do cockpit (Home 28:2 · Demanda×Oferta 279:1916 · Forecast 284:1934 · Contratar 283:1941).
> **Marcação:** ✅rule-free (pode implementar já) · 🔒precisa-de-regra (PROVISÓRIO + pergunta ao dono).

## 🏆 Destaque
O painel, de forma independente, elegeu como **P0 #1 a própria Diretriz Suprema**: **marcar proveniência de cada
número** (real via sync RO × demo × projeção). Ataca o risco nº1 (superconfiança) sem travar o protótipo.

## 📊 Backlog priorizado

| # | P | Melhoria | Área | Esf. | Tipo |
|---|---|----------|------|------|------|
| 1 | P0 | **Badge de proveniência por KPI** (real/demo/projeção + tooltip de origem) | Transversal | P | ✅ |
| 2 | P0 | **Barra de frescor do dado** ("Sincronizado da TC há Xh · base DD/MM") no cabeçalho | Todas | P | ✅ |
| 3 | P0 | **Saneamento dos 3.804 incompletos** como fila de mutirão clicável (o que falta + ação + export) | Home↔Cadastro | M | ✅ |
| 4 | P0 | **Oferta auditável**: número derivado com fórmula visível (turnos×duração−intervalos) + link às escalas | Demanda×Oferta | M | ✅ |
| 5 | P0 | **Drill-down do gap → pool ocioso** (dos "−36 Gineco" aos 64 com escala + sem-escala + incompletos da espec.) | Home↔Demanda×Oferta | M | ✅ |
| 6 | P0 | **Forecast honesto**: método+horizonte+premissas+faixa P10–P90; não publicar número sem método | Forecast | M | 🔒 |
| 7 | P0 | **Contratar = registro de INTENÇÃO** rastreável (encaminhada→em andamento→suprida) + trilha LGPD | Contratar | G | 🔒 |
| 8 | P1 | **Home acionável**: manchete única de ação no topo + worklist priorizada (gap × tempo de espera) | Home | M | ✅ |
| 9 | P1 | **Remanejar antes de Contratar**: insight automático folga×déficit na mesma semana (oferta real) | Contratar·Capacidade | M | ✅ |
| 10 | P1 | **Severidade sem depender de cor**: ícone+rótulo+sinal (+/−) na matriz e tabela (WCAG 1.4.1) | Demanda×Oferta·Forecast | P | ✅ |
| 11 | P1 | **Origem da Demanda** como entrada explícita versionada (quem informa/quando) + definição no cabeçalho | Demanda | G | 🔒 |
| 12 | P1 | **Represamento/backlog com aging** (0-30/30-90/90-180/180+ dias) — o KPI que justifica o produto | Home·Demanda×Oferta | G | 🔒 |
| 13 | P1 | **Oferta fantasma**: cruzar incompletude×gap ("X dos 36 JÁ existem, só não faturam") | Home+Demanda×Oferta | M | 🔒 |
| 14 | P1 | **Alerta proativo** de gap antes de virar déficit (limiar + antecedência configuráveis) | Demanda×Oferta·Forecast | M | 🔒 |
| 15 | P1 | **Estados vazio/carregando/erro de sync** com timestamp da última leitura | Home+Demanda×Oferta | M | ✅ |
| 16 | P2 | **Drill na matriz do forecast** (célula clicável, NET sticky, ordenar por severidade) | Forecast | M | ✅ |
| 17 | P2 | **Exportação auditável** (CSV/PDF) com carimbo de base/filtros/método | Demanda×Oferta·Forecast | P | ✅ |
| 18 | P2 | **Segmentação por estado/HC/cliente** com filtro global persistente | Cockpit | G | 🔒 |
| 19 | P2 | **Detecção de anomalia** no feed de sync e séries (queda de oferta, salto de demanda) | Home·sync | G | 🔒 |
| 20 | P2 | **Corte de escopo**: adiar Forecast da 1ª entrega; focar Completude+Oferta+Escala (dado real) | Roadmap | P | ✅ |

## 🛠️ Progresso de implementação (loop)
- ✅ **#1 Badge/faixa de proveniência** — feito em Home (verde "real"), Demanda×Oferta (âmbar "demo"),
  Forecast (azul "projeção"), cada um com legenda `real (sync TC) · demo · projeção`. Strips 289:1952/1966/1980.
- 🟡 **#2 Frescor do dado** — PARCIAL: a faixa já mostra "base 17/06"; falta o "sincronizado há Xh" e estender
  às telas de Relatório. Baixa prioridade (deixar p/ depois dos outros quick wins distintos).
- ✅ **#10 Severidade sem depender de cor** — badges da tabela com ícone+rótulo (▲ Contratar / ◆ Reforçar / ✓ OK)
  + coluna GAP com sinal; matriz do forecast já usa sinal −/+ (não-cromático). WCAG 1.4.1 ok.
- ✅ **#5 Drill gap→pool ocioso** — tela `291:1952` (Ginecologia): 18 com escala / 9 ociosos / 24 incompletos
  (=51), "escalar 9 ≈ +160 = 89% do gap antes de contratar". Linha Gineco da tabela → drill; CTAs → Médicos 16:2 /
  incompleto 51:2; voltar → cockpit. Contagens=real, gap=demo (faixa). Nav 100% (57/57).
- ✅ **#4 Oferta auditável** — painel verde na Demanda×Oferta `293:1970`: declara Oferta=slots reais das escalas,
  fórmula D-072 (turnos×(60÷duração)−intervalos = 2.249) + link "Ver escalas que compõem →" (8:2). Lado REAL vs demo.
- ✅ **#3 Fila de saneamento dos incompletos** — tela `294:1970` (worklist): 6 médicos-exemplo (Gineco no topo),
  pills do que falta (CPF/RQE/Valor fixo), "Completar →" por linha → 51:2, filtros (chips). Big number "3.804" da
  Home (card 29:15) → fila; voltar → Home. Lista=real, exemplos=demo. Nav 100% (58/58).
- ✅ **#8 Home acionável** — manchete navy no topo da Home `296:1988`: "⚡ O que precisa da sua atenção · faltam 36
  terça em Gineco · 3.804 não faturam" + CTAs "Ver gap →" (279:1916) e "Sanear cadastros →" (294:1970). Leitura→ação.
- ✅ **#15 Estado de erro de sync** — tela-exemplo `297:1988` (Home · sync falhou): banner vermelho + "Tentar
  novamente" (→28:2) + dados esmaecidos 50%. Acessível por "ⓘ ver estado de sync →" na faixa da Home. Nav 100% (59/59).
- ✅ **#17 Export carimbado** — botão "Exportar ▾" + nota de carimbo (base/filtros/método) na Demanda×Oferta e
  Previsão → stub `298:2006` "Exportação gerada (PROVISÓRIO)" (trilha LGPD/comitê). Nav 100% (60/60).
- ✅ **#2 Frescor do dado** — linha "↻ Sincronizado da Teleconsulta há ~2h · base 17/06 08:12" nas 8 telas de
  Relatório (224/237/241/247/250/257/258/260). **TODOS os 9 quick wins rule-free ✅.**
- ✅ **Critic 3.3** — 60/60 alcançável · menu lateral correto (cockpit=visao, relatórios=relatorio) · 0 botões mortos.

## ⚡ Quick wins rule-free (ordem de ataque do loop)
1. **#1 Badge de proveniência** (real/demo/projeção) — P0, esforço P, serve a Diretriz Suprema. **← próximo a implementar.**
2. **#2 Barra de frescor do dado** no cabeçalho.
3. **#10 Severidade sem depender de cor** (ícone+sinal) — acessibilidade.
4. **#5 Drill-down do gap → pool ocioso** (1 clique).
5. **#4 Oferta auditável** (fórmula + link).
6. **#3 Fila de saneamento dos incompletos**.
7. **#8 Home acionável** (manchete + worklist) · **#15 estados vazio/erro** · **#17 export carimbado**.

## 🔒 Precisa-de-regra → foi para `docs/discovery/03-open-questions.md`
Origem/unidade da Demanda · método/horizonte do Forecast · efeito real do Contratar e definição de "suprido" ·
limiar/severidade do gap · existência de dado de represamento/anos-de-espera · segmentação por governo ·
definição oficial de "incompleto" · feriados no cálculo de Oferta · precedência Remanejar-antes-de-Contratar (RN-39).

## 🧭 Decisão estratégica levantada (para o dono)
**#20 — adiar o Forecast da 1ª entrega?** O Cético argumenta que, por hora/valor com 1 dev, o maior retorno
imediato está no que já tem **dado real**: mutirão de completude (3.804), cálculo de Oferta e gestão de Escala —
isso move o ponteiro dos atendimentos represados **agora**. Forecast fica como cenário honesto até ter método+série.
