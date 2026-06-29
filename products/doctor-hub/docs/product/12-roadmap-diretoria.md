# Roadmap da Diretoria — 4 fases (2026-06-15)

> Fonte: 4 diagramas apresentados/validados na diretoria em 2026-06-15 (FigJam, prints em
> `~/Pictures/Screenshots/`). Decisões: **D-052** (roadmap + 1ª entrega = Fase 1) e **D-053** (escala fixa+adicional).
> **A 1ª ENTREGA é a FASE 1 (Escala médica).** As fases seguintes vêm na sequência.

## Fase 1 — Escala médica  ⬅ **1ª ENTREGA**
**Perfil:** Demandas médicas.
**Fluxo:** Demandas busca o doutor na Teleconsulta → cria a **escala fixa** → o sistema **calcula a
capacidade de atendimento por especialidade**.
**Habilita:**
1. **Previsibilidade** da capacidade médica (gráficos de evolução com base no histórico).
2. **Cadastro do doutor** no nosso sistema: CRM, RQE, endereço, contato; **início do modelo de
   faturamento** (valor/hora ou /consulta).
**Modelo de escala (D-053):** disponibilidade = **escala FIXA + escala ADICIONAL**.
- **Fixa**: baseline previsível (dias × períodos × duração → vagas/mês). Ex.: Dr. João, Pediatra,
  seg–sex 08–12 e 13–18, consulta 20 min → X vagas/mês.
- **Adicional**: disponibilidade **excepcional por DIA específico** (datada) + período extra
  (ex.: a fixa vai até 17h, mas hoje até 22h), **sem mexer na fixa** — cobre **faltas/lacunas**.
- **Capacidade do dia = fixa + adicional**; a **previsibilidade usa só a fixa** (adicional = extra pontual).
- **Faturamento:** a **hora adicional tem TAXA PRÓPRIA** (distinta da fixa).

## Fase 2 — Solicitações de especialidades
**Perfil:** Gestor do HC + Demandas médicas.
**Fluxo:** Gestor do HC solicita, para um período, a quantidade por especialidade → Demandas analisa a
necessidade de cada health_center e **disponibiliza** (pool).
**Habilita:** autonomia do gestor p/ solicitar (com fluxo de aprovação); visibilidade/controle da
quantidade disponibilizada por HC; histórico de "quantos especialistas contratar" por cliente.
_(Mapeia D-031/D-032/D-035/D-043/D-045 — já construído no protótipo.)_

## Fase 3 — Agendamento
**Perfil:** Gestor (vinculado a um gestor de HC).
**Fluxo:** o regional separa uma quantidade de slots p/ sua unidade e faz o **agendamento
(paciente + doutor)**; Demandas/Gestor HC têm visão e podem aprovar/reprovar/solicitar alteração.
**Habilita:** autonomia local p/ agendar; **integração com a Teleconsulta** (baixa do agendamento);
visibilidade real-time da alocação. (Aprovação semanal/diária; notificação via WhatsApp citada.)
_(Mapeia D-029/D-034/D-042/D-044 — já construído no protótipo.)_

## Fase 4 — Remanejamento
**Perfil:** Demandas médicas.
**Fluxo:** slots vagos nas próximas **48h** são habilitados p/ remanejamento; Demandas realoca; ao
remanejar, **ambos os gestores de health_centers são notificados**.
**Habilita:** otimização (evitar desperdício de slots ociosos); refinamento das demandas por histórico;
no futuro, **remanejamento automático via LLM/motor de IA** por indicadores e regras.
_(Mapeia D-013/D-047 — parcialmente construído.)_

## Impacto no que já existe
O protótipo já tem a Escala (Fase 1) **e** boa parte das Fases 2–4 (pool, reserva, agendamento). Tudo
segue válido; só **a 1ª entrega foca a Fase 1**. **Lacunas da Fase 1 a completar:**
- [ ] **Escala adicional** (datada, por dia + período, com taxa própria) — conceito NOVO (D-053).
- [ ] **Cadastro do doutor**: CRM, RQE, endereço/contato, **valores** (hora/consulta) fixo + adicional.
- [ ] **Visão de capacidade/previsibilidade por especialidade** (vagas/mês, evolução) — baseline = fixa.

## Perguntas abertas (Fase 1)
- 🟡 Faturamento: além da "taxa própria da hora adicional", qual a regra de cobrança (ainda só cadastrar valores na v1 — D-053).
- 🟡 Feriados na fórmula de capacidade (ver `03-open-questions`).
- 🟡 Onboarding médico: lançar horas no onboarding p/ que doutores atuais e novos passem sempre pela plataforma (nota dos diagramas) — detalhar.
