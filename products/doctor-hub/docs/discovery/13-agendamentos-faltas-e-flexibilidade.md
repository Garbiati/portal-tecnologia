# Agendamentos, faltas do doutor e escala flexível — braindump do Alessandro (2026-07-05, 02h29)

> **Fonte:** mensagem do Alessandro antes de dormir. Status: DISCOVERY + algumas regras JÁ
> UTILIZÁVEIS (marcadas ✅). O que depende de spec/integração está ❓/🔜.

## 1. Escala tem que refletir a REALIDADE do doutor (não-CLT) ✅ requisito
Exemplo canônico (do Alessandro): *"atende segunda 8–14, terça 10–18; na 2ª semana do mês não
trabalha; o resto atende nesses horários; tem vezes que na segunda trabalha 8–18; e algumas
quintas no mês."* → o sistema precisa registrar **esse nível de complexidade ou pior, FÁCIL**.
- Horários por dia ✅ (entregue 2026-07-05).
- **Exceção por semana do mês** ("2ª semana não trabalho") → ENTRA AGORA (D-152).
  ⚠️ PROVISÓRIO: interpretada como **n-ésima ocorrência do dia no mês** (padrão de calendários;
  ex.: 2ª semana = 2ª segunda, 2ª terça…). Confirmar com o Alessandro.
- **Extensões pontuais** ("às vezes segunda 8–18, algumas quintas") = papel da **FLEX**
  (adição pontual sobre a FIXA). D-151 segue: FLEX não ganha recurso novo, mas fica claro
  que o PAPEL dela é esse. Quinzenal: ainda ❓ (ancoragem).

## 2. Falta do doutor — o que fazer com os agendamentos ✅ regras dadas
- **1º atendimento** → redistribui para outros doutores. Ideia: **1 doutor "de plantão da
  operação"** por turno que absorve agendamentos de faltosos. ❓ como escala/remunera esse plantão.
- **RETORNO de especialidade de CONTINUIDADE (psiquiatria, psicologia, "entre outras")** →
  **NUNCA troca de médico**; remarcar com o MESMO doutor é melhor que trocar. ❓ lista exata de
  especialidades de continuidade (catálogo com flag `continuidade`?).
- **Escala de ENCAIXE** ✅: doutor faltou → cria escala para reatender os pacientes penalizados
  (retornos cancelados dele). É a materialização do "plantão de reposição" (flag já existe).
- **Mensagem ao paciente DIFERENCIADA** no cancelamento por falta: "o doutor teve um imprevisto;
  vamos reagendar com PRIORIDADE MÁXIMA com esse doutor; em breve entraremos em contato."
  🔜 depende do canal de notificação (Teleconsulta/SMS) — ainda não integrado.

## 3. Métricas/gestão de cancelamentos ✅ direção dada
- Marcar doutores que cancelaram agendamentos; **ranking dos que menos cancelam**; métricas de
  aderência ("quais atendem dentro do previsto"). → alimenta o painel (fase discovery).

## 4. Usabilidade com IA 🔜 visão
- **Assistente de escala** (texto/áudio): "fala" a escala do doutor e o sistema cria.
- **Chat de ajuda no sistema**: "como eu crio uma escala?" → explica e executa.
- Requisito de plataforma: web + mobile sempre.

## 5. Discovery agendada (agents da madrugada 05/07)
- Pesquisa: dores/padrões de sistemas de escala médica do mercado.
- Discovery: mitigação de cancelamento de última hora + ranking/métricas.
