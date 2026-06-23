# Entrega 1 enxuta + Intenção do que foi para o futuro (D-087, 2026-06-18)

> O Alessandro reduziu o escopo da 1ª entrega. Este doc **guarda a intenção** do que foi movido p/ entrega futura
> (as telas saíram do protótipo Figma, mas o conceito fica registrado aqui — nada se perde).

## ✅ Entrega 1 (foco atual)
- **Gestão de Médicos:** cadastro-dono (dados + CPF + nascimento + especialidades/RQE) + **faturamento por produto**
  (Teleconsulta: por especialidade, modo hora/consulta + valor + tempo; Telediagnóstico: por laudo por tipo de exame)
  — D-085/D-086. Estados: ver/editar/incompleto/inativo/confirmações. Inativar/reativar. Histórico/LGPD. Provisionamento.
- **Escala:** localizar, criar (+validações), ativo, arquivar/reativar, histórico, modais (timeline, horas adicionais).
- **Conta:** perfil + configurações.
- **Landing pós-Login:** Médicos · Localizar.

## 🔮 Entrega FUTURA — intenção preservada (telas deletadas do protótipo)

### A. Visão geral / Cockpit C-level (era D-082/D-083/D-084)
- **Capacidade de entrega:** herói duplo (médicos ativos + capacidade de atendimento), **fatiável por especialidade ×
  dia × duração** (a "tabela de disponibilidade": _"quantas consultas de 20 min de Cardiologia na terça"_), seletor de
  **janela temporal** (hoje/fim do dia/semana/fim do mês), funil **instalada · ativada · ociosa · travada**, taxa de
  ativação. **Sem demanda inventada** — só a NOSSA capacidade (a demanda vem por estado×especialidade em fases futuras, D-083).
- **Projeção de capacidade:** slots/semana das próximas semanas pelas **vigências** das escalas (cai quando vence sem renovar).
- **Pool por especialidade** (ociosos/incompletos) + **Saneamento** de cadastros incompletos.
- **Home/manchete** de ação + KPIs executivos.

### B. Relatório (era D-079/D-080)
- **Relatório de escalas:** grade Especialidade → Médico × faixas de horário (planejamento, dia-a-dia).
- **Capacidade / heatmap:** atendimentos previstos por hora (capacidade = slots da escala), filtros (especialidade/
  médico/janela/granularidade), painel **"Foto"** reativo, 24h com madrugada colapsada, drills (especialidade/médico/horário).
- **Cobertura por período:** Hoje / Amanhã / Semana / Até fim do mês.

## Fontes (a intenção detalhada vive aqui)
Decisões D-079, D-080, D-081, D-082, D-083, D-084 (`decisions-log.md`) + `docs/product/15-overnight-*`, `16-overnight-*`,
`17-capacidade-de-entrega-conceito.md`. **Quando a entrega futura começar, reconstruir a partir daqui** (com o recálculo
de capacidade já derivando do **tempo de atendimento por especialidade**, D-085 — a cascata que ficou flagueada).
