# Feature flags por tenant (white-label) — design

> Decisão do Alessandro (2026-07-05): diferenciar **clientes do doc hub (TENANTS)** dos **clientes
> dos clientes (os HCs)**, e permitir habilitar/desabilitar features **por tenant**. Ex.: Portal
> Telemedicina → só `teleatendimento` + `telediagnóstico`; os outros tipos existem mas ficam OFF.
> SDD: este design é a spec — validar antes de codar. Núcleo crítico (multi-tenant) = revisão humana.

## Hierarquia (formaliza a visão do doc 28)
```
doc hub (produto)
└── TENANT  = cliente do doc hub (ex.: Portal Telemedicina)      ← NOVO
    ├── feature flags (o que está habilitado neste tenant)        ← NOVO
    └── CLIENTES do tenant = HCs (Piauí, Amazonas…)               ← os "Clientes" de hoje
```

## Decisões confirmadas
- **D-158a — Sistema GENÉRICO de feature flags por tenant** (não hardcode): cobre **tipos de serviço**
  (teleatendimento, telediagnóstico, laudo…) **E módulos/features** do app (escalas, solicitações,
  painel, assunção…), extensível a features futuras. Começa ligando os tipos de serviço.
- **D-158b — Configurado pelo SUPER-ADMIN do doc hub** (você): controle centralizado (padrão SaaS/
  white-label). O tenant recebe o que foi habilitado; não mexe nos próprios flags (por ora).

## Modelo de dados
- **Tenant**: `Id`, `Nome`, `Slug`, `Ativo`, `CriadoEm`. **Portal = tenant 1** (seed do baseline).
- **Cliente** (existente): **+ `TenantId`** (FK) — cada HC pertence a um tenant.
- **Feature (catálogo)**: `Key`, `Categoria` (`tipo-servico` | `modulo` | `feature`), `Nome`,
  `DefaultHabilitado`. É o que a tela de config sabe listar.
- **TenantFeature**: `(TenantId, FeatureKey, Habilitado)` — **override por tenant**; sem linha =
  `DefaultHabilitado` do catálogo. Mecanismo único e extensível (nova feature = nova linha no catálogo).

Exemplos de keys: `tipo-servico:teleatendimento`, `tipo-servico:telediagnostico`, `tipo-servico:laudo`,
`modulo:escalas`, `modulo:solicitacoes`, `modulo:painel`, `modulo:assuncao`.

## API (super-admin)
- `GET /api/tenants` — lista tenants.
- `GET /api/tenants/{id}/features` — catálogo + estado efetivo (default ∪ override).
- `PUT /api/tenants/{id}/features/{key}` `{ habilitado }` — liga/desliga.
- Política nova: `super-admin` (ver open questions). Fase 1 gate = `admin`.

## Como o app respeita os flags
- **Escala**: o select de tipo de serviço mostra só os `tipo-servico:*` habilitados no tenant corrente.
- **Módulos**: nav + rotas escondem/bloqueiam os `modulo:*` desabilitados (defense-in-depth: back-end
  também recusa endpoint de módulo OFF).
- **Resolução do tenant corrente**: hoje single-tenant → **Portal (tenant 1)**. No multi-tenant futuro,
  o `tenantId` vem do token (como o `clienteId` hoje — I-011/D-142).

## Faseamento
- **Fase 1 (concreta, o exemplo):** Tenant + `Cliente.TenantId` + catálogo de **tipos de serviço** +
  `TenantFeature` + **tela de config (super-admin)** + a escala respeita os tipos habilitados.
  Portal = teleatendimento + telediagnóstico; os demais existem mas OFF.
- **Fase 2:** módulos/telas do app no mesmo mecanismo + features futuras. "Até feature por feature."

## Perguntas abertas (NÃO inferir — confirmar)
1. **Papel `super-admin`**: hoje `admin` = você (single-tenant), então na Fase 1 a tela de config fica
   atrás de `admin`. Formalizar um papel `super-admin` distinto do `admin`-do-tenant quando houver 2º
   tenant. OK assim?
2. **`telediagnóstico`**: não está no catálogo atual (hoje: teleatendimento, atendimento, plantão,
   laudo, exame). É um tipo NOVO (slug `telediagnostico`) ou mapeia p/ um existente? Vou adicionar como
   novo, salvo indicação.
3. **Default sem override**: feature sem linha em `TenantFeature` usa `DefaultHabilitado` do catálogo
   (proposta: tipos de serviço nascem habilitados; o super-admin restringe por tenant). OK?

## Fora de escopo
Multi-tenant real (isolamento de dados por tenant além do que o RBAC já faz — D-142); auto-serviço do
tenant configurar os próprios flags (D-158b: por ora só o super-admin).
