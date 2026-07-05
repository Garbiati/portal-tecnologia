# Raio-x de completude por perfil — 2026-07-04

> Classificação FACTUAL (5 agentes lendo o código, evidência arquivo:linha) de quanto cada perfil
> está ligado a dados/ações REAIS da API vs fixture/placeholder. Critério: % ponderado por
> funcionalidade. Relatório interativo: artifact "raio-x de completude" (claude.ai) da sessão.
> Serve de base para priorizar as próximas fatias (pós-demo de 2026-07-07).

| Perfil | Completude | Telas | Funcionalidades | Real | Fixture | Placeholder |
|---|---|---|---|---|---|---|
| **Demandas** | 13% | 15 | 75 | 10 | 56 | 9 |
| **Regulação** | 0% | 2 | 17 | 0 | 16 | 1 |
| **Supervisor** | 0% | 1 | 10 | 0 | 10 | 0 |
| **Admin** | 100% | 2 | 12 | 12 | 0 | 0 |

## Leitura executiva
- **Admin (100%)**: CRUD de usuários via API→Keycloak completo (D-143) — pronto de verdade.
- **Demandas (13%)**: o REAL está concentrado na **ficha do médico** (edição cadastral, faturamento
  por especialidade e por laudo, status — D-127/D-125/D-126) e na **lista de médicos** (GET /doctors).
  A **escala é 100% fixture** (escalas-store de sessão, some no reload) — é a Fatia 1 já especificada
  (SPEC-MEDICOS-ESCALA v2). Solicitações/clientes/painel = fixture.
- **Regulação (0%) e Supervisor (0%)**: jornadas inteiras sobre fixture — dependem de backend de
  solicitações (SPEC-000/ui.md draft) e de assunção/agendamento (dependência TC: POST /integration/appointment).

## Ordem sugerida de ataque (pós-demo)
1. **Backend da escala** (Fatia 1 — spec aprovada; destrava /escala, capacidade e o badge "com escala").
2. **Solicitações** (destrava Demandas·Inbox + Regulação inteira; specs em draft — precisam aprovação).
3. **Assunção/agendamento** (Supervisor; exige integração TC — DEP-TC-1).
4. Painel/estoque real (deriva de 1+2).

## Gotchas encontrados pelos agentes (corrigir na Fatia 1)
- `/escala` e `/medico/:id` (deep-link) **não chamam** `hidratarMedicosDaApi` — caem na fixture; só
  `/medicos-escala` hidrata.
- `temEscala` hardcoded `false` p/ médicos da API (api.ts:190) — filtro "Com escala" vazio.
- Busca/filtro/paginação de médicos são client-side (ok p/ 4,5k, mas mover pro servidor).


---

## ATUALIZAÇÃO 2026-07-04 (noite) — pós "ondas do 100%" (D-145)

Backend + front das ondas 1–3 EM PRODUÇÃO (E2E 8/8 verde). Estimativa revisada:

| Perfil | Antes | Agora | O que virou REAL |
|---|---|---|---|
| Admin | 100% | **100%** | (já era) |
| Demandas | 13% | **~70%** | escalas (CRUD+invariantes+persistência), inbox de solicitações, home (KPIs), auditoria, clientes; ficha/médicos já eram |
| Regulação | 0% | **~90%** | minhas solicitações (lista + CRIAÇÃO persiste), de acordo (aceite = flag persistida) |
| Supervisor | 0% | **~60%** | assunção/agendamento persiste e re-hidrata (LGPD só iniciais); vagas seguem derivadas (PROVISÓRIO) |

Segue fixture/derivado (com regra pendente — NÃO inferir): painel (capacidade), contratação
(fórmula D-113×v2 em aberto), sobrepor (regras de reserva), monitor-integração, vagas da assunção,
cobertura numérica (`coberturaDe`). TC real = DEP-TC-1.
