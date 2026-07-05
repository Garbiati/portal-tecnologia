# Escala avançada, Indisponibilidade e Plantão de Reposição — anotações da sessão de Figma

> **Fonte:** anotações do Alessandro na sessão de validação do Figma com stakeholders (registradas
> em 2026-07-04). **Status: DISCOVERY** — nada aqui vira código sem spec aprovada (SDD). O que está
> marcado ✅ foi dito textualmente; o que está marcado ❓ é pergunta aberta (Diretriz Suprema: não
> inferir). Perguntas também listadas em [`03-open-questions.md`](03-open-questions.md).

---

## 1. Renomeação de papéis (rótulos) ✅

Anotado: **"Gestor Geral → Regulação"** (já era o D-139) e **"Gestor Regional → Supervisor"**
(**novo** — o D-139 tinha renomeado para "Gestor"; agora o rótulo passa a ser **Supervisor**).
Registrado como **D-144**. Coerente com o uso na anotação do plantão ("não fica disponível para
os **supervisores** assumir").

❓ Alcance da renomeação: assumido **rótulo de exibição** (seletor de jornada, chip de persona,
textos). A **chave técnica** do client role (`gestor` no Keycloak) fica como está até decisão
específica (migração de role em prod tem custo; rótulo não).

## 2. Escala fixa com variação por dia e por semana ✅ (novas capacidades)

Anotações textuais:
- "A escala fixa pode ter **horários diferentes em dias diferentes**" — ex.: *"segunda eu atendo
  das 8 às 15h, terça eu atendo das 11h até 16h"*.
- "Pode ter **diferenças entre semanas**" — ex.: *"na segunda semana do mês eu não atendo"*.
- "Existem médicos que atendem de forma **quinzenal**."
- "Tem médicos que precisam estar **indisponíveis num dia específico** do próximo mês ou semana."

**O que a SPEC-MEDICOS-ESCALA v2 (specified, D-120..D-123) já cobre:** dias da semana com 1..N
blocos de horário, vigência, FIXA contínua + FLEX pontual somando capacidade, invariante de não
sobreposição (INV-1).

**O que é NOVO (não coberto pela v2):**
| Capacidade | Exemplo anotado | Observação |
|---|---|---|
| Blocos **por dia** da semana | seg 08–15 · ter 11–16 | v2 tem blocos "no dia", não fica claro se por-dia; precisa entrar explícito no modelo |
| Exceção por **semana do mês** | "2ª semana do mês não atendo" | ❓ "2ª semana" = semana-calendário (dias 8–14) ou 2ª ocorrência do dia (2ª segunda-feira)? |
| Recorrência **quinzenal** | atende semana sim, semana não | ❓ ancorada em quê (data de início? semana par/ímpar?) |
| **Indisponibilidade pontual futura** | "dia X do próximo mês não atendo" | vira o item 3 abaixo |

## 3. Funcionalidade: Indisponibilidade do médico ✅ (regras anotadas)

Quando o médico fica indisponível numa faixa que já tem compromissos:

**Se tem AGENDAMENTO (paciente marcado):**
- **Primeira consulta** → "jogar para a **fila/pool** e habilita, se necessário, **alocar um novo
  especialista**".
- **Retorno** → "sistema **aloca de forma automática** para a **próxima escala de reposição deste
  doutor**, **cancelando e notificando** o antigo com o novo" (retorno mantém o MESMO doutor).

**Se tem só SLOTS (sem paciente):** "remove o doutor da disponibilidade daquela faixa de horário."

❓ Perguntas abertas (bloqueiam a spec):
1. **Fila/pool**: onde vive essa fila? (é a Disponibilização/pool que o Supervisor assume — tela
   `/assuncao` — ou uma fila nova de reagendamento?) Quem é notificado?
2. "habilita **se necessário** alocar novo especialista" — quem decide o "se necessário"
   (automático por regra? ação humana de quem — Demandas? Regulação?)
3. **Retorno**: se o doutor NÃO tem plantão de reposição futuro, o que acontece? (fila? alerta?)
4. **Notificações**: notifica quem (paciente? unidade/supervisor?) e por qual canal (a integração
   de agendamento é via Teleconsulta — POST /integration/appointment; o cancelamento/reagendamento
   tem API correspondente na TC? — dependência externa a confirmar)
5. Indisponibilidade tem **motivo/tipo** (férias, atestado, pontual)? Precisa de aprovação de
   alguém ou o próprio Demandas registra?

## 4. Funcionalidade: Plantão de Reposição ✅ (conceito anotado)

> "Uma **escala especial** que **não fica disponível para os supervisores assumir**, e que **só é
> possível vincular pacientes que tiveram um reagendamento** (analisar a regra)."

- É a "escala de reposição" citada no fluxo de retorno do item 3.
- ❓ **"analisar a regra"** (marcado pelo próprio Alessandro): critérios exatos de quem pode ser
  vinculado (só reagendos do PRÓPRIO doutor? qualquer reagendado da especialidade?), quem enxerga
  esse plantão, se ele conta no estoque/capacidade (D-005/D-111/D-112) e como aparece no cockpit.

## 5. Contexto estratégico (para o roadmap) ✅

- O Doctor-Hub **substitui um sistema hoje operado por um TERCEIRO** que "monta escalas e integra
  no portal telemedicina". Trabalharemos **extraindo de sistemas existentes**.
- Visão societária: **Portal Tecnologia** nasce da Portal Telemedicina para cuidar de inovação e
  tecnologia médica (certificações de órgãos reguladores, responsabilidade do uso de tecnologia na
  medicina). **Portal Telemedicina = medicina; Portal Tecnologia = capacidade técnica aos médicos
  (humanos ou agents)** para exponenciar o alcance.
- Sem ambiente de homologação/desenvolvimento: **dev local usa o IdP de PROD** (I-006) + Postgres
  local; o restante (API/front) roda local.

## 5b. Status das perguntas (2026-07-05, madrugada — respostas do Alessandro no app)

Perguntadas antes da noite de construção; TODAS respondidas como **"depois"**:
recorrência avançada ("depois eu explico"), fila da 1ª consulta ("depois vemos"),
retorno sem plantão futuro ("depois vemos"), vínculo do plantão de reposição ("analisar depois" —
mas com aval explícito: *criar o plantão não-assumível pelo Supervisor SEM vínculo por ora*).

**Consequência (escopo da noite):** construir só o TEXTUAL — (a) escala fixa com horários POR DIA;
(b) indisponibilidade: cadastro + efeito "remove da disponibilidade" (slots sem paciente);
(c) plantão de reposição: flag na escala, fora da assunção do Supervisor, sem vínculo de paciente.
Recorrência quinzenal/semana-do-mês e os fluxos com paciente ficam BLOQUEADOS até as respostas.

### Perguntas novas (agente da onda 2 — painel/tipos):
- Escala dedicada a projeto deve RESERVAR capacidade (descontar do pool nas solicitações) ou é rótulo por ora?
- Tipo de serviço muda cálculo/validação (laudo exige faturamento de laudo? plantão muda vagas)?
- Tipo/projeto podem ser EDITADOS numa escala existente?
- Período canônico do painel real (mês corrente?) — hoje herda o PERIODO_DEMO (junho/2026).
- Cliente desativado com escalas apontando pra ele: como exibir?

## 6. Próximos passos combinados

1. Adiantar **tudo que der local** (sem tocar na GCP nova): backend da escala v2 (spec já
   aprovada), telas do Figma em modo funcional com fixture onde a regra ainda não fechou.
2. Alessandro vai **detalhar as regras** ("depois explico") → responder as ❓ acima → spec v3
   (recorrência avançada + indisponibilidade + plantão de reposição) → só então codificar essas regras.
