# Plano de maturidade — elevar o score do que está no NOSSO controle

> Base: auditoria de maturidade 26/06 (3 agentes: frontend, backend, escopo) + `docs/design/figma-app-audit.md`.
> **Princípio:** este plano ataca só o **acionável por nós** — sem depender das **credenciais/homologação da
> Teleconsulta** (DEP-TC-1/2/3, externas) nem de **regras de negócio que precisam da sua decisão** (Diretriz
> Suprema). O que é bloqueado fica listado em "Fora de escopo (por quê)".

## Baseline (scorecard atual)
| Eixo | Hoje | Alvo deste plano |
|---|---|---|
| Arquitetura/técnica | 🟢 5/5 | mantém 5 |
| Dados/domínio (backend) | 🟢 5/5 | mantém 5 |
| Cobertura de telas | 🟢 4/5 | 5 |
| Sync Teleconsulta | 🟡 3/5 | 3→3.5 (contrato/teste; ligar = bloqueado) |
| **Backend escrita/CRUD** | 🔴 2/5 | **4** |
| **Integração backend (front)** | 🔴 1/5 | **3–4** |
| Auth | 🔴 0/5 | 0→1 (scaffold, sem escolher IdP) |
| Segurança/LGPD | 🟡 2/5 | 3 |
| Testes (back) | 🟢 4/5 | 5 |

**Métrica de sucesso:** ficha do médico (dados + faturamento + RQE) **persiste no Postgres** (hoje é sessão);
2 endpoints → ~8; segurança endurecida sem auth real; densidade + estados de erro fechados. Tudo com teste.

---

## Ondas (prioridade por ROI no score)

### ✅ 🌊 Onda 1 — Persistir a ficha do médico no backend (FEITA — D-138, 26/06)
> **Concluída e provada E2E** (edição pelo UI → Postgres). Backend escrita 2→4, Integração front 1→3.
> Itens originais abaixo (todos entregues, exceto concorrência = flag).
> Hoje o front edita dados/faturamento/RQE só na **sessão** (some ao recarregar). Mover pro Postgres
> usa o domínio que já existe + pequenas adições de schema. **Sem regra nova** (modelo = D-125/126 + tipos do front).
- [ ] **Schema:** colunas de cadastro no `Doctor` (nascimento/telefone/email) + tabela/colunas de **faturamento por especialidade** (modo/valor/tempo) em `DoctorEspecialidade` + tabela **FaturamentoLaudo** (exame/valor). Migration.
- [ ] **Endpoints de escrita:**
  - `PUT /api/doctors/{id}` — dados cadastrais (NOME/CRM travados; CPF/nasc/tel/email).
  - `PUT /api/doctors/{id}/especialidades/{espId}` — RQE + faturamento (modo/valor/tempo); `POST`/`DELETE` p/ vincular/remover.
  - `POST`/`PUT`/`DELETE /api/doctors/{id}/laudos` — telediagnóstico.
  - `PATCH /api/doctors/{id}/status` — inativar/reativar (soft).
- [ ] **Front:** trocar os `Promise.resolve(fixture)` por `http<T>()` em `api.ts` (a assinatura já é a final); a ficha passa a ler/gravar do backend.
- [ ] **Concorrência:** last-write-wins por ora (🚩 edição concorrente = pergunta aberta — não resolver agora).
- [ ] **Testes:** WebApplicationFactory + InMemory por endpoint (criar/editar/remover + 400 inválido).
- **Lift:** Backend escrita 2→4 · Integração front 1→3 · Testes back +.

### 🌊 Onda 2 — Endurecer segurança do backend (sem auth, sem decisão)
> Não resolve o "auth 0%", mas tira os furos óbvios que não dependem de ninguém.
- [ ] **CORS por allowlist** (env `Cors:Origins`) no lugar de `AllowAnyOrigin`.
- [ ] **Validação de entrada** nos endpoints (length/obrigatório → 400 com problema), além do MaxLength do banco.
- [ ] **Rate limiting** básico (ASP.NET `RateLimiter`, fixed window) nos endpoints públicos.
- [ ] **Connection string** com `SSL Mode` documentado p/ prod (Cloud SQL).
- [ ] **Log estruturado** de request (correlação) — base de observabilidade.
- [ ] (CPF **não** mascarado segue **decisão sua** — não mexo.)
- **Lift:** Segurança 2→3.

### 🌊 Onda 3 — Polimento do front (telas + dívida + Conta)
- [ ] **Estados de erro/vazio** nos 2–3 fluxos que o agente apontou (UX defensiva).
- [ ] **Densidade (Confortável/Compacto)** em Configurações — UI pura, mesmo padrão do tema (fecha + um pedaço do gap de Conta).
- [ ] **Notificações** — alinhar os 3 toggles do Figma (Escala criada/arquivada, Pendências de cadastro, Resumo semanal).
- [ ] **Reduzir dívida** onde virou real: trocar `PROVISÓRIO`/fixture pelos endpoints da Onda 1.
- **Lift:** Telas 4→5 · Dívida 2→3.

### 🌊 Onda 4 — Scaffold de auth (prepara, sem escolher o IdP)
> Não decide D-109 (Identity vs IdP da Portal) — só deixa o terreno pronto pra plugar.
- [ ] **Middleware de auth atrás de flag** (`Auth:Enabled`), com claims de papel (RBAC) e proteção dos endpoints de escrita.
- [ ] **Token de dev** (sessão local) p/ exercitar o fluxo; troca pelo IdP real é localizada.
- [ ] 🚩 **Escolha do IdP fica com você** (D-109) — não inferida.
- **Lift:** Auth 0→1 (scaffold).

### 🌊 Onda 5 — Profundidade de teste do sync (sem ligar contra a TC)
- [ ] **Teste de contrato** do `TeleconsultaDoctorSourceDapper` contra um schema-fake documentado (o mapeamento segue pergunta aberta, mas o shape fica coberto).
- [ ] Testes dos endpoints de escrita (Onda 1) e do watermark.
- [ ] (Teste contra **Postgres real** só na sua máquina — sandbox sem rede host↔container; deixar script pronto.)
- **Lift:** Testes back 4→5 · Sync 3→3.5.

---

## Fora de escopo deste plano (BLOQUEADO — por quê)
- 🔴 **Ligar o sync ao vivo da TC** — query Dapper é rascunho + **mapeamento = pergunta aberta** + **credencial real não chegou (DEP-TC-1)**. Não ligar sem confirmar.
- 🔴 **Envio de agendamento à TC** — **credencial/homologação externas (DEP-TC-1/2)**.
- 🔴 **Regras de demanda/cockpit** (modelo de solicitação, prazo/urgência, cobertura parcial, KPIs da Home) — **suas decisões** (31 🔴 abertas).
- 🔴 **LGPD** (base legal, retenção, minimização de dado de paciente) — decisão legal/produto.
- 🔴 **Auth real (IdP)** — D-109, sua escolha (a Onda 4 só prepara).

---

## Sequência recomendada
**Onda 1 primeiro** (maior salto: escrita + integração + persistência da ficha), depois **2** (segurança) e **3** (polimento) em paralelo de baixo risco; **4** e **5** quando você quiser preparar auth/sync.

> Efeito esperado no score global: backend de leitura-only → **CRUD persistente da ficha**; "1ª entrega" sobe
> de ~70–75% para ~80–85%; produção continua limitada pelos bloqueios externos/decisões (esperado).
