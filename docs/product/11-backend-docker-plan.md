# Backend dockerizado (.NET 10 + Dapper + Postgres) — plano/checklist do loop

> Decisão **D-049**. Contrato de domínio: `specs/modelo-oferta-demanda/spec.md` (SPEC-000) + tipos do
> front em `app/src/data/mock.ts` / `store.tsx` (a API deve espelhar exatamente esses contratos para o
> front migrar sem reescrever telas). Modelo TC: `docs/discovery/08-healthcenter-unidades.md`.
> Regra de ouro: **NÃO INFERIR regra de negócio** → `docs/discovery/03-open-questions.md` (🟡).

## Arquitetura (tudo em Docker)
```
docker-compose.yml
├── db   postgres:16-alpine · volume · env (POSTGRES_DB=saude_demandas, USER=saude_app, PASSWORD via .env)
├── api  ./server  ·  .NET 10 (multi-stage sdk→aspnet:10.0) · Dapper + Npgsql + BCrypt + JWT · :8080 · depends_on db (healthy)
└── web  ./app     ·  multi-stage (node build → nginx:alpine) · serve SPA + proxy /api → api:8080 · :8080→80
```
Subir tudo: `docker compose up --build`. Gate de cada round: `docker compose build` OK; `db` healthy;
`api` responde `/health`; (Fase C) `web` serve o SPA e o login real funciona.

## FASE A — FUNDAÇÃO (1 agent; vem ANTES de tudo) — ✅ FEITA (2026-06-15)
- [x] `docker-compose.yml` + `.env.example` (creds dev) + `.dockerignore`s.
- [x] `server/` solução .NET 10 (ASP.NET Core minimal API) `SaudeDemandas.Api` + `Dockerfile` (sdk→aspnet).
- [x] Pacotes: Dapper, Npgsql, BCrypt.Net-Next, Microsoft.AspNetCore.Authentication.JwtBearer.
- [x] **Schema SQL** (migrations versionadas) espelhando o domínio: health_centers, unidades, especialidades,
      doctors, blocos_escala, solicitacoes, pools(disponibilizacao), reservas, agendamentos, usuarios, pacientes
      (com password_hash, role, scope_health_center_id, scope_unidade_id). Migrator simples roda no startup
      (tabela `schema_migrations`). Arquivos: `server/Db/Migrations/001_init.sql` (schema), `002_seed_reference.sql` (HCs/unidades/esp/doutores/etc).
- [x] `DbConnectionFactory` (Npgsql, conn via `ConnectionStrings__Default` do env).
- [x] **Auth real**: `POST /auth/login` (bcrypt verify → JWT), `GET /me`, validação JWT + helper `Roles` por papel.
- [x] `GET /health` (+ checa DB). Program.cs com CORS pro web, DI, pipeline.
- [x] `web/` Dockerfile (build do app atual com node → nginx) + `nginx.conf` (SPA fallback + proxy `/api`).
- [x] **Verificado**: `docker compose build` OK; `up -d db api`; `db` healthy; `curl /health` 200 `{"status":"ok","db":true}`;
      login `renata@portaltelemedicina.com.br`/`demo` retorna JWT; `/me` com o Bearer 200; senha errada/sem token → 401.
- ℹ️ **Portas no host ajustadas** (conflito local): `db` sem mapa de porta (havia Postgres em :5432); `api` em **8081→8080**
      (host :8080 ocupado). O proxy do nginx fala com `api:8080` pela rede interna, então o `web` não é afetado.
      Seed das 12 personas (bcrypt de `demo`) roda em C# no startup (`server/Data/UserSeeder.cs`).

## FASE B — DADOS + ENDPOINTS — ✅ FEITA + VERIFICADA (2026-06-15, 6 agents)
- [x] **Seed realista** (`003_seed_realistic.sql`, idempotente): **306 doutores**, ~318 pacientes, ~102 blocos de escala, 31 solicitações, 25 pools, 37 reservas, 19 agendamentos.
- [x] Endpoints (módulo `Endpoints/*` + `Repositories/*`, arquivos distintos; fiação central no `Program.cs` feita por mim):
      `Referencia` (healthcenters/unidades/especialidades/doctors/pacientes), `Escala` (blocos+sobreposição D-022),
      `Demanda` (solicitações+pools, status derivado D-035), `Execucao` (reservas com **min(saldo,teto)** D-036/37/46 + agendamentos desacoplados D-042/44), `Usuarios` (CRUD, só admin).
- [x] Autorização por papel/escopo fail-closed em cada endpoint (espelha `escopoDoUser`/`filtrarEscopo` do front).
- [x] **Fiação + fix:** claim `name` no JWT (p/ solicitante_nome); registro DI de Referencia/Usuarios; cast `::int` no PoolView. `dotnet build` 0; smoke OK (login, escopo, regra da reserva, criar solicitação).
- 🟡 Perguntas que os agents NÃO inventaram → `docs/discovery/03-open-questions.md`: histórico de escala (persistência/LGPD); travar nº de agendamentos vs `reserva.qtd` (server); validação doutor↔especialidade/paciente↔unidade no agendamento (defesa em profundidade); regra canônica do campo `org`.

## FASE C — MIGRAÇÃO DO FRONT (localStorage → API)
- [ ] Cliente HTTP (`app/src/data/api.ts`) + token JWT (Authorization: Bearer).
- [ ] `AuthContext` usa `POST /auth/login` + `GET /me` (mantém a interface `useAuth()`).
- [ ] `store.tsx` (DataProvider) passa a buscar/gravar via API (mantém a interface `useData()` — telas não mudam).
- [ ] `web` container serve o SPA migrado; `docker compose up` mostra o app ponta a ponta com banco real.

## Invariantes de todo round (gate)
1. `docker compose build` sem erro; `dotnet build` do `server` sem erro; (Fase C) `app` build tsc 0 + lint 0.
2. NÃO INFERIR regra de negócio → open-questions (🟡).
3. Creds só em `.env`/`appsettings.Development.json` (nunca hardcoded em código versionável de forma sensível). Zero segredo de produção.
4. Registrar cada round aqui.
5. **Parar** quando A+B+C completas e `docker compose up` sobe tudo saudável (db+api+web) com login real e dados realistas → resumo final + avisar "pronto pra homologar". Não reagendar.
