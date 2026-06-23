---
id: SPEC-XXX
title: <Nome da feature/tela>
status: draft            # draft | specified | tested | implemented
owner: <quem é dono desta spec>
area: <Oferta | Demanda | Alocação | Remanejamento | Agendamento | Acesso | Integração>
clickup: <url da tarefa/whiteboard, se houver>
figma: <url do frame, se houver>
validated_by: ""         # preenchido quando humano confirma (status: specified)
validated_at: ""         # data da validação
last_update: <AAAA-MM-DD>
---

# <Nome da feature/tela>

## 1. Problema / Dor  _(Definition of Success — o "resolve a dor")_
> POR QUE isto existe. Sem isto, a feature não deveria ser construída.

- **Dor:** <qual dor concreta>
- **De quem:** <qual papel/persona sente a dor>
- **Evidência:** <como sabemos que a dor é real — fala do cliente, ticket, lei, etc.>
- **Sucesso = quando:** <o resultado observável que prova que a dor foi resolvida (outcome, não output)>

## 2. Função  _(o "o quê")_
> O que a tela/feature faz, em linguagem de negócio (não técnica).

<descrição funcional>

## 3. Regras de negócio  _(somente CONFIRMADAS)_
> Apenas regras com `✅ Confirmado por <nome> em <data>`. Tudo o resto vai para "Perguntas abertas".

- ✅ <regra confirmada> — _Confirmado por <nome> em <data>_

## 4. Critérios de aceite  _(a fonte do teste — Gherkin/BDD)_
> Cada cenário aqui VIRA um teste executável antes do código (TDD).

```gherkin
Cenário: <nome>
  Dado <contexto>
  Quando <ação>
  Então <resultado observável>
```

## 5. Definition of Done  _(o "funciona")_
- [ ] Todos os cenários da seção 4 passam como teste automatizado
- [ ] Sem perguntas abertas 🔴 pendentes
- [ ] Validado por humano (preencher `validated_by`)
- [ ] <critérios específicos desta feature>

## 6. Fora de escopo  _(o que esta spec NÃO faz)_
> Protege o escopo congelado. O que está aqui é deliberadamente deixado de fora desta entrega.

- <item fora de escopo>

## 7. Dependências & Integrações
- <ex: insere agendamento na Teleconsulta — contrato em SPEC-XXX>

## 8. Perguntas abertas  _(NÃO INFERIR — perguntar)_
> Enquanto houver 🔴 aqui, a spec não pode virar `specified`.

- 🔴 <pergunta que bloqueia>
- 🟡 <pergunta importante>
- 🟢 <pergunta que pode esperar>
