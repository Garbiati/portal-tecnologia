# Roteiro de demonstração — Diretoria (~10 min)

> Guia para apresentar o doc hub à Diretoria. Dados REAIS (cenário semeado por
> `infrastructure/scripts/seed-demo-diretoria.py`). Fluxo do posicionamento (D-155) ao valor
> (déficit/previsibilidade). Login: **Alessandro** (CPF `35922911813`, tem os 4 papéis → vê tudo).

## Antes de começar (checklist)
- [ ] `min-instances=1` nos 3 serviços (sem cold start) — reverter depois (P-010).
- [ ] Cenário semeado presente (rodar o seed se tiver resetado).
- [ ] Smoke: `/` (landing) · `/app` (login) · id/api 200.
- [ ] Tema (claro/escuro) à escolha; mobile ou desktop.

## Roteiro

**1. A abertura — o produto (1 min).** Abra **doctorhub.app.br**. É a **landing**: "Capacidade médica
no lugar certo, na hora certa." Fale o posicionamento — sistema que faz a **gestão e a distribuição da
capacidade médica**, público ou privado. Aponte a **faixa de segurança** (LGPD/CFM/RBAC) e o **case
Portal Telemedicina**. (1 tela = a Diretoria entende o que é e por que é confiável.)

**2. Entrar (30s).** "Entrar" → `/app` → login (CPF/senha; mencione que aceita passkey/Face ID). Note
a **marca consistente** (login = e-mail = app).

**3. Clientes & Projetos (1 min).** Mostre os **projetos reais** (Piauí Saúde Digital, Saúde Am…). O
doc hub é **multi-cliente** (público/privado) — a base do white-label. Cada usuário só vê o seu (RBAC).

**4. Base médica (1 min).** Médicos → **4.523 médicos reais** cadastrados. É a matéria-prima da
capacidade. (Mencione: importação/sync da base — sem integrar a Teleconsulta nesta fase.)

**5. Escala real, do jeito do médico (2 min) — o "isso é difícil e a gente resolve".** Abra um médico →
Escala. Mostre uma FIXA com **horários por dia** (seg 8–14, ter 10–18) e **exceção de semana do mês**
("folga na 2ª semana"). Esse é o diferencial: a agenda do médico **não é CLT** e o doc hub registra
**fácil**. (Se quiser, crie uma na hora — leva 30s.)

**6. 🎯 Painel de Capacidade & DÉFICIT (2–3 min) — O CLÍMAX.** Vá ao Painel. Mostre a **capacidade real**
(derivada das escalas) e, no topo, o **INSIGHT**: *"faltam X vagas para cobrir a demanda — concentradas
em Cardiologia/Psiquiatria"*. Explique: **oferta (escalas) × demanda (solicitações dos clientes) =
previsibilidade**. É aqui que a Diretoria vê o valor: saber ANTES onde falta médico, por especialidade
e projeto, pra alocar/contratar com antecedência.

**7. De onde vem a demanda (1 min).** Solicitações → o cliente pede X vagas de tal especialidade; o
sistema distribui contra a capacidade. Feche o ciclo: **cadastro → escala → capacidade → solicitação →
distribuição** (agendamento pronto — sem disparar pra Teleconsulta nesta fase).

**8. Segurança como diferencial (30s).** Mencione: **RBAC por cliente/unidade no servidor** (não só na
tela), **LGPD** (paciente só por iniciais), **CFM**, auditoria. Público/OSS valoriza muito.

**9. Fechamento — a visão (1 min).** doc hub é o produto (Portal é o case). North-star: **hub de
soluções médicas com IA** para decisão/alocação; futuros: pareamento médico↔hospital, remuneração por
serviço. "Já funciona hoje; evolui com o crescimento."

## Perguntas prováveis — respostas curtas
- *"Os dados são reais?"* Sim — 4.523 médicos reais, escalas e solicitações reais no banco (nada mock).
- *"É seguro?"* RBAC por cliente provado no backend + testes automáticos de segurança; LGPD/CFM.
- *"Integra com a Teleconsulta?"* A arquitetura prevê; nesta fase paramos na criação do agendamento.
- *"Quanto custa manter?"* Infra enxuta (Cloud Run/Cloud SQL compartilhado), escala com o uso (P-010).
