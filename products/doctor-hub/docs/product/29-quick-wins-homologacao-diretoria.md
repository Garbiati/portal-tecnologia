# Quick wins — homologação pela Diretoria ASAP

> Análise (2026-07-05): o que falta pra apresentar o app à Diretoria o mais rápido possível, por
> impacto × esforço. A Diretoria não homologa "cada campo" (isso é a homologação operacional, doc 26)
> — ela quer VER o valor, que funciona e que é profissional/confiável. Foco nisso.

## Já pronto (o alicerce — não refazer)
- App funcional + **homologado E2E** em 5 telas (doc 26 / D-153); **segurança RBAC** por cliente
  provada (D-142); baseline limpo (só o dono); **CI/CD** nos 3 repos; marca "doc hub".
- **Landing** (v1) + **e-mail profissional** (deployando via o CI que acabou de subir).

## Quick wins (prioridade IMPACTO × ESFORÇO)

### 🥇 1. [ALTO impacto · MÉDIO esforço] Painel com o INSIGHT que é a tese do produto
Hoje o painel mostra **capacidade real**. O "wow" pra Diretoria é cruzar **capacidade × DEMANDA**
(solicitações) e mostrar o **déficit**: *"temos 1.860 vagas/mês, a demanda é 2.400, faltam 540 —
concentradas em Cardiologia/Piauí"*. É a **previsibilidade** (o diferencial). Materializa a Fase 4.3/4.4
do doc 26 num dashboard simples com 1 insight claro. **É o que faz a Diretoria entender o valor em 10s.**

### 🥈 2. [ALTO · BAIXO] Cenário de demo semeado (realista, com números)
Um projeto de ponta a ponta pronto pra mostrar: médicos reais + escalas (previsível e dinâmica) +
solicitações + a distribuição/déficit. Sem isso a demo começa vazia. Eu semeio via script (reversível).

### 🥉 3. [ALTO · BAIXO — em progresso] Landing no ar em doctorhub.app.br
A Diretoria abre `doctorhub.app.br` e vê o **produto posicionado** (o que é, segurança, case Portal)
antes de entrar no app. Primeira impressão profissional. (Já em deploy.)

### 4. [MÉDIO · BAIXO] Roteiro de demo guiado (10 min)
Um script de apresentação: login → cria cliente → cadastra/importa médico → monta escala real →
**vê a capacidade** → cria solicitação → **vê o déficit/distribuição**. Evita fumbling ao vivo.

### 5. [MÉDIO · BAIXO] Polir os rough edges VISÍVEIS no happy-path
Dos ~99 médios catalogados, corrigir só os que aparecem numa demo de Diretoria (textos, estados
vazios, um ou outro fluxo). Não os 99 — os ~10 que a Diretoria veria.

### 6. [MÉDIO · BAIXO] Confiabilidade na hora da apresentação
`min-instances=1` nos 3 serviços durante a janela (sem cold start/travada); uptime + smoke ativos
(já temos); reverter depois (custo — P-010).

### 7. [BAIXO · BAIXO] Consistência de marca "doc hub" (login/e-mail/app) — quase pronto
O CI do IdP que subiu alinha login + e-mail. Fechar o app em /app + landing dá o conjunto coeso.

## Sequência recomendada (caminho mais curto até a Diretoria)
1. Terminar o que já está em voo: **landing no ar** (/app) + **e-mail profissional** (CI do IdP).
2. **#1 déficit/insight no painel** (o valor) + **#2 cenário semeado** (pra ter o que mostrar).
3. **#4 roteiro de demo** + **#6 confiabilidade**.
4. **#5 polimento** dos rough edges visíveis.

## O que fica FORA (não bloqueia a Diretoria)
Os 99 médios/70 cosméticos restantes; onboarding do médico (D-156); FLEX/regras "depois" (D-151);
recebimento de e-mail em contato@ (nice-to-have p/ leads, não p/ a demo).
