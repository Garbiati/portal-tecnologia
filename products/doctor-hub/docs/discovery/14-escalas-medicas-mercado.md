# Discovery — Dores e padrões de sistemas de escala médica (pesquisa de mercado)

> **Fonte:** agente de pesquisa, madrugada 2026-07-05 (missão autorizada pelo Alessandro:
> "rode um agent de pesquisa sobre escalas médicas, entenda as realidades e dores"). 11/12
> afirmações decisivas confirmadas em fonte primária. Status: DISCOVERY — orienta a spec da
> escala, mas nada vira código sem decisão registrada. Base do requisito "escala FÁCIL de criar".

## Contexto do pedido (Alessandro)
"O doutor atende seg 8–14, ter 10–18, folga na 2ª semana do mês; às vezes na segunda vai até 18h,
e algumas quintas no mês. A agenda dele NÃO é CLT — é fixa e difícil de mudar; ele sempre atende
nessas condições. O sistema tem que registrar isso **fácil**." + visão de assistente de IA (texto/voz)
que "conversa e cria a escala".

## Como o mercado resolve (o que copiar)

### Padrão vencedor: REGRA SEMANAL + OVERRIDE POR DATA
- Calendly/Zocdoc/SimplePractice: grade semanal com múltiplos blocos por dia (seg 8–14, ter 10–18)
  + **"horário específico por data"** que SUBSTITUI a semana naquele dia. **Um só mecanismo cobre
  folga pontual E extensão** ("segunda até 18h", "quinta X"). É o padrão que o médico já conhece.
- ⚠️ Dor conhecida: overrides "somem"/ficam invisíveis (Calendly) → **a lista de exceções ativas
  precisa ser SEMPRE visível**.

### "2ª semana do mês" ≠ "quinzenal"
- Nem Google nem Outlook fazem "2ª e 4ª semana" numa série única (workaround = 2 séries).
- Quinzenal (INTERVAL=2 ancorado na data de início) DIVERGE de "2ª semana do mês" em meses de 5
  semanas. → **a UI deve DESAMBIGUAR mostrando as próximas datas geradas** (nossa semântica atual
  D-152 = n-ésima ocorrência do dia; PROVISÓRIO — o preview vai deixar isso explícito).

### Arquitetura de dados de consenso
- Guardar a REGRA (estilo Fowler: expressões temporais Union/Intersection/**Difference** —
  "toda segunda EXCETO 2ª semana do mês") + **materializar instâncias** num horizonte (3–6 meses)
  + tabela de EXCEÇÕES por instância + edição no trio universal **"só este dia / este e os
  seguintes / toda a série"**. Swaps e extensões operam na INSTÂNCIA, nunca na regra.
- Ninguém expõe RRULE cru ao usuário. Trocas de plantão: 3 verbos (devolver ao pool / dar a colega
  / trocar) com aprovação configurável.

## Players e reclamações (o que EVITAR)
- **QGenda** (líder EUA): automação quebra com regras complexas ("corrige uma, outra quebra");
  mudança de regra passa por CHAMADO no suporte (não self-service); **sem trilha de auditoria** de
  quem mudou a escala; app mobile bugado.
- **Lightning Bolt/PerfectServe**: rules engine potente (400+ regras/cliente) mas "audit trail is
  terrible", regras quebrando, curva íngreme.
- **Amion**: UX legada, um editor por vez, app com crash.
- **Brasil**: Escala Plantões (Einstein) nota **2,3/5** (app lento, escala demora dias p/ atualizar);
  Pega Plantão 4,9/5 mas trava. **No BR o jogo é confiabilidade/velocidade do app, não features.**
- **Dores universais**: (a) motor de regras que quebra na realidade complexa; (b) app mobile ruim;
  (c) suporte que degrada pós-venda; (d) sem auditoria de escala; (e) automação caixa-preta mata adoção.

## Falta do médico ("bump" / provider no-show)
- Benchmark Vizient: **4,9%** das consultas (faixa 0,7–12,4%). Auditoria UK: causa nº1 = **escala
  não sincronizada com o agendamento** → integrar escala↔agendamento É a prevenção (é o que fazemos).
- **Só a Teladoc trata como fluxo de produto**: "tentamos conectar você ao próximo profissional
  disponível ANTES de cancelar" — realocação automática + nova notificação. (valida a ideia do
  "doutor de plantão da operação".)
- Float pool: match por competência+disponibilidade+compliance; em telemedicina, realocar só na
  MESMA especialidade. Reencaixe: waitlist com oferta automática (SMS/WhatsApp), expira em ~30 min.
- BR: canal é **WhatsApp** (confirmar/reagendar em 1 clique).

## Continuidade (psiquiatria/psicologia — valida a regra do Alessandro)
- Trocar de terapeuta **multiplica dropout: OR 4,59** (40,4% vs 7,1%). Maior continuidade em saúde
  mental → menos hospitalização e menor mortalidade.
- Mercado (Talkspace/BetterHelp): vínculo "sticky by default" — mesmo profissional; troca só por
  iniciativa do PACIENTE; troca involuntária exige explicação.
- Modelagem: vínculo longitudinal (FHIR **CareTeam**) SEPARADO da consulta (Encounter); o scheduler
  consulta o vínculo p/ preferir o mesmo profissional. Métrica pronta: **UPC** (% consultas do
  paciente com o profissional vinculado) — quase ninguém exibe = diferencial.

## IA/voz para criar escala (espaço ABERTO)
- **Ninguém no nicho médico** tem NL para criar/editar escala. Melhor caso é fora da saúde
  (Legion WFM, varejo).
- Arquitetura vencedora: **LLM interpreta/extrai → motor DETERMINÍSTICO gera → humano aprova**
  (SMILO: 90% de acerto vs LLM direto). Por que auto-scheduling falha: regras reais são "tácitas,
  informais, politizadas" (Drake 2014) → só há adoção com transparência + humano decidindo por último.
- **Recomendação:** o assistente de IA do doc hub deve ser INTÉRPRETE de disponibilidade, não
  gerador cego: "atendo seg 8–14, ter 10–18, folgo 2ª semana" → propõe a regra → **mostra preview de
  datas** → humano confirma → motor gera. Não existe produto comercial fazendo isso = diferenciação.

## 10 recomendações acionáveis (por impacto/esforço)
1. **Regra semanal + override por data** (um mecanismo p/ folga E extensão). Alto impacto, baixo esforço.
2. **Preview das próximas datas antes de salvar** qualquer recorrência. Defesa mais barata contra
   regra errada em prod. Alto/baixo.
3. **Regra materializa ocorrências; edição opera na ocorrência** (trio "só este / e os seguintes /
   sempre"). Decisão de arquitetura de dia 1 (barata agora, cara depois).
4. **Vínculo paciente-médico de 1ª classe** (FHIR CareTeam) + flag de continuidade por especialidade.
5. **Trilha de auditoria de escala desde o dia 1** (já temos auditoria — estender à escala). Reclamação
   literal contra os líderes.
6. **Falta do médico como EVENTO de sistema** (modelo Teladoc): realoca 1º atendimento / mantém
   médico no retorno de continuidade / notifica com reagendamento 1-clique / meta <30 min.
7. **Notificação e reagendamento via WhatsApp** (mínimo dado clínico — LGPD).
8. **Dashboard mínimo**: bump rate por médico (bench 4,9%), aderência (atendido÷escalado), fill rate,
   **UPC** (continuidade). Registrar motivo do bump numa taxonomia curta.
9. **Trocas com 3 verbos** (devolver/dar/trocar) com aprovação — fase 2.
10. **IA como intérprete de disponibilidade** (não gerador). Ataca o gargalo real; diferenciação. Voz
    = aposta exploratória.

**Anti-padrões (lições pagas pelos incumbentes):** expor RRULE ao médico; auto-scheduling caixa-preta;
regra editável só via suporte; app mobile de 2ª classe; prometer automação que quebra em regra
complexa (melhor cobrir 100% do simples com override fácil que 80% do complexo com regra frágil).

## Fontes principais
Calendly/Zocdoc/SimplePractice availability docs · Fowler "Recurring Events" (martinfowler.com/apsupp/recurring.pdf) ·
Vizient CPSC · Teladoc help center · QGenda/Lightning Bolt reviews (Capterra/KLAS) · Escala Plantões/Pega Plantão
(App Store BR) · PMC5480417 (dropout terapeuta OR 4,59) · FHIR CareTeam · SMILO (arxiv 2511.02364) · Drake 2014 (PubMed 23991714).
