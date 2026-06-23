# Build Progress — Design System & Telas (loop autônomo)

> Estado vivo da construção no Figma (file NCMcYURZgrHH36f9DTk7di). Atualizado a cada iteração.

## ✅ Feito
- Tokens (`design/tokens.css`, `tokens.json`, `design-system.md`) — paleta AA.
- Figma Variables (coleção "Tokens").
- **UI Kit** (id 24:2): Button/Input/Badge/Chip/KPI + estados.
- **Visão geral** (id 28:2): KPIs + barras + atividade.
- **Remanejamento** (id 28:115): banner + janela + tabela origem→destino.
- **Configurações** (id 30:2) e **Auditoria/Logs** (id 30:180).
- **Painel/Visões** (id 32:2) e **Mapa de Cobertura** (id 32:126).
- **Estados** (board id 36:2): vazio · erro 403/500 · loading skeleton · toasts.
- **Clientes & HCs** (id 38:2): público/privado, segmented, tabela clientes + HCs por cliente.
- **Monitor de Integração** (id 40:2): alerta proativo + KPIs + funil 30d + tabela "em risco".
- **Board Apresentação · Fase 1** (id 42:2): filmstrip dos 6 passos do cockpit.
- **Board Apresentação · Fase 2** (id 44:2): Assunção→TC, Remanejamento, Auditoria, Configurações.

## ✅ Handoff dev
- **`design/components/`** (HTML/CSS): `components.css` (29KB, 0 hex, 100% tokens, WCAG AA, mobile-first), `index.html` (galeria), `README.md`. + tokens de transição em tokens.css.
- **`specs/*/ui.md`** (7 UI-specs + README-ui): layout, componentes, estados, responsivo, regras (Dxxx) + EARS. ✅
- Handoff completo (HTML/CSS + UI-specs). Specs ficam `draft` (têm perguntas abertas — correto).

## 🔴 Perguntas de negócio que as specs levantaram (precisam do humano)
- Regra da "janela de envio" que expira (causa dos 7,7%) — não definida.
- REGULA-HUB (AM/SISReg) é a mesma fonte do projeto (HC-SP)? Define se o Monitor lê da nossa integração TC ou de hub externo.

- **Paleta migrada** (it. 11): 6 telas de fluxo remapeadas p/ token (#2563EB etc.); boards Fase 1 (id 47:2) e Fase 2 re-clonados. Consistência total.

- **Mobile / Assunção** (it.12): lista (id 50:2) + bottom-sheet (id 50:58) — caso do Gestor no celular.

- **Navegação religada** (it.13): 14 telas, 101 links de sidebar, flow start no Login. Protótipo 100% navegável.

- **Arquitetura** ✅ (it.13b, agente): `docs/architecture/` 5 docs (C4, domínio+invariantes, system design, SDD+TDD+paralelização 6 ondas, README). 39 .md no projeto.

- **Board "Capa / Índice"** (it.14, id 54:2): título + problema + 6 cards de índice + rodapé de handoff. No topo (y=-1280).

> ESTADO: arquivo Figma profissional e completo — capa + 19 telas/boards navegáveis (desktop+mobile) + UI Kit + Estados + 2 apresentações por fase. Handoff (HTML/CSS + UI-specs) + arquitetura completos.

- **Mobile / Solicitação** (it.15, id 56:2): Secretário no celular — HC+mês, especialidades+qtd, Enviar.

## ✅ ENTREGÁVEL SEMANA 0 — COMPLETO (2026-06-14)
Capa/índice + 21 telas/boards navegáveis (desktop+mobile) · UI Kit · Estados · 2 apresentações por fase ·
handoff (design/tokens.css + design/components HTML/CSS + 7 specs/*/ui.md com EARS) · arquitetura (5 docs) ·
39+ docs · 20 decisões. Paleta-token AA consistente. Protótipo 100% navegável (start no Login).

## 🟦 O que resta NÃO é construção autônoma — depende do humano
- 🔴 Regra da "janela de envio" (gatilho do Monitor / 7,7%) — indefinida.
- 🔴 Fonte do funil: integração TC vs hub externo (AM/SISReg) — confirmar.
- 🟡 Stack ainda aberta (D-001); escopo/fase a aprovar; **homologação** (fecha a Semana 0).
- Próximas telas só fazem sentido após essas respostas (não inferir).

## 🔼 Incremento do loop (2026-06-14, 2ª direção): aprofundar a Semana 0 + material C-level/técnico
Token liberado; muitos agentes em paralelo. Objetivo: demonstrar TUDO o que cabe num Figma+repo (telas, regras, roadmap, custo/ROI, tradicional×AI-Driven, governança/segurança), nível técnico E C-level com big numbers/ROI.

### Docs (5 agentes paralelos) — ✅ TODOS PRONTOS
- ✅ docs/business/executive-pitch.md · cost-roi-analysis.md · traditional-vs-ai-driven.md
- ✅ docs/product/08-roadmap-detalhado.md (gantt + S0–S58 + 6 ondas + marcos M0–M7)
- ✅ docs/discovery/06-regras-de-negocio.md (50 RN + 8 INV + 23 perguntas abertas QA-01..23)

### Boards Figma (apresentação) — banda y=-1280 — ✅ COMPLETA
- ✅ Capa/Índice (54:2) · Antes×Depois (58:2) · Tradicional×AI (60:2) · Custo&ROI (62:2) · Roadmap (64:2) · Regras de Negócio (66:2)

## ✅ INCREMENTO 2 — COMPLETO (2026-06-14)
Semana 0 aprofundada ao máximo demonstrável: 6 boards C-level + 5 docs (pitch, custo/ROI, tradicional×AI, roadmap detalhado, 50 RN) somados ao produto (21 telas navegáveis, UI Kit, Estados, 2 apresentações por fase, mobile, handoff HTML/CSS+UI-specs, arquitetura 5 docs). ~45 docs no projeto.

## 🔧 PRIMEIRA ENTRESA — protótipo ÚNICO (2026-06-14, 4ª direção) — ver D-027/028/029, product/10
- ✅ **Consolidado**: removidas 3 telas antigas (Login/Visão geral/Médicos & Escala duplicadas); v2 renomeadas p/ oficiais; 1 flow só ("Entrega 1 · Login → Sistema"); navegação religada (97 links). 15 telas, 0 duplicatas, 0 sufixo "v2". **Sem 'antiga/v2/legado'.**
- Escopo CORRIGIDO: Primeira Entrega vai ATÉ o agendamento na TC (D-027). Slots CONCRETOS (D-028). Agendamento = doutor+paciente no slot (D-029).
- ✅ **Tela Agendamento** (id 95:2, y=15300): grade de slots concretos (Cardio 20min, Seg–Sex, livre/reservado/agendado) + painel atribuir Dr. Fernando + paciente Thiago no slot Ter 08:00–08:20 → TC. (slot/duração derivado da escala, D-028)
- ✅ **Fluxo ligado**: Solicitação→Enviar→Disponibilização→Emitir/Reserva→**Agendamento**→Confirmar→Visão geral.
- ✅ **Boards de persona re-clonados** das telas oficiais (Gestor agora termina no Agendamento, id 98:881).
- 🟡 não inferir: quem agenda (gestor/operador); seleção do doutor (preferencial D-011 vs manual).

## ✅ PRIMEIRA ENTREGA — fluxo montado e navegável (aguarda homologação)
Protótipo único consolidado + tela de Agendamento (slots concretos + doutor+paciente→TC) + fluxo ponta a ponta + 3 boards de persona. Aguarda homologação do Alessandro e as 2 🟡.
→ Loop volta a manutenção até homologação/feedback.

## 🔁 (histórico) LOOP DE HOMOLOGAÇÃO v2
Refazer telas conforme D-021..D-025 / discovery/07 / product/09. Versões "v2" ao lado (nada destrutivo), em y=11000+.
- ✅ **Visão geral v2** (id 74:2, y=11000): KPIs solicitado/disponibilizado/saldo/em-risco + tabela por especialidade + por health center + variantes por perfil.
- ✅ **Login v2** (76:2) + **Login · erro** (76:20): banner + bordas vermelhas; fluxo ligado (feliz→VG v2 / infeliz→erro→VG). flowStartingPoint "Login (feliz/infeliz)".
- ✅ **Médicos & Escala v2** (78:2): busca na TC + presets + 3 blocos (incl. 22:00–02:00 "vira o dia") + validação sem-overlap + vigência (ativar/inativar total/parcial) + rastreabilidade + nota produtividade futura.
- ✅ **Apresentações por persona** (3 boards, banda y=-3500..-5200): Persona Admin (81:2), Persona Solicitante, Persona Gestor — filmstrip só com a jornada de cada persona, do Login em diante.

## ✅ LOOP DE HOMOLOGAÇÃO v2 — fila COMPLETA (aguarda homologação do Alessandro)
4 entregas do feedback prontas: Visão geral v2 (74:2) · Login v2 (76:2)+erro (76:20) com fluxo · Médicos & Escala v2 (78:2) · 3 boards por persona (81:2…). Tudo em y=11000+ (telas) e y=-3500..-5200 (boards), ao lado das atuais. Nada destrutivo.
PENDENTE (humano): homologar cada uma; 🔴 busca de profissional na TC; 🔴 board do ClickUp da Entrega 1.
→ Loop volta a cadência de manutenção até o Alessandro homologar / dar nova direção.
- 🔴 pendências humano: endpoint de busca de profissional na TC · board do ClickUp que define a Entrega 1.

## ⏸️ (histórico) Cadência → manutenção
Não há mais valor incremental construível sem input do humano. O que falta é: homologar; responder as 2 🔴 (janela de envio; fonte AM/SISReg); aprovar escopo/stack/valor-hora. Loop em cadência longa até direção/parar.

## 🔎 Achados da planilha (agente, `docs/discovery/05-processo-manual-excel.md`)
- Excel hoje é REATIVO: ~7,7%/mês perdido por "janela de envio expirou" (visível só depois). → **Nova tela proposta: "Monitor de Janela/Integração"** (funil + ALERTA antes da janela expirar = diferencial).
- Params úteis: SLA agendamento→atendimento 15 dias; 3 consultas/hora/especialista; plantão mín. 4h.
- ⚠️ Aberto: planilhas são da Saúde AM Digital (AM/SISReg) — confirmar se é o mesmo cliente do HC-SP.

## 🔼 Escopo do loop incrementado (direção 2026-06-14)
- Conceito **Cliente público/privado** acima de HC (D-018) → nova tela "Clientes & HCs".
- **Problema-núcleo = sair do Excel** (D-019); agente analisando a planilha real → `docs/discovery/05-processo-manual-excel.md`.
- **Apresentação por fase** isolada no Figma (D-020): boards "Apresentação · Fase 1" / "Fase 2".
- Usar **agentes especializados em paralelo** (xlsx, arquitetura, UI-specs, HTML/CSS).
- Construir **estrutura local (SDD/TDD)** que valida o Figma e vice-versa; nada destrutivo.
- Marca PTM depois (logos em ~/Downloads/Logos Portal...). Rodar **até o usuário pedir para parar**.

## ⏭️ Fila (posicionar novas telas em y=6790+)
1. Tela **Clientes & HCs** (público/privado) + multi-cliente em Solicitação/Painel — **próxima**
2. Board **Apresentação · Fase 1** (só telas do cockpit "sair do Excel")
3. Incorporar achados da planilha (quando o agente terminar)
4. Migrar as 6 telas do protótipo de fluxo p/ paleta-token + sidebar consolidada
5. Responsividade (Gestor mobile) + religar navegação
6. design/components/ (HTML/CSS) + UI-spec por tela + doc de arquitetura

## ⚠️ Lições de integração (não repetir)
- **NUNCA terminar build com `throw`** → Figma faz ROLLBACK. `throw` só em scripts de LEITURA (recuperar ids).
- `resize(w,h)` em frame auto-layout **fixa aquele eixo** (vira FIXED). Para manter hug: `counterAxisSizingMode="FIXED"; resize(w,1); primaryAxisSizingMode="AUTO"`.
- Frames auto-layout nascem FIXED 100×100 → setar sizing "AUTO". `counterAxisAlignItems` não aceita "STRETCH" (usar child `layoutSizingVertical="FILL"`). Sempre `appendChild` o input dentro do field.

## Convenções
- Paleta-token: acc #2563EB, accSub #EFF6FF, bg #F1F5F9, sec #475569, muted #64748B (ver tokens.css).
- Posições: protótipo de fluxo grade 2×3 (x0..2980); boards UI Kit/Estados em x3260; telas paleta-token em y=3400+.
