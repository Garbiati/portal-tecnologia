# Plano da Sessão Autônoma (noite 2026-06-15 → manhã 2026-06-16)

> Alessandro foi dormir 23:38 BRT e pediu: deixar a **Entrega 1 (Médicos & Escala / Doctor-Hub)**
> o mais perfeita possível, em **modo auto** (sem pedir permissão), **tudo local**, sem comprometer
> a entrega. Lançar agents de maturidade/código/performance/arquitetura/SDD+TDD/AI. Avisar às 07h BRT.

## 🔒 Travas de segurança (válidas a noite toda)
- **NÃO inventar regra de negócio** (Diretriz Suprema). Dúvida → escolha conservadora + `// PROVISÓRIO`
  + registrar em `docs/discovery/03-open-questions.md`. Nunca bake-in silencioso.
- **NÃO `docker compose down -v`** — apagaria os 4.523 médicos reais (não há seed). Só migrations
  ADITIVAS + `up --build` (preserva o volume). Se precisar recriar, re-rodar a sync de prod.
- **NÃO escrever na produção da Teleconsulta** (só RO). Sem segredos no código.
- Manter o app **buildando e servindo** a cada iteração (tsc/eslint/dotnet build + smoke test).
- Sem ações externas (nada de push, deploy, e-mail, posts).

## 🎯 Escopo da Entrega 1 (já decidido — D-052/D-063…D-066)
Cadastro-DONO do médico + escala mensal (fixa + adicional) sobre **dados reais de produção**.

## Backlog priorizado (faço nesta ordem; o crítico primeiro)
1. **[UI] Wizard Médicos & Escala** no novo modelo (D-066): 1 Localizar · 2 Cadastro (multi-especialidade
   + RQE por especialidade, valores) · 3 Escala (vigência hoje→fim do mês, especialidade, períodos,
   histórico ativa/arquivada) · 4 Adicional (só sobre escala ativa; valor default do cadastro). Remove
   selo "importado"; some com a palavra "blocos".
2. **[Data layer] store/api** → ligar nas rotas novas (`/api/doctors/{id}/specialties`, `/schedules`).
3. **[Testes/TDD]** projeto de testes backend (xUnit) p/ invariantes: 1 escala ativa, replace de
   especialidades, validações, arquivamento. Vitest p/ a lógica de `escala.ts` (slots/sobreposição).
4. **[Funcional]** testar escala: inserir, excluir, arquivar, simular capacidade. Corrigir bugs.
5. **[Auditoria multi-agente]** (Workflow): código, performance, arquitetura, segurança, a11y (WCAG AA),
   SDD+TDD, maturidade. Aplicar achados de alta confiança; registrar o resto.
6. **[UI] Visão geral → KPIs da Fase 1** (médicos com/sem escala, capacidade por especialidade, cadastros incompletos).
7. **[IA] Menu "Cadastros" com submenu por perfil** (D-062) — Médicos/Admin/Solicitantes/Regionais.
8. **[Polish]** estados vazios/erro, acessibilidade, consistência de tokens, mensagens.
9. **[Docs]** BUILD-PROGRESS, decisions, open-questions, e o **relatório da manhã**.

## 📈 Log de progresso (append a cada iteração)
- **23:42 BRT** — Plano criado. Fundação backend do novo modelo (D-063/064) pronta e testada na rodada
  anterior (migration 008, endpoints specialties/schedules, smoke 200/201). Próximo: iteração 1 (wizard UI).
- **23:50 BRT** — ✅ **Iteração 1 (wizard UI) concluída.** `MedicosEscalaPage` reescrita como wizard de 4
  passos (Localizar → Cadastro c/ multi-especialidade+RQE → Escala mensal c/ vigência+histórico → Adicional).
  Nova data layer `app/src/data/doctorProfile.ts`. tsc/eslint/build limpos; web rebuildado; **fluxo testado
  ponta a ponta via API** (PUT specialties, PUT cadastro, POST schedule ativa, GET lista). 3 PROVISÓRIOs
  registrados em `03-open-questions.md`. Próximo: iteração 2 — testes automatizados (TDD) + teste funcional
  (excluir/simular) + 1ª auditoria multi-agente.
- **00:49 BRT** — ✅ **Iteração 2 (parte 1).** Vitest instalado + `app/src/data/escala.test.ts` com **20 testes
  passando** (slots, duração, sobreposição incl. cruzar meia-noite e wraparound Sáb→Dom, presets, slotKey).
  Scripts `test`/`test:watch` no package.json. **Auditoria multi-agente lançada em background** (Workflow
  `phase1-audit`, 7 dimensões + verificação adversarial). Próximo: teste de integração do backend + processar
  achados da auditoria quando chegar.
- **01:1x BRT** — ✅ **Auditoria processada (29 achados confirmados de 50; 57 agents).** A verificação
  adversarial rebaixou muitos p/ low e marcou vários como 'question' (regra de negócio → registrados em
  open-questions, NÃO inferidos). **Batch A (backend correção/segurança) corrigido + testado:**
  (1) **D-065** agora validado no backend (adicional exige escala ATIVA + valor obrigatório);
  (2) **GET /api/doctors/{id} (PII) restrito a admin/demandas** (LGPD; espelha PUT+nav);
  (3) colisão de escala ativa → **409** (não 500); (4) horário malformado → **400** (não 500);
  (5) **WeekOverlap** helper único (matou a tripla duplicação front/2-back); (6) param morto removido;
  (7) limites de tamanho no PUT; (8) comentário de serialização corrigido. Backend build limpo;
  **teste de integração agora 24/24** (tests/test_api.py, cobrindo os fixes). Próximo: Batch B (a11y +
  loading state + memo no front) e Batch C (perf: N+1/hydration). Achados 'question' → open-questions.
- **04:08 BRT** — ✅ **Batch B (a11y + UX) aplicado e deployado.** 7 fixes em MedicosEscalaPage: loading
  state no passo Escala (não mostra mais "sem escala" durante carregamento), memo em EscalaCard,
  associação de erros (aria-invalid/describedby + role=alert), aria-current sem aria-pressed nos passos,
  readOnly-only na identidade, ● aria-hidden, role=group + aria-pressed nos presets. tsc/eslint/build/
  20-testes-front OK; web rebuildado; **regressão integração 24/24**. NOTA de tempo: ops lentas (latência),
  ~3h pro deadline. Próximo: Batch C (perf N+1/hydration — se tempo/risco permitir) e RELATÓRIO da manhã.
- **04:13 BRT** — ✅ **Batch C (perf) — N+1 da busca eliminado.** Novo endpoint em lote
  `GET /api/doctors-schedule-flags?ids=` (1 query devolve quem tem escala ativa) + `getActiveScheduleFlags`
  no front; StepLocalizar trocou o loop de 8 GETs por 1 chamada. Build/lint/test/regressão 24/24 OK.
  **Follow-up documentado (não feito — risco):** a hidratação carrega todos os médicos no login; trocar
  por busca server-side (debounce + LIMIT) é o próximo passo de perf. Próximo: Dashboard Fase-1 (KPIs
  factuais, PROVISÓRIO) + relatório da manhã.
- **04:19 BRT** — ✅ **Dashboard Fase-1** (substitui o funil vazio das Fases 2–4). Endpoint factual
  `GET /api/dashboard/phase1` (admin/demandas): médicos cadastrados / com escala ativa / sem escala /
  cadastros incompletos + capacidade por especialidade. DashboardPage reescrita (loading/erro graceful;
  solicitante→403 tratado). Testado (4.523 base, capacidade aparece ao criar escala). +Testes vitest dos
  helpers de data (off-by-one de fuso, fim-de-mês bissexto) → **29 testes front + 24 integração**, todos
  verdes. KPI-set marcado PROVISÓRIO (open-questions). Próximo: relatório da manhã + polish final.
- **04:30 BRT** — ✅ **Re-revisão focada (agent cético) das mudanças da noite: ZERO regressões** crit/high/med.
  1 achado low (try/catch no lançar-adicional) **corrigido**. ✅ **Relatório da manhã** escrito
  (`14-relatorio-manha-2026-06-16.md`). ✅ **CLAUDE.md atualizado** (Fase 6 Construir; Doctor-Hub em
  homologação; Diretriz Suprema + riscos preservados). **Convergindo:** trabalho seguro de alto valor
  concluído; itens restantes (menu Cadastros D-062, perf hidratação, xUnit) ficam p/ o Alessandro ver
  (risco/design). Heartbeat longo até ~05:30 → reverificar saúde → wrap-up final ~06:30-06:45.
- **05:34 BRT** — ✅ Saúde reverificada após 1h (containers up, /health ok, 4.523 médicos). Criado
  **README de topo** (handoff: como rodar, login, testes). **Verificação final TODA VERDE:** front tsc +
  29 testes, backend build, 24/24 integração. App estável/completo no escopo seguro. Último heartbeat até
  ~06:35 → checagem final + fecho o relatório + paro o loop.
