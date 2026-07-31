# Runbook — Homologação da Escala Fixa (entrega parcial de produção)

> **Quando usar:** para provar, no ambiente publicado, que a **criação de Escala FIXA** e o
> **relatório por origem** funcionam ponta-a-ponta antes de abrir produção.
> Cobre D-242…D-246. **Onde rodar:** no ambiente ATUAL, que passa a ser **homologação** (D-246 §2) —
> produção nasce vazia e depois, e nela nada se testa.

## 0. Pré-requisitos

| Onde | O quê | Como conferir |
|---|---|---|
| Keycloak (prod do IdP) | atributo `grupo` declarado + protocol mapper no client `doctor-hub-web` | rodar `services/portal-identity/scripts/aplicar-grupo-prod.sh` (idempotente) |
| Doctor-Hub API | deploy com o lote de hoje | `GET /health` → 200 |
| Doctor-Hub Web | deploy do mesmo lote | abrir o app, **hard-refresh** (PWA guarda versão antiga) |

**Sanity check de 1 minuto:** logar como Admin → o menu deve ter só **Início · Usuários · Clientes ·
Relatórios**; como Demandas, só **Início · Médicos**. Se aparecer Painel/Solicitações/Sync, o deploy
antigo ainda está no ar (hard-refresh).

---

## Cenário 1 — A tag de grupo chega no usuário (D-242/I-012)

1. Admin → **Usuários** → editar um usuário → preencher **Grupo/empresa de origem** = `aciges` → salvar.
2. Reabrir o usuário: o campo deve estar preenchido (se voltar vazio, o atributo não está declarado no
   Keycloak — rodar o script do §0; foi exatamente o bug do I-009).
3. Na lista, o usuário mostra a tag como etiqueta discreta.

**✅ Passou se:** a tag persiste ao reabrir. **Nada mais muda** — a pessoa continua com os mesmos papéis
e vendo as mesmas telas (a tag não é permissão).

---

## Cenário 2 — Criar uma Escala FIXA (o coração da entrega)

1. Logar com um usuário de papel **Demandas** que tenha a tag `aciges`.
2. **Médicos** → abrir a ficha de um médico → conferir/definir o **faturamento** da especialidade ×
   tipo de serviço (sem isso a criação é barrada com mensagem clara — gate D-169).
3. **Nova escala**: tipo **FIXA** (o tipo FLEX **não deve aparecer** — se aparecer, o navegador está com
   configuração antiga; a chave de config foi renovada nesta entrega, então basta recarregar).
4. Preencher dias, blocos de horário, duração da consulta e vigência (início ≥ amanhã) → salvar.

**✅ Passou se:** a escala aparece na ficha do médico com as datas/vagas previstas.
**Também vale testar (invariantes):** criar outra escala sobreposta no mesmo médico → deve ser recusada;
tentar vigência retroativa → recusada.

---

## Cenário 3 — O relatório responde "quem fez o quê" (D-244)

1. Logar como **Admin** → **Relatórios · Origem**.
2. Sem filtro nenhum: os totais (Escalas/Médicos) e as tabelas **Por grupo** e **Por usuário** aparecem
   com **tudo** — é o requisito de "ver sem filtrar" (D-246 §3).
3. Filtrar **Grupo = aciges**: só as escalas criadas por usuários com essa tag; os totais acompanham.
4. Filtrar **Usuário = <a pessoa do cenário 2>**: só o que ela criou.
5. Filtrar **período**: restringe pela data de criação.

**✅ Passou se:** a escala do cenário 2 aparece nos três recortes (grupo, usuário, período) e some quando
o filtro é de outro grupo/pessoa.

**Teste-chave da decisão (vale fazer):** troque a tag daquele usuário de `aciges` para `portal` e recarregue
o relatório — **as escalas antigas dele passam para o grupo novo**. É o comportamento correto do D-244: a
tag agrupa pessoas na hora do filtro, não fica carimbada no registro.

---

## Cenário 4 — Export (deixado por último, D-246 §3)

Botão **Exportar Excel** na tela de Relatórios baixa exatamente o recorte da tela (mesmos filtros).
Conferir: abre no Excel, uma linha por escala fixa, coluna "Criado por" com o **nome** da pessoa (nunca
CPF) e a coluna "Grupo" preenchida.

> Se a homologação da escala revelar campos faltando, é aqui que a gente ajusta — o export é o último
> item da entrega, de propósito.

---

## Limitações conhecidas (não são bugs)

- **"Médicos cadastrados por fulano" fica vazio.** Médico ainda não nasce no Doctor-Hub (vem da Portal);
  a estrutura já está pronta para quando existir cadastro/sync (D-246 §1). O que o relatório mostra é
  "médicos que têm escala neste recorte".
- **Telas incompletas continuam acessíveis por URL direta** (só saíram do menu) — com login e permissão
  exigidos normalmente. Decisão aceita no D-243.
- **Escala FLEX está desligada**, não removida.

## O que reportar se algo falhar

Print da tela + o que foi feito + horário. Para erro de API, o mais útil é o código HTTP e a mensagem
exibida — as validações desta entrega devolvem mensagem explicando o motivo (faturamento faltando,
vigência retroativa, período invertido, grupo inválido).

## Referências
- Decisões: D-242 (tag), D-243 (produção parcial), D-244 (tag resolve no relatório), D-245 (base limpa),
  D-246 (refino da 1ª entrega) em `../decisions/decisions-log.md`; I-012 no `portal-identity`.
- Runbook do sync de cadastro (outra frente, pausada): `homologacao-sync-cadastro.md`.
