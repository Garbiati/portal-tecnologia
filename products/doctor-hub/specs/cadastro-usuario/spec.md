---
id: SPEC-001
title: Cadastro de Usuário (com papel e escopo)
status: draft
owner: Alessandro
area: Acesso
clickup: ""
figma: ""
validated_by: ""
validated_at: ""
last_update: 2026-06-14
---

# Cadastro de Usuário (com papel e escopo)

## 1. Problema / Dor  _(Definition of Success)_
- **Dor:** hoje não existe forma controlada de dar acesso a quem representa um governo/secretaria
  para que ele consiga solicitar atendimentos de uma especialidade para um HC.
- **De quem:** do operador/Admin que precisa habilitar o solicitante; e do próprio solicitante,
  que não tem por onde pedir os atendimentos.
- **Evidência:** descrição do Alessandro (2026-06-14) — exemplo: "um membro da secretaria de
  saúde de um estado que irá solicitar 1000 atendimentos de cardiologista".
- **Sucesso = quando:** um membro de secretaria recém-cadastrado consegue, sozinho, abrir uma
  solicitação de N atendimentos de uma especialidade para o seu HC — e o sistema sabe quem ele é,
  o que ele pode ver e o que ele pode fazer.

## 2. Função  _(o quê)_
Tela que cria um usuário do sistema e o associa a um **papel** (ex.: Solicitante/Gestor de uma
secretaria) e a um **escopo** (ex.: um estado / um ou mais HCs), definindo o que ele pode fazer.
O exemplo-âncora: cadastrar o membro da secretaria que vai solicitar atendimentos.

## 3. Regras de negócio  _(somente CONFIRMADAS)_
> Nenhuma regra confirmada ainda. Esta spec está em `draft` justamente porque o que segue
> abaixo (seção 8) precisa ser respondido por um humano antes de virar contrato.

## 4. Critérios de aceite  _(rascunho — a validar junto com as regras)_
```gherkin
Cenário: Admin cadastra um solicitante de secretaria
  Dado que estou autenticado como Admin
  Quando cadastro um usuário com papel "Solicitante" e escopo "Secretaria de Saúde de <Estado>"
  Então o usuário é criado como ativo
  E o usuário passa a poder abrir solicitações apenas para o(s) HC(s) do seu escopo
```
> ⚠️ Este cenário é uma HIPÓTESE. Não vira teste enquanto as perguntas 🔴 não forem respondidas.

## 5. Definition of Done
- [ ] Cenários da seção 4 confirmados e passando como teste
- [ ] Sem perguntas 🔴 pendentes
- [ ] Validado por humano
- [ ] Trilha de auditoria do cadastro (quem criou, quando) — _a confirmar se é requisito_

## 6. Fora de escopo  _(rascunho)_
- Autenticação/login em si (provável SPEC separada).
- Fluxo de solicitação de atendimentos (provável SPEC separada — esta tela só habilita o acesso).

## 7. Dependências & Integrações
- Depende do **mapa final de papéis** (`docs/discovery/02-roles.md`).
- Relaciona-se com a futura SPEC de "Solicitação dos Governos".
- ❓ Relaciona-se com a Teleconsulta? (o usuário existe só aqui, ou precisa existir na TC também?)

## 8. Perguntas abertas  _(NÃO INFERIR)_
- 🔴 Quais são, de fato, os papéis e suas permissões? ("Solicitante" e "Gestor" são o mesmo?)
- 🔴 Um usuário pertence a UM escopo (um estado/uma secretaria) ou pode ter vários?
- 🔴 Quem pode cadastrar quem? (Admin cadastra todos? A secretaria cadastra os próprios?)
- 🟡 O usuário "secretaria" solicita por HC específico, ou por estado (e o sistema distribui)?
- 🟡 O exemplo "1000 atendimentos de cardiologista" tem teto/aprovação? Pode pedir qualquer quantidade?
- 🟡 Há trilha de auditoria obrigatória (LGPD) sobre quem cadastrou e acessou?
- 🟢 O cadastro envia algum convite/e-mail ao usuário, ou o acesso é entregue manualmente?
