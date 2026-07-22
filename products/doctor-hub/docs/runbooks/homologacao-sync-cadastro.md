# Runbook — Homologação do sync bidirecional de cadastro (health_center ⇄ Cliente)

> **Quando usar:** depois que a chave DoctorHub estiver configurada e o relay ligado, para
> **provar ponta-a-ponta** que uma mudança no Doctor-Hub reflete na Teleconsulta e vice-versa.
> Cobre PRD-026 / D-231…D-237. O canal foi provado em **ensaio local** (docker) antes deste runbook;
> aqui é a homologação no ambiente publicado.

## 0. Pré-requisitos (o "ligar a chave")

Antes de qualquer cenário, confirmar que está tudo no ar e configurado:

| Onde | Config | Valor |
|---|---|---|
| **Core (ptm-core-api)** deployada | `PARTNERAPIKEY__DOCTORHUB` (Secret Manager) | a chave de parceiro DoctorHub |
| **Hub (doctor-hub-api)** deployada | `TeleconsultaSync__ApiKey` (Secret Manager) | a **mesma** chave DoctorHub |
| Hub | `TeleconsultaSync__BaseUrl` | a CoreAPI publicada (ex.: `https://.../api/core/v1`) |
| Hub | `ClienteSyncOutbox__Enabled` | `true` (liga o **push** Hub→TC) |
| Hub | `Sync__Teleconsulta__Enabled` | `true` (liga o **pull** TC→Hub) |

**Sanity check (2 min), antes de mexer em tela:**
1. `GET {BaseUrl}/sync/health-centers` **sem** header → deve dar **401** (auth ativa).
2. `GET {BaseUrl}/sync/health-centers` com `X-API-KEY: <chave DoctorHub>` → **200** + JSON de health centers.
3. No Hub, abrir a tela **admin (persona Admin) → "Sync · Teleconsulta"** (`admin-sync`): o card **Relay** deve estar **Ligado** (âmbar = desligado, revisar a env).

**Probe de prontidão de Unidade/Grupo (sem segredo):** os cenários 6–7 dependem da TC publicada
conter os feeds novos (PRs #2067/#2071, mergeados na `dev` em 2026-07-22). Antes de tentá-los:

```bash
curl -s -o /dev/null -w '%{http_code}\n' {BaseUrl}/sync/units    # 401 = no ar · 404 = master ainda sem a promoção
curl -s -o /dev/null -w '%{http_code}\n' {BaseUrl}/sync/groups
```

Enquanto der **404**, a `master` da TC ainda não recebeu a promoção `dev → staging → master` —
rode só os cenários 1–5 (Cliente) e volte aqui depois do release da TC.

> A tela `admin-sync` é o **painel da homologação** — deixe-a aberta num monitor com o **auto-refresh ligado**;
> ela mostra o outbox (Pendente/Entregue/Conflito), tentativas, último erro e o watermark do pull.

---

## Cenário 1 — Renomear um Cliente no Hub reflete na TC (Hub→TC, update)

1. Hub → **Clientes** (`admin-clientes`): escolha um Cliente **que veio da TC** (tem `ExternalId`; os
   Clientes demo C1–C5 **não** têm âncora e não empurram). **Renomeie** e salve.
2. Na tela **Sync**: uma linha nova de outbox aparece — `Operação = Atualizar`, `Status = Pendente`.
3. Em até 1 min (intervalo do relay), a linha vira **Entregue** (`Tentativas` ≥ 1).
4. **Conferir na TC:** o `health_centers.name` daquele `external_id` = o novo nome (via tela da TC que
   lista health centers, ou consulta ao banco por quem tem acesso a prod).

**✅ Passou se:** outbox → Entregue **e** o nome atravessou.
**Anti-eco:** no próximo pull, o Hub recebe o HC de volta com o mesmo nome → `ClienteSyncService` é no-op
(não gera evento novo). A tela **não** deve ficar criando outbox em loop.

---

## Cenário 2 — Criar um Cliente no Hub cria o health_center na TC (Hub→TC, create)

1. Hub → **Clientes** → **Novo cliente** (sigla/nome/natureza). Salvar.
2. O Hub gera um `ExternalId` (Guid) e enfileira `Operação = Criar` (Sync → Pendente).
3. Relay roda → **Entregue**. Na TC, um **health_center novo** com aquele `id` (= `external_id`) e o nome,
   **completo** (timezone default + evento no message bus, porque a criação passa pelo `HealthCenterService`, D-236).
4. **Conferir na TC:** o novo health_center existe e é usável.

**✅ Passou se:** outbox → Entregue **e** o HC nasceu na TC.

---

## Cenário 3 — Mudar um health_center na TC reflete no Hub (TC→Hub, pull)

1. Na **TC**, renomeie um health_center (ou crie um) — pelo caminho normal da TC.
2. Na tela **Sync** do Hub, o **watermark do pull** avança (o `ultimoSyncEm` atualiza no intervalo do sync).
3. Hub → **Clientes**: o Cliente correspondente (por `ExternalId`) aparece com o **nome novo** (ou um Cliente
   novo, se o HC era novo — derivado por `ClienteFactory`).

**✅ Passou se:** a mudança da TC apareceu no Hub sem ninguém digitar nada no Hub.

---

## Cenário 4 — Colisão de nome vira Conflito (terminal, não trava a fila)

1. Hub → **Clientes** → criar um Cliente com um **nome que já existe** como health_center na TC.
2. Relay tenta o `POST` → a TC responde **409** (a checagem de nome único da TC dispara `ConflictException`).
3. Na tela **Sync**: a linha vira **Conflito** (vermelho), com `ultimoErro` preenchido — **e não fica
   retentando pra sempre** (409/4xx é terminal; 404/429/5xx é que retenta).

**✅ Passou se:** a linha para em **Conflito** e o resto da fila continua fluindo.
**Regra aberta:** o que fazer com a colisão (rejeitar vs vincular) ainda é decisão de produto — por ora,
Conflito exige atenção humana.

---

## Cenário 5 — Relay desligado acumula; ligar drena

1. Desligue o relay (`ClienteSyncOutbox__Enabled=false`) e redeploy/reload.
2. Edite/crie alguns Clientes → na tela **Sync**, o Relay mostra **Desligado** e as linhas ficam **Pendente**
   (nada vai pra TC).
3. Ligue o relay (`=true`) → em um ciclo, os Pendentes drenam para **Entregue**.

**✅ Passou se:** off = acumula sem enviar; on = drena. (É o **kill switch** de segurança.)

---

## Cenário 6 — Unidade/Grupo criados ou renomeados na TC aparecem no Hub (TC→Hub, pull · D-239)

> Pré-requisito: probe de prontidão (§0) devolvendo **401** em `/sync/units` e `/sync/groups`.

1. Na **TC**, crie ou renomeie uma **Unidade** (`profile_tag`) num health center que exista como
   Cliente no Hub — pelo caminho normal da TC. Idem para um **Grupo**, se quiser cobrir os dois feeds.
2. No Hub, aguarde o ciclo do pull (ou dispare a carga pelo caminho admin) e abra a tela de
   **Unidades**: a Unidade nova/renomeada aparece **no Cliente certo** (o item do feed carrega
   `health_center_id`; o casamento por Cliente/vínculo é o do D-218).
3. Conferir que o Grupo (se criado) aparece na gestão de Grupos da tela de Unidades.

**✅ Passou se:** a mudança da TC apareceu no Hub, no Cliente certo, sem digitação manual no Hub.

---

## Cenário 7 — Deletar Unidade na TC propaga o tombstone (D-240)

> Este cenário só existe porque `ProfileTag`/`ProfileTagGroup` viraram **soft-delete** na TC
> (D-240): o `DELETE /profiles/tags/{id}` agora marca `deleted_at` em vez de apagar a linha, e o
> feed emite o item com `deleted=true`. Antes disso, o delete era invisível pro sync (Unidade
> fantasma eterna no Hub).

1. Na **TC**, delete uma Unidade **de teste** (criada no cenário 6 — não use Unidade real em uso).
2. No Hub, após o ciclo do pull, a Unidade **some** da tela de Unidades (ou aparece como
   removida, conforme a tela trate tombstone).
3. **Recriação:** crie na TC uma Unidade nova com o **mesmo nome** (e/ou mesmo CNES) no mesmo HC —
   deve ser aceita (índices únicos são parciais, `WHERE deleted_at IS NULL`) e refletir no Hub
   como Unidade nova.

**✅ Passou se:** a deleção atravessou (sem fantasma) **e** a recriação com o mesmo nome/CNES funciona.

---

## Rollback / kill switch

- **Parar o push imediatamente:** `ClienteSyncOutbox__Enabled=false` (o outbox continua acumulando, sem enviar).
- **Parar o pull:** `Sync__Teleconsulta__Enabled=false`.
- Nenhuma escrita destrutiva na TC: o write é **allowlist** (name/normalized_name/deleted_at/updated_at),
  `WHERE id = external_id`, **nunca DELETE/DROP/TRUNCATE** (D-069). "Remover" = soft (deleted_at / tombstone).

## O que observar (invariantes)

- **LWW por timestamp:** se o mesmo campo mudou dos dois lados, vence o `updated_at` mais recente
  (compare-and-swap no UPDATE da core — sem sobrescrever cego).
- **Idempotência:** reenviar o mesmo evento (retry) é no-op (por id no create; por LWW no update).
- **Convergência:** o pull periódico (anti-entropia) é a garantia de longo prazo — reconciliação dedicada
  é o próximo passo (D-233), ainda não ligada.

## Referências
- Decisões: D-230…D-240 em `../decisions/decisions-log.md` (cenários 6–7: D-239 e D-240).
- Endpoints core: `GET/PUT/POST /sync/health-centers` + `GET /sync/units` + `GET /sync/groups`
  (ptm-core-api, `SyncController`; units/groups mergeados na `dev` em 2026-07-22 — PRs #2067/#2071).
- Hub: `/api/clientes` (CRUD que origina), `/api/admin/sync/status` (o painel), tela `admin-sync`.
