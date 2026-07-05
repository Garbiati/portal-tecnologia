# Runbook — Rollback & Incidente (doc hub em produção)

> **O "como desfaço" em prod.** Lacuna apontada no scorecard de maturidade (05/07/2026). Healthcare/
> prod: reverter rápido é inegociável. Cloud Run guarda revisões → rollback é **roteamento de tráfego**
> (instantâneo, sem rebuild). Distinto do `reset-ambiente.sh` (que zera dados, NÃO reverte release).

## TL;DR — reverter um release ruim (instantâneo)
Cada serviço (`doctor-hub-api`, `doctor-hub-web`, `portal-identity`) guarda revisões no Cloud Run.
Para voltar tráfego pra a revisão anterior boa:

```bash
REGION=southamerica-east1
# 1. listar revisões (a ativa + as anteriores), mais nova primeiro
gcloud run revisions list --service=<SERVICE> --region=$REGION \
  --format='table(metadata.name, status.conditions[0].lastTransitionTime, spec.containers[0].image)'
# 2. rotear 100% do tráfego pra a revisão BOA anterior (instantâneo, sem rebuild)
gcloud run services update-traffic <SERVICE> --region=$REGION --to-revisions <REV_BOA>=100
```
`<SERVICE>` ∈ {`doctor-hub-api`, `doctor-hub-web`, `portal-identity`}. Confirme com o smoke (abaixo).

## Antes de reverter — 30s de diagnóstico
- **Qual serviço quebrou?** `curl` os 4 healths (ver smoke). O `smoke-doctor-hub` (routine, de hora em hora) já dá o veredito.
- **Foi deploy de código ou de config?** Código → rollback de revisão. Config (Keycloak realm/secret/env) → reverter a mudança de config (não a revisão).
- **Houve MIGRATION no release?** ⚠️ crítico (abaixo).

## ⚠️ Rollback COM migration de banco
As migrations rodam no **boot da API** (`MigrateAsync`) e são normalmente **aditivas** (backward-compatible)
→ o código antigo geralmente roda sobre o schema novo **sem quebrar**. MAS:
- Se a migration foi **destrutiva** (drop/rename de coluna usada pelo código antigo), o rollback de código
  **não basta** — precisa de migration reversa. Por isso: **evitar migrations destrutivas**; preferir
  expand→migrate→contract.
- O rollback de tráfego **não desfaz** dados já gravados/migrados. Para dados: `reset-ambiente.sh`
  (destrói o transacional, preserva o baseline — NÃO é rollback de release).

## Por serviço
- **doctor-hub-api / doctor-hub-web:** rollback de revisão (TL;DR). Deploy é via CI (push → build → Cloud Run).
- **portal-identity (Keycloak):** rollback de revisão reverte a IMAGEM (tema/providers). O **realm** vive
  no banco (não é re-importado) → mudança de realm feita via Admin API se reverte via Admin API, não pela
  revisão. Tema: rollback de revisão volta a imagem anterior.
- **Config/secret:** Secret Manager guarda versões → `gcloud secrets versions list <secret>` e apontar o
  Cloud Run pra a versão boa (ou `add` uma nova). Realm/roles: reverter via Admin API + realm JSON.

## Smoke pós-rollback (tem que ficar tudo 200)
```bash
for u in doctorhub.app.br/ doctorhub.app.br/app \
         id.portaltecnologia.app.br/realms/portal api.portaltecnologia.app.br/health; do
  printf '%-42s %s\n' "$u" "$(curl -sS -o /dev/null -w '%{http_code}' https://$u)"
done
```
Depois: rodar `infrastructure/scripts/verify-seguranca-fixes.py` se o release mexeu em authz.

## Incidente — ordem de ação
1. **Estabilizar** (rollback de tráfego) antes de investigar a fundo. Serviço no ar > diagnóstico perfeito.
2. **Comunicar** (se tiver stakeholder/demo em curso).
3. **Diagnosticar** pela causa (logs no Cloud Logging; `gcloud run services logs read <SERVICE>`).
4. **Registrar** a causa + o fix como decisão (D/P/I-xxx) — não repetir o mesmo furo.

## Prevenção (débito 🟠 registrado)
- Mover `MigrateAsync` do boot → job pré-deploy (evita corrida com >1 instância).
- Alertas (uptime/5xx/DB) — hoje só o smoke de 1h avisa; sem push quando cai.
- Readiness real (health que toca o banco) — hoje `/health` é estático.
