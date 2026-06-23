# Processo Manual em Excel — Engenharia Reversa das Planilhas Operacionais

> Status de cada afirmação: **[LITERAL]** = está escrito/calculado na planilha · **[INFERÊNCIA]** = deduzido do conteúdo, a confirmar.
> Fonte: planilhas exportadas pelo usuário em `~/Downloads/` (read-only, analisadas via openpyxl em 2026-06-14).
> ⚠️ Nenhum dado pessoal sensível (CPF, CNS, nome completo de paciente, telefone) foi copiado para este relatório. Amostras estão resumidas/anonimizadas.

---

## 1. Visão geral

O usuário hoje opera **um pipeline de teleconsultas SUS no Amazonas (Saúde AM Digital)** controlado por planilhas Excel exportadas periodicamente de um sistema chamado, nas próprias planilhas, **"REGULA-HUB" / "hub"**. O fluxo de negócio é:

```
SISReg (regulação estadual, regulator_code=sisreg_am)
   │  exporta .csv de agendamentos regulados
   ▼
HUB (captura → ingestão → enriquece dados → integra)
   │
   ▼
Saúde AM Digital (médico + paciente + agenda → teleconsulta)
```

As planilhas **não são o sistema** — são **exportações de acompanhamento** que o usuário baixa várias vezes por dia para conferir o que entrou, o que integrou, o que ficou pendente e o que se perdeu. **[INFERÊNCIA]** O controle "manual" aqui é menos digitação e mais **monitoramento, conferência e triagem de exceções** sobre um hub de integração que já existe.

Há **dois eixos** distintos de planilha:

| Tipo | Eixo temporal | Pergunta que responde |
|------|---------------|------------------------|
| `agenda-operacional-*` | **Futuro** (próximos ~10 dias) | "O que está agendado para frente e está tudo integrado/com médico?" |
| `dashboard-30d-*` (e `24h`, `hoje`, `mes-ant`) | **Passado** (janela de 30 dias / 24h) | "Do que já passou, quanto integrou, quanto era recuperável, quanto se perdeu?" |

A planilha **`Macro Planejamento e GAP Analysis - Edital HC-SP`** é de **outro contexto** (planejamento de proposta para um edital HC-SP / e-saúdeSP) e não faz parte da operação diária; entra aqui só como contexto de roadmap.

**Relação com o projeto "Saúde Digital · Demandas":** estas planilhas evidenciam a etapa **⑤ Agendamento → Teleconsulta** do pipeline do projeto (ver `01-domain-overview.md`), só que para um cliente já em produção (AM). O hub do AM cobre captura→integração→agendamento; o que o usuário ainda faz no Excel é **a camada de gestão/visibilidade** (saldo por dia, demanda por especialidade, pendências, perdas) — exatamente a camada que o novo sistema pretende internalizar.

---

## 2. `agenda-operacional-2026-06-11.xlsx` (planilha principal)

Exportada em 11/06/2026 16:50 (Manaus). 11 abas: 1 de resumo + 10 abas-dia.

### Aba `Visão Geral` (painel de KPIs) — 59 linhas

Não tem formato tabular único; é um **painel montado** com vários blocos. Blocos **[LITERAL]**:

- **Cabeçalho/resumo em texto**: "Nos próximos 10 dias temos 1547 teleconsultas agendadas. Maior dia: sexta 12/06 com 469. Taxa de integração: 97%."
- **KPIs topo**: `TOTAL FUTURO=1547` · `DIAS=10` · `MÉDIA/DIA=155` · `PICO=12/06 (469)` · `TAXA INTEGRAÇÃO=96.5%`.
- **STATUS DO PIPELINE**: `Integrados:1493` · `Com Médico:756` · `Sem Médico:712` · `Já Existiam:25` · `Pendentes:54`.
- **VOLUME POR DIA** (tabela): colunas `Data · Dia da Semana · Total · Integrados · Com Médico · Sem Médico · Pendentes · Taxa · Situação · Volume(barra ███)`. Uma linha por dia + TOTAL. Coluna `Situação` usa semáforo textual: `✅ Completo` / `⚠️ N pendentes`.
- **TOP ESPECIALIDADES**: `Especialidade · Total · % do Total · Integrados · Pendentes · Volume`. Ex.: Neurologia 302 (19,5%), Nutricionista 270, Cardiologia 189, Ortopedia 180, Psicologia 159, Neurologia Infantil 115, Endocrinologia 112, Urologia 65, Ginecologia 63, Gastroenterologia 56, Pediatria 24, Psiquiatria 12.
- **CAPITAL vs INTERIOR**: `Origem · Total · Integrados · Pendentes · % · Situação`. Neste arquivo: Capital (Manaus) 1547, Interior 0 municípios.
- **UNIDADES EXECUTORAS (CAPITAL)**: `Unidade · Total · % · Integrados · Volume`. Concentração forte em `AMBULATORIO VIRTUAL DO AMAZONAS` (889 = 57%) e `COMPLEXO REGULADOR DO AMAZONAS` (302 = 19,5%); resto pulverizado em policlínicas/CAICs.

**[INFERÊNCIA]** Esta aba é o "raio-x do dia" que o usuário olha primeiro: total a entregar, taxa de integração e onde estão as pendências (por dia, por especialidade, por unidade).

### Abas-dia (`HOJE 11-jun`, `12-jun`, `15-jun`, `16-jun`, `17-jun`, `18-jun`, `22-jun`, `24-jun`, `25-jun`, `26-jun`)

Uma aba por data com atendimento. Linha 0 = título ("12/06/2026 — sexta-feira — 469 agendamentos"); linha 1 = cabeçalho. **Colunas [LITERAL]** (15):

`Paciente · CPF · CNS · Telefone · Médico · Especialidade · Unid. Solicitante · Unid. Executora · Disponibilizado no SISReg · Capturado em · Integrado em · Atendimento em · Status · Substatus · Cód. Regulação`

Cada linha = **um agendamento de paciente**. Observações estruturais **[LITERAL]**:

- Coluna `CPF` vem vazia em todas as amostras (só `CNS` preenchido). Bom para privacidade.
- `Unid. Solicitante` aparece ora como **nome** (ex. "USF DEODATO DE MIRANDA LEAO"), ora como **código CNES numérico** (ex. "2015439") — formato inconsistente.
- Trilha de **timestamps**: `Disponibilizado no SISReg` (data) → `Capturado em` (datetime) → `Integrado em` (datetime) → `Atendimento em` (datetime do slot). Permite medir latência captura→integração.
- `Status` observado (distribuição agregada nas 10 abas): `Integrado` 1493 · `Revisão` 25 · `Pronto` 25 · `Dados faltando` 4.
- `Substatus` observado: `Com médico` 756 · `Sem médico` 712 · `(vazio)` 54 · `Já existia` 25.
- Quando `Integrado em` = `—`, o `Status` é `Pronto`/`Revisão` (ainda não integrado).

**Amostra resumida (anonimizada)** de uma aba-dia:

| Médico (iniciais) | Especialidade | Unid. Executora | Capturado→Integrado | Status / Substatus |
|---|---|---|---|---|
| R.C.A. | Neurologia | Ambulatório Virtual AM | 09/06 17:03 → 17:04 | Integrado / Sem médico |
| T.B.G. | Ortopedia | CAIMI Ada R. Viana | 29/05 00:11 → 31/05 19:29 | Integrado / Com médico |
| (—) | Ortopedia | Complexo Regulador AM | 10/06 22:54 → — | Revisão / (vazio) |

**[INFERÊNCIA]** Padrão visível: a aba `16-jun` está quase toda `Revisão`/`Pronto` (não integrada) e concentrada num único médico de Ortopedia — ou seja, **lote de uma agenda específica ainda travado**. A aba é onde o usuário "varre" linha a linha procurando o que está `Sem médico` ou não integrado para agir.

### O que cada aba controla (resumo)

- `Visão Geral` → **agregação gerencial**: saldo total, taxa de integração, demanda por especialidade/unidade, semáforo por dia.
- Abas-dia → **detalhe operacional por agendamento**: o caso a caso que alimenta os agregados e onde se identifica a exceção.

---

## 3. Evolução `06-09` → `06-11` (comparação)

| | `agenda-...-06-09` (gerada 09/06 10:09) | `agenda-...-06-11` (gerada 11/06 16:50) |
|---|---|---|
| Abas-dia | HOJE 09-jun, 10, 11, 12, 15, 17, 22, 24 | HOJE 11-jun, 12, 15, 16, 17, 18, 22, 24, 25, 26 |
| Total futuro | **947** | **1547** |
| Dias | 8 | 10 |
| Taxa integração | 99,5% | 96,5% |
| Com/Sem médico | 385 / 487 | 756 / 712 |

**[LITERAL]** o arquivo é **regenerado várias vezes ao dia** (vide os múltiplos arquivos `06-03 (1)`, `05-28 (1..3)` etc. na pasta). **[INFERÊNCIA]** A "agenda" é uma **fotografia descartável**: a cada export o usuário compara mentalmente com a anterior. O dia 11/06, que em 09/06 era previsão de 283, virou 432 reais — ou seja, **a demanda cresce entre exports** e o controle manual não tem histórico/diff: cada planilha é um snapshot solto.

---

## 4. `dashboard-30d-2026-06-02-2029.xlsx` (acompanhamento retrospectivo)

Exportado 02/06/2026. Eixo: data do agendamento, últimos 30 dias (03/05–02/06), `regulator_code=sisreg_am`. 4 abas.

### Aba `Dashboard` (funil) — 27 linhas

- **KPIs topo [LITERAL]**: `CAPTURADOS 5.448` · `INTEGRADOS 5.027 (92,3% sucesso)` · `RECUPERÁVEIS 1 (0,0%)` · `PERDIDOS 420 (7,7% irreversível)`.
- **FUNIL DE CONVERSÃO [LITERAL]** (`# · Etapa · Quantidade · % · Queda · Visual`), 8 etapas que descrevem o pipeline real do hub:
  1. Capturado do SISReg (.csv)
  2. Ficha ambulatorial capturada
  3. Ingestão no hub
  4. Dados do paciente OK (CADSUS)
  5. Doutor encontrado no Saúde AM
  6. Procedimento mapeado
  7. Unidade executora mapeada
  8. **INTEGRADO** (5.027 — queda de −421)
- **COMPOSIÇÃO DOS NÃO INTEGRADOS [LITERAL]**: Recuperáveis (pode resolver: destravar dados/mapear unidade) vs Perdidos (janela passou: agendamento expirou) vs Perdidos por falha permanente.

**[INFERÊNCIA]** Este funil é o **mapa de causas de falha** do hub: cada etapa é um ponto onde um agendamento pode "cair" (CADSUS não bate, médico não encontrado, procedimento/unidade não mapeados, ou a janela expira antes da integração).

### Aba `Realizados` — 5.031 linhas

Colunas **[LITERAL]** (19): `Paciente · CPF · CNS · Telefone · Nascimento · Médico · Especialidade · Modalidade · Disponibilizado no SISReg · Capturado em · Integrado em · Atendimento em · Cadastro do paciente · Médico vinculado · Como foi feito · Unidade execut. (CNES) · Unidade solic. (CNES) · ID no Saúde AM · Cód. regulação`.

Campos-chave novos vs a agenda **[LITERAL]**:
- `Modalidade`: `Remoto (teleconsulta)` ou `Presencial`.
- `Cadastro do paciente`: `Sim — hub cadastrou` / `Já existia no Saúde AM`.
- `Médico vinculado`: `Com vínculo` / `Sem vínculo (horário ocupado)`.
- `Como foi feito`: `Cadastrado e agendado` / `Agendado sem médico (horário ocupado)` / `Já existia no Saúde AM`.

**[INFERÊNCIA]** "Sem vínculo (horário ocupado)" = o slot do médico já estava cheio, então o hub criou o agendamento **sem amarrar a um médico** — é o mesmo "Sem médico" da agenda visto pelo retrovisor. Isso é um **sinal de capacidade/oferta estourada** por especialidade-horário.

### Aba `Recuperáveis` — poucos casos

Colunas incluem `Situação` (ex. "Aguardando revisão") e **`O que fazer`** (ação textual, ex. "Verificar os dados de cadastro deste paciente"). **[INFERÊNCIA]** É a **fila de trabalho** do operador: casos ainda dentro da janela que ele consegue salvar manualmente.

### Aba `Perdidos` — 424 linhas (420 casos)

Colunas: `... Situação · Motivo · Tentativas · Nota da resolução · Unid. solic. · Unid. execut.`. **[LITERAL]** Motivo dominante: "Janela de envio expirou" (`Situação=Janela perdida`), com `Tentativas` de 2 a 15. **[INFERÊNCIA]** Evidência histórica de perda: 420/5448 ≈ 7,7% dos agendamentos do mês não chegaram a ser integrados a tempo — **a principal dor mensurável**.

---

## 5. `Macro Planejamento e GAP Analysis - Edital HC-SP_v1.xlsx` (contexto, não-operacional)

1 aba (`Sheet1`), ~995 linhas. **[LITERAL]** É uma **matriz de planejamento de proposta** para o edital HC-SP / plataforma e-saúdeSP, não um controle operacional.

- Bloco 1 (linhas 1–8): **Macro Etapas × cronograma** (`Mês 0 … Mês 7-12`) com `Faturamento` por marco (Kick-off 0,75%, Integração 5,5%, Homologação 13,75% etc.). Etapas: qualificação → plano de trabalho/kick-off → recebimento base cadastro → tratamento base/novos pacientes → integração de sistemas → homologação → operação.
- Bloco 2 (linha 10 em diante): **Itens do TR (Termo de Referência)** com colunas `# · Item TR - Objeto · Envolvidos · Status · Incerteza · Observações · (cronograma) · Faturamento`. `Status` classifica cada requisito como `GAP`, `GAP com Alternativa`, `Default TD+TC`, `Default Demandas Médicas`, `Default Dados`, `NA`. `Incerteza` = Alta/Média/Baixa.

**[INFERÊNCIA]** Relevância para o projeto: mostra o **vocabulário e o modelo de negócio alvo** — agendamento de especialidades com confirmação automatizada, SLA agendamento→atendimento de **15 dias** (item 2.6.1.1.7), plantões mín. 4h e até **3 consultas/hora/especialista** (2.6.1.1.8), triagem Manchester com TME ~7min. Esses números são **parâmetros de capacidade/SLA** que o sistema "Demandas" precisará modelar. Não há dados pessoais nesta planilha.

---

## 6. Mapa do processo manual atual (inferido)

**Quem preenche:** **[INFERÊNCIA]** o operador **não digita** os dados clínicos — eles vêm do hub/SISReg. O trabalho manual é: (a) **exportar** a planilha do hub várias vezes ao dia; (b) **ler** os painéis e varrer as abas-dia; (c) **agir** sobre exceções; (d) eventualmente **anotar** ações (colunas "O que fazer"/"Nota da resolução" no dashboard).

Ordem típica de uso **[INFERÊNCIA]**:

1. **Exportar `agenda-operacional`** → abrir `Visão Geral` → ler total futuro, taxa de integração e o **semáforo por dia** (`⚠️ N pendentes`).
2. Para cada dia com `⚠️`, abrir a **aba-dia** e filtrar visualmente linhas `Status≠Integrado` ou `Substatus=Sem médico`.
3. Cruzar com **TOP ESPECIALIDADES / UNIDADES EXECUTORAS** para entender se a pendência é concentrada (uma especialidade/um médico/uma agenda travada).
4. Periodicamente **exportar `dashboard-30d`** → conferir o **funil** (onde estão caindo) e trabalhar a aba **`Recuperáveis`** (fila de ação) antes que virem **`Perdidos`** (janela expira).
5. Repetir o ciclo no próximo export (sem diff automático entre snapshots).

**O que efetivamente se controla:**

| Dimensão | Onde aparece | Tipo |
|---|---|---|
| **Demanda** (volume de agendamentos por dia, especialidade, unidade, capital/interior) | `Visão Geral` blocos VOLUME/TOP ESPECIALIDADES/UNIDADES | agregado |
| **Capacidade/oferta de médico** | `Substatus=Sem médico` e `Médico vinculado=Sem vínculo (horário ocupado)` | indireto/proxy |
| **Agenda** (slot, data/hora de atendimento) | abas-dia, coluna `Atendimento em` | detalhe |
| **Saldo / pendência** | `Pendentes` por dia, funil, Recuperáveis vs Perdidos | exceção |
| **Latência** (captura→integração) | timestamps `Capturado em`/`Integrado em` | derivável (não calculado na planilha) |

### Dores e erros do controle manual

1. **[INFERÊNCIA]** **Snapshots descartáveis, sem histórico/diff.** Dezenas de arquivos `(1)(2)(3)` na pasta; a demanda muda entre exports (947→1547 em 2 dias) e não há trilha — o operador compara de cabeça.
2. **[INFERÊNCIA]** **Capacidade do médico só visível por consequência.** "Sem médico / horário ocupado" só aparece **depois** que o slot estourou; não há visão prévia de oferta vs demanda por especialidade-horário (o gap que o módulo Demanda do projeto resolve com "Simular saldo").
3. **[LITERAL→INFERÊNCIA]** **Perda por janela expirada** = 7,7%/mês (420 casos), com até 15 tentativas registradas. É a falha mais cara e é **reativa**: só dá para ver no dashboard depois de perdido.
4. **[LITERAL]** **Inconsistência de cadastro de unidade solicitante** (ora nome, ora CNES numérico) → dificulta agrupar/conferir.
5. **[INFERÊNCIA]** **Triagem manual de exceções** (varrer centenas de linhas por dia procurando `Sem médico`/`Revisão`) — trabalhoso e sujeito a passar caso batido.
6. **[INFERÊNCIA]** **Dados pessoais de paciente (CNS, telefone, nascimento) trafegando em planilha Excel local** — risco LGPD inerente ao controle por arquivo (alinhado às restrições transversais de `01-domain-overview.md`).

---

## 7. Como o sistema "Saúde Digital · Demandas" substitui cada etapa

Mapeando o pipeline do projeto (`oferta → demanda → alocação → agendamento → teleconsulta`) sobre o que o Excel faz hoje:

| Etapa hoje no Excel (manual) | Etapa no sistema | Como substitui |
|---|---|---|
| Olhar `Substatus=Sem médico` / `Sem vínculo (horário ocupado)` **depois** do estouro | **① Oferta** (escala fixa do médico: dias, horário, consultas/hora) | Capacidade vira **estoque calculado antes**, não consequência observada a posteriori. |
| `TOP ESPECIALIDADES` + `VOLUME POR DIA` lidos em painel estático | **② Demanda** (solicitação por especialidade/período) | Demanda passa a ser **entidade do sistema**, não agregado de export. |
| Comparar mentalmente snapshots `(1)(2)(3)`; "Sem médico" como sinal de estouro | **③ Alocação** ("Simular" demanda × estoque → saldo +/-) | **Saldo calculado em tempo real**; flag de vaga >30 dias; reserva baixa estoque. Elimina o diff manual. |
| Aba-dia com `Atendimento em`, `Status`, `Substatus`; pendências varridas à mão | **⑤ Agendamento** (médico+paciente+especialidade+HC) | Agendamento é estado consultável e filtrável, não linha de planilha; "Sem médico" vira regra de alocação, não exceção manual. |
| `Recuperáveis` (coluna "O que fazer") trabalhada antes de expirar; `Perdidos` (7,7%) | **Fila de exceções + SLA** (SLA edital = 15 dias agendamento→atendimento) | Casos recuperáveis viram **workflow com alerta antes da janela**, reduzindo perda por expiração. |
| Funil do `dashboard-30d` e KPIs montados por export | **Métricas nativas** (taxa de integração, latência, perdas) | Painel do sistema substitui o export de acompanhamento; latência (hoje só derivável) passa a ser medida. |
| Planilha local com CNS/telefone/nascimento | **Dados em sistema com base legal/auditoria** | Tira dado sensível do Excel local (mitiga risco LGPD apontado no domínio). |

**Resumo:** o Excel hoje é a **camada de visibilidade e triagem de exceções** por cima de um hub de integração. O sistema "Demandas" internaliza essa camada e — crucialmente — **antecipa** o que hoje só é visto depois do fato (capacidade estourada, janela perdida), convertendo monitoramento reativo em alocação proativa com saldo e SLA.

---

## 8. Itens a confirmar (não inferir)

- ❓ O "REGULA-HUB / hub" das planilhas é o mesmo sistema do projeto ou um produto anterior do AM? (Vocabulário coincide, mas é **outro cliente/contexto** — AM/SISReg vs HC-SP/e-saúdeSP.)
- ❓ Quem faz o export e com que frequência (parece manual e várias vezes/dia).
- ❓ A "janela de envio" que expira (causa de 7,7% de perda) — qual a regra de prazo e por que casos chegam a 15 tentativas?
- ❓ As planilhas são geradas pelo próprio hub (export pronto) ou montadas pelo usuário? **[INFERÊNCIA forte]**: geradas pelo hub (barras `███`, semáforos e textos prontos sugerem template automatizado).
