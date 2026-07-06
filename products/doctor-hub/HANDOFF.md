# HANDOFF — 06/07 08h BRT · Doctor Hub pronto para a demo

> Sessão remota da noite de **05/07** (Alessandro homologando + off ao final). Tudo pedido está
> **no ar, verde e saudável**. Nada pendente bloqueia a demo de segunda ao meio-dia.

## ✅ Verificação final (23:54 BRT 05/07)
| Check | Resultado |
|---|---|
| IdP `realms/portal` | **200** |
| API `/health` | **200** · `{"status":"healthy"}` |
| Web `/app` | **200** |
| Landing | `Doctor Hub — capacidade médica no lugar certo, na hora certa` |
| Login Keycloak | 302 (fluxo OK) |
| Contrato/gate (`/especialidades-habilitadas`) | 401 (protegido/deployado) |
| CI (web · api · idp) | **todos success** |
| Testes | web **442** · api **185** |

**Monitor noturno:** rotina `smoke-doctor-hub` roda de hora em hora (veredito no seu celular).
⚠️ Corrigido nesta sessão: as rotinas checavam o título antigo (`doc hub`/`Doctor-Hub`) — atualizei
a boa para `<title>Doctor Hub` e desliguei a duplicada, senão você levaria **alarme falso** a noite toda.

## 🚀 O que subiu hoje
1. **Rebrand Doctor Hub completo** — nome, marca **Hub Orbital**, paleta **navy+ouro**, **tema claro padrão** — no **app, landing, login E e-mail**.
2. **Papéis renomeados** (D-162): Regulação → **Gestor do Contrato** · Supervisor → **Operador de Agendamento** (rótulos; slugs técnicos intactos).
3. **Home + Meus dados para todos os papéis** — homes novas de Gestor do Contrato, Operador e Super Admin.
4. **Logo por cliente** (D-163, white-label) — Admin sobe imagem; aparece na identidade; **reset preserva**.
5. **Contrato por cliente + GATE** (D-164) — Admin liga Telemedicina + especialidades por cliente; Gestor do Contrato **só solicita o que está no contrato**.
6. **Escala sempre pool** (D-165) — removido o campo "Projeto"; alocação a cliente é no **agendamento/retorno**, não na escala.
7. **Usuários e detalhes do cliente view-first** — abrem em **visualização** (não edição), com Editar/Inativar/Excluir + filtros (papel/status) + campo Cliente condicional.
8. **Wizard de criar escala** (D-166) — **4 passos** guiados (o quê / quando / horários / revisão) + prévia de capacidade; invariantes preservadas.
9. **Registrado p/ depois:** IA na escala v2 (D-167 — backend+Haiku+Secret Manager, adiado por sua decisão) · upload em lote (template a definir).

## 🧪 Como homologar (ordem sugerida — de manhã)
1. **doctorhub.app.br** em aba anônima → landing rebrandada → **Entrar**.
2. Login (sua conta) → app **navy+ouro/claro** + Doctor Hub.
3. **Contrato:** Admin → **Clientes** → ⋯ de um cliente → **"Atividades / Contrato"** → liga Telemedicina + especialidades.
4. **Gate:** entre como **Gestor do Contrato** daquele cliente → **Nova Solicitação** → só as habilitadas aparecem.
5. **Wizard:** abra um médico → **Criar escala** → passe pelos 4 passos (**teste no celular** — era onde incomodava).
6. **Usuários:** clique num usuário → **visualização** → Editar/filtros.
7. **Logo:** ⋯ de um cliente → detalhe → **Enviar logo** → veja na identidade.

> Se algo parecer "não atualizado" no celular: **Ctrl+Shift+R / aba anônima** (cache do PWA).

## ⚠️ Pendências / riscos (NÃO bloqueiam a demo)
- **PNGs do PWA / OG image** ainda com a arte antiga (o `favicon.svg` já é o novo — a aba mostra Hub Orbital). Regenerar do SVG precisa de rasterizador (ambiente não tem). **Cosmético.**
- **IA v2 (D-167)** e **upload em lote (D-166)** — registrados, não construídos (adiamento seu).
- **`escala.clienteId`** fica dormante no backend (sempre null) — dropar em migração futura.
- **Backlog técnico pós-demo:** pool-size do Postgres (janela segura), migrations off-boot, Cloud SQL tier/HA, Keycloak clustering, capacidade server-side.

## 🔒 Segurança/LGPD
Nenhum segredo tocado ou vazado · `doctors-demo.json` local-only · pushes só p/ `Garbiati/` · gitleaks limpo em todos os commits.

_Gerado 06/07 ~00h BRT. Decisões da sessão: D-162..D-167 em `docs/decisions/decisions-log.md`._
