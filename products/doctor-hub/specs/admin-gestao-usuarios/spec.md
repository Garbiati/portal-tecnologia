---
id: SPEC-ADMIN-USERS
title: Área Admin — Início + Gestão de Usuários (CRUD dos papéis)
status: specified        # draft | specified | tested | implemented
owner: Alessandro
area: Acesso
clickup: ""
figma: ""
validated_by: "Alessandro Garbiati"
validated_at: "2026-06-30"
last_update: 2026-06-30
---

# Área Admin — Início + Gestão de Usuários

> Operacionaliza a administração agora que o login é real (Keycloak/OIDC). É a **fatia operacional**
> do acesso: o admin lista, cria, edita, ativa/desativa usuários e atribui papéis. O conceito mais
> amplo de **escopo** (vincular Regulação/Gestor a uma secretaria/HC) fica na [SPEC-001
> `cadastro-usuario`](../cadastro-usuario/spec.md), que segue `draft` — ver §8.

## 1. Problema / Dor
- **Dor:** hoje o admin loga e cai num **placeholder**; não há como gerir quem acessa o Doctor-Hub.
  Toda gestão de identidade é feita no console do Keycloak (técnico, fora do produto).
- **De quem:** do **Admin** do Doctor-Hub.
- **Evidência:** pedido do Alessandro (2026-06-30) após o login real funcionar: "tela inicial para o
  admin e uma tela de gestão de usuário — CRUD de todos os papéis".
- **Sucesso = quando:** o admin cria um usuário com papel(éis), a pessoa recebe o convite por e-mail,
  define a senha e entra — tudo pela aplicação, sem tocar no console do Keycloak.

## 2. Função
Duas telas, na **persona Admin** dentro do `AppShell` (sidebar+topbar) já existente:
- **Início (Admin):** visão rápida — contagem de usuários por papel + atalhos (Usuários).
- **Usuários:** lista com busca; criar; editar (dados + papéis); ativar/desativar; reenviar convite.

**Arquitetura (D — confirmada):** o front **não** fala com o Keycloak direto. Fluxo:
`Front (admin) → doctor-hub-api (RBAC: só papel admin) → Keycloak Admin API`, usando um
**service account** com permissões mínimas de gestão de usuários (`realm-management`).

## 3. Regras de negócio  _(somente CONFIRMADAS)_
- ✅ **Acesso via API intermediária** (front→api→keycloak), nunca front→keycloak direto — _Alessandro, 2026-06-30_.
- ✅ **Só o papel `admin`** pode gerir usuários (RBAC no backend) — _Alessandro, 2026-06-30_.
- ✅ **Vários papéis por usuário** (N de `admin/demandas/regulacao/gestor`) — _Alessandro, 2026-06-30_.
- ✅ **Novo usuário define a senha por CONVITE por e-mail** (link do Keycloak; admin nunca sabe a senha) — _Alessandro, 2026-06-30_.
- ✅ **"Excluir" = DESATIVAR** (`enabled=false`): reversível, preserva histórico (LGPD) — _Alessandro, 2026-06-30_.
- ✅ Papéis disponíveis = os 4 client roles atuais do `doctor-hub-api` (D-141): `admin`, `demandas`, `regulacao`, `gestor`.
- ✅ **Campos obrigatórios: nome, e-mail, CPF e telefone** (todos). **CPF e e-mail únicos**; CPF validado (dígito verificador) — _Alessandro, 2026-06-30_.
- ✅ **Seletor de jornada incluído nesta fatia:** usuário multi-papel escolhe a jornada ao entrar e troca pelo topbar — _Alessandro, 2026-06-30_.
- ✅ Anti-lockout: admin não desativa a si mesmo nem remove o próprio papel `admin`. Admin pode editar CPF/telefone. Lista com busca+paginação. Botão reenviar convite. Início = contagem por papel + atalho — _Alessandro, 2026-06-30 (defaults aceitos)_.

## 4. Critérios de aceite  _(fonte do teste — TDD)_
```gherkin
Cenário: Admin cria um usuário e ele entra por convite
  Dado que estou autenticado como Admin
  Quando crio um usuário (nome, e-mail) com os papéis [demandas]
  Então o usuário é criado ATIVO no Keycloak com o(s) papel(éis) escolhido(s)
  E ele recebe um e-mail de convite para definir a senha
  E após definir a senha consegue entrar e cai na jornada do seu papel

Cenário: Não-admin não acessa
  Dado que estou autenticado como demandas/regulacao/gestor
  Quando chamo os endpoints de gestão de usuários
  Então recebo 403 (proibido)

Cenário: Desativar bloqueia o login
  Dado um usuário ativo
  Quando o admin o desativa
  Então enabled=false e ele não consegue mais logar (cadastro preservado)

Cenário: Atribuir vários papéis
  Dado um usuário existente
  Quando o admin marca [regulacao, gestor]
  Então o token do usuário passa a conter os dois client roles

Cenário: Editar papéis reflete no acesso
  Dado um usuário com [demandas]
  Quando o admin troca para [regulacao]
  Então no próximo login ele cai na jornada de Regulação
```

## 5. Definition of Done
- [ ] Cenários da §4 passando (TDD: API + front; E2E com Keycloak rodando).
- [ ] Sem perguntas 🔴 pendentes (§8).
- [ ] Validado por humano (`validated_by`).
- [ ] Só `admin` acessa (RBAC backend); service account com escopo mínimo; segredo fora do git.
- [ ] Design-system-first no front (`pnpm check:ui` + `pnpm build` verdes); sem PII em log (LGPD).

## 6. Fora de escopo (desta fatia)
- **Escopo/vínculo** de Regulação/Gestor a secretaria/HC (clienteId) → depende da SPEC-001 (🔴). Esta
  fatia cria a identidade + papéis; o vínculo de escopo é fatia seguinte.
- Autoatendimento (a própria secretaria cadastrar seus usuários) — futuro.
- Federação/sincronização de usuários com a Teleconsulta.

## 7. Dependências & Integrações
- **Keycloak Admin API** via service account (`realm-management`: manage-users/view-users/query-users).
- **SMTP** (I-005) — necessário para o convite por e-mail e o "definir senha".
- `doctor-hub-api` RBAC (D-142, política `papel:admin`).
- Front: `AppShell`, `persona-context`, design system (regra de reuso).

## 8. Perguntas abertas  _(resolvidas na validação 2026-06-30)_
- ✅ Campos: **nome, e-mail, CPF, telefone — todos obrigatórios**; CPF e e-mail **únicos**; CPF validado. → §3.
- ✅ **Seletor de jornada incluído agora** (login multi-papel + troca no topbar). → §3.
- ✅ Anti-lockout (sim); admin edita CPF/telefone (sim); busca+paginação (sim); reenviar convite (sim);
  Início = contagem por papel + atalho (sim). → §3.
- 🟡 **Escopo (cliente/unidade)** de Regulação/Gestor segue **fora** desta fatia (depende da SPEC-001).
- 🟡 **Unicidade do telefone:** validar formato; unicidade global a confirmar quando o telefone virar
  chave de OTP/identidade (por ora: obrigatório + validado, sem travar duplicado).

## 9. Plano de implementação (após validação)
1. **Keycloak:** service account (client confidencial) com `realm-management` mínimo; segredo em `.env`/Secret Manager.
2. **API (TDD):** `GET /admin/users` (busca/paginação), `POST /admin/users` (cria + convite),
   `PUT /admin/users/{id}` (dados+papéis), `POST .../{id}:deactivate|activate`, `POST .../{id}:resend-invite` — todos `papel:admin`.
3. **Front (TDD, design-system):** persona Admin no `AppShell`; página **Início** + página **Usuários**;
   seletor de jornada p/ multi-papel.
