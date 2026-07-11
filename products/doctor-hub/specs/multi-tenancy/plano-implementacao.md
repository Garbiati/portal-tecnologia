# Plano de implementação — Fundação de multi-tenancy

> Deriva de **SPEC-MULTI-TENANCY** (D-197..D-203). Método: **TDD, lotes pequenos** — cada lote escreve
> os testes a partir dos cenários da seção 4 da spec ANTES do código, sobe verde e é pushado (deploy em
> prod). **Tudo DEPOIS da demo de segunda** (que roda como Demandas/vê-tudo e não depende disto).
>
> Repos: `services/doctor-hub-api` (.NET 10) e, quando tocar tela, `services/doctor-hub-web`.
> Gate de cada lote: `dotnet test` verde + revisor-seguranca (LGPD/isolamento) + `/entrega`.

## Sub-fase 1 — hierarquia + vínculo + isolamento + vaga-por-vínculo  (decidida — D-197/198/199/200/202/203)

### Lote 1 — `Unidade` vira entidade
- **Entra:** `Domain/Unidade.cs` (`Id`, `ClienteId` FK, `Nome`, `Sigla`, `Ativo`); config no `AppDbContext`
  + migration; **seed** das unidades (recomeçar do seed — D-203); o claim `unidade` do token resolve pra
  `UnidadeId`/código estável.
- **Aceite:** unidade pertence a um cliente; seed carrega; token→unidade resolve. _(base pros cenários de
  contenção de escopo)_
- **Dep:** nenhuma. **Risco:** baixo (aditivo).

### Lote 2 — discriminador `ClienteId` no `Agendamento` (carimbado na criação)
- **Entra:** `Agendamento.ClienteId` (FK `Cliente`), preenchido no `POST /agendamentos` a partir da
  **`Unidade` que assumiu** (`Unidade.ClienteId`); migration; carimbo também no evento do **outbox**
  (habilita o filtro por tenant do pull+ack).
- **Aceite:** agendamento nasce com `ClienteId` derivado da unidade; sem unidade/cliente resolvível →
  fail-closed. _(cenário "discriminador obrigatório — fail-closed")_
- **Dep:** Lote 1.

### Lote 3 — vínculos N:N (`DoctorVinculo` / paciente) à la EMPI
- **Entra:** `DoctorVinculo` (doutor canônico ↔ **escopo poli-nível** `tenantId`+`clienteId?`+`unidadeId?`,
  com `DisabledAt`) — espelha `PacienteTenantRef` (D-191); estende o vínculo do paciente se preciso.
  Lógica de **contenção com cascata + estreitamento** (D-203 #1): um vínculo cobre um escopo se o contém.
- **Aceite:** cascata (vínculo no Cliente cobre suas Unidades; só na Unidade cobre só ela); N:N. _(cenário
  "contenção de escopo")_
- **Dep:** Lote 1.

### Lote 4 — isolamento por escopo vinculado (EF global query filter)
- **Entra:** filtro global nas entidades tenant-owned, keyed no **escopo permitido do principal** = união
  dos vínculos ativos (fila unificada — D-201), **default-deny** fora disso; **fail-closed** se o escopo
  não resolve. (Admin/Demandas = vê-tudo seguem por bypass explícito, como já é no RBAC.)
- **Aceite:** cenários "default-deny — sem vínculo não vê", "identidade compartilhada não vaza",
  "fila unificada dentro do escopo vinculado", "fail-closed".
- **Dep:** Lotes 2 e 3. **Risco:** ALTO (é a fronteira de segurança) → revisor-seguranca obrigatório,
  revisão humana das invariantes (núcleo crítico, não delegar cegamente).

### Lote 5 — vaga-por-vínculo (D-202)
- **Entra:** filtro da visibilidade de vaga — a vaga de um doutor só aparece/é agendável a um cliente se o
  doutor está **vinculado** a ele; **pool** (escala sem `ClienteId`) = disponível aos clientes vinculados
  do doutor; **dedicada** (com `ClienteId`) = reservada àquele cliente (D-203 #2).
- **Aceite:** o **cenário Doutor A/B** (guardrail) + "vínculo é gate ANTES do saldo".
- **Dep:** Lote 3.

> **Fecho da sub-fase 1:** com os 5 lotes verdes, a jornada escala→agendamento fica correta por vínculo
> (sem o saldo). A spec `multi-tenancy` pode ir a `specified` na parte de vínculo/isolamento/vaga.

## Encaixe seguinte — Agendamento resiliente Fase 2 (pull+ack, D-196)
- Engata **após o Lote 2** (precisa do `ClienteId` no agendamento) + auth por cliente (D-196). Contrato já
  fechado; ver `specs/agendamento-resiliente/spec.md` seção 4b. Worker/feature off até onboarding real.

## Sub-fase 2 — motor de visibilidade configurável (grants, D-201)  ⛔ aguarda discovery
- **Bloqueada pelos 🔴:** modelo do grant (papel × relação de cuidado/break-glass; granularidade) +
  consentimento/LGPD do paciente compartilhado. Discovery roda **em paralelo** à sub-fase 1.
- **Depois:** entidade/política de grant, visibilidade cruzada, trilha de auditoria de acesso cruzado,
  login do papel Doutor + escolha de contexto na fila unificada.

## Fase própria posterior — SALDO `min(pool, teto)` (D-190)
- Camada separada (7 abertas na D-190). Não bloqueia nada acima; entra depois.

## Ordem sugerida
1 → 2 → 3 → 4 → 5  (sub-fase 1)  ·  pull+ack após o Lote 2  ·  discovery da sub-fase 2 em paralelo  ·
grants (sub-fase 2)  ·  saldo (D-190).
