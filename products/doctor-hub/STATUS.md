# STATUS — doc hub (visão única de estado)

> Painel de "o que está VIVO e real vs. o que é protótipo/planejado". Mantido à mão (o `HANDOFF.md`
> é diário narrativo; este é o estado). Última atualização: **2026-07-05**.

## 🟢 No ar (produção)
| Componente | URL | Estado |
|---|---|---|
| Landing pública | `doctorhub.app.br/` | ✅ real (SEO, form grava lead) |
| App (PWA) | `doctorhub.app.br/app` | ✅ real, login OIDC |
| IdP (Keycloak) | `id.portaltecnologia.app.br` | ✅ realm `portal`, brute-force/PKCE/refresh-rotation |
| API (.NET 10) | `api.portaltecnologia.app.br` | ✅ bearer-only, RBAC+escopo |
| Banco | Cloud SQL `portal-identity-pg` (f1-micro, SSL forçado) | ✅ keycloak + doctorhub |

CI/CD nos 3 repos (WIF keyless). Custo ~$40/mês ocioso (P-010). Smoke horário (routine).

## Telas — real vs. protótipo
**✅ Real (API):** login · usuários/papéis · clientes/HCs · médicos (4.523 reais) · escala (+ preview de
datas) · painel de capacidade & **déficit** · solicitações · **assunção (vagas reais)** · agendamento
(para no TC) · **Tenants & Features** (feature flags por tenant).
**🟡 Protótipo/fixture ainda:** `monitor-integracao` (funil hardcoded — fora da nav) · fallback de
fixture quando a API cai (agora **com banner de aviso**, não silencioso).

## 🔒 Segurança
Pentest interno (2026-07-05): **7 findings de authz corrigidos + verificados ao vivo** (8/8) · Keycloak
endurecido (K1-K4) · Cloud SQL SSL · sem credencial default · sem segredo no git · CPFs reais não
vazaram. Gate P-014 (doc 33). **Posição: pronto e seguro pra demo/homologação.**

## Papéis (D-159) — modelo canônico
super-admin (você, config de tenants/features) · admin (tenant: cria usuários e HCs) · demandas (escalas
+ médicos — usuário principal) · regulação (HC: solicita consultas) · supervisor=gestor (HC+unidade:
agenda os slots). Fluxo: escala → analisa pedidos → recruta → disponibiliza → HC aprova → supervisor agenda.

## Aberto (não bloqueia a demo)
**🟠 Antes do uso real (Demandas cadastrando):** pool de conexões (capturado no TF, aplicar em janela
segura) · resiliência Keycloak-admin (em correção) · migrations fora do boot · alertas (uptime/5xx/DB).
**🟡 Escala (10x+, adiar — P-010):** Keycloak clustering, Cloud SQL tier/HA, capacidade server-side +
paginação, observabilidade (OTel), TS strict, quebrar god files, pin de deps (em correção).
**D-159 (vira spec):** admin tenant-scoped · especialidades por HC · vínculo vaga↔solicitação (gate
D-116 em vagas reais) · mapa vaga↔unidade do gestor · prioridade FIFO · busca de paciente real no TC
(com Alessandro presente).

## Como operar
Deploy: push → CI. Rollback: `docs/operations/rollback-runbook.md`. Reset de ambiente:
`infrastructure/scripts/reset-ambiente.sh` (preserva baseline). Homologação E2E:
`infrastructure/scripts/homolog-*.py`. Gate de segurança: `docs/product/33` + `verify-seguranca-fixes.py`.
