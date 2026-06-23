# Passar a limpo — Figma Fase 1 (Médicos + Escala) — LOG DA NOITE

> Sessão autônoma 2026-06-16 ~23h→06h BRT. Objetivo (Alessandro): criar um **Figma novo, limpo**,
> levando só o necessário da **Etapa 1 = Gestão de Médicos + Escala**; homologar se atende.
> Regras: app/código = fonte da verdade; **não inferir regra de negócio**; marca D-074; redesign D-075.

## Arquivos Figma
- **NOVO (limpo, alvo):** `snTNGRUJO2GwoKpXTHCBjf` — https://www.figma.com/design/snTNGRUJO2GwoKpXTHCBjf
- ANTIGO (referência, confuso/legado): `NCMcYURZgrHH36f9DTk7di` (v2 Escala já refinada: Ativo 158:2 etc.)

## Plano
1. [ ] Fundação no arquivo novo: Tokens (vars da marca) + páginas (Médicos, Escala, 🎨 Base) + shell v2 (sidebar+perfil).
2. [ ] **Médicos** (do código MedicosPage.tsx): Localizar + Ficha (Dados: CPF-máscara, Nascimento≥18, Tel, E-mail, Valor fixo/adicional, Especialidades+RQE, Editar/Salvar; Histórico LGPD; Escala-resumo + "Gerenciar escala →") + estados (ver/editar, vazio).
3. [ ] **Escala** (porta a v2): Ativo, Localizar(+filtros), Criar(+erro,+sem-esp), Vazio, Arquivado/Histórico, Reativar-bloqueado, Confirmações, Modais (Linha do tempo, Horas adicionais ±preenchido) + protótipo navegável.
4. [ ] Homologação: comparar contra o checklist (agent) → fechar lacunas.

## Checklist de aceite (Fase 1)
- PRONTO em `docs/design/fase1-acceptance-checklist.md` (agent, fundamentado em D-NNN+código).
- Divergências a corrigir no rebuild: "Confirmar arquivamento" NEUTRO (não vermelho) [D-075d]; rótulo "Horas adicionais"; badge slots/semana azul-info; timeline+horas = modais.

## Tokens do arquivo NOVO (snTNGRUJO2GwoKpXTHCBjf) — ids p/ binding
collection VariableCollectionId:1:2 · mode 1:0
primary 1:3 · primary-subtle 1:4 · surface 1:5 · surface-muted 1:6 · bg 1:7 · border 1:8 · border-strong 1:9 ·
text 1:10 · text-secondary 1:11 · text-muted 1:12 · accent 1:13 · accent-hover 1:14 · accent-text 1:15 · accent-subtle 1:16 ·
action 1:17 · action-hover 1:18 · text-on-action 1:19 · success 1:20 · success-bg 1:21 · danger 1:22 · danger-bg 1:23 · warning 1:24 · warning-bg 1:25
Páginas: Médicos 0:1 · Escala 1:26 · 🎨 Base 1:27

## INVENTÁRIO FINAL (arquivo novo, 1 página "Doctor-Hub · Fase 1 (fluxo)" id 0:1)
Médicos (y=120): Ficha-ver **5:2** · Localizar **16:2** · Ficha-editar **17:2**
Escala (y=1820): Ativo **2:2** · Localizar **8:2** · Vazio **9:2** · Criar **10:2** · Arquivado/Histórico **12:2** · Confirmações **13:2**
Modais/erros (y=3100): Modal-Linha-do-tempo **14:2** · Modal-Horas-preenchido **15:2** · Criar-erro **22:2** · Criar-sem-especialidade **22:124**
Protótipo: 1 página (cross-page NÃO funciona via API → consolidei tudo numa página). Flow start = Médicos Localizar 16:2. Sidebar nav (Médicos/Escala) + handoffs (Gerenciar escala→Ativo, Ver cadastro→Ficha) ligados. Filtros Com/Sem escala = não navegam (sem variantes filtradas no arquivo novo).

## HOMOLOGAÇÃO (vs checklist) — cobertura
Médicos: ✓ título/sub · ✓ Localizar(+filtro/badges) · ✓ contexto · ✓ Dados ver+editar (CPF,Nascimento,Tel,Email,Valores, Nome/CRM locked, Especialidades+RQE, Editar/Salvar/Cancelar, Add/Remover) · ✓ Histórico LGPD · ✓ Escala-resumo + Gerenciar escala. GAPS menores: nota "Faltam p/ faturamento", estado CPF-inválido, empty/overflow do Localizar (não montados).
Escala: ✓ título 1× · ✓ Localizar · ✓ 1 CTA laranja · ✓ card ativo (badges info/ativa/slots-azul) · ✓ Criar(+erro+sem-esp) · ✓ métrica herói+Realizados · ✓ timeline MODAL · ✓ Arquivar(confirm NEUTRO) · ✓ Reativar(last+nota) · ✓ Excluir(danger) · ✓ Histórico · ✓ Horas adicionais MODAL · ✓ Vazio · ✓ Confirmações. GAPS nice-to-have: Reativar-bloqueado(há ativa), timeline-várias, Horas-vazio.
**Todos os [Required] do checklist cobertos.** Divergências D-075 aplicadas (Confirmar arquivamento neutro; rótulo Horas adicionais; slots azul-info).

## Progresso (atualizar a cada ciclo)
- 23:07 — arquivo novo criado; código Médicos lido; doc iniciado.
- 23:20 — tokens(1:3..1:25)+páginas criados; checklist de aceite salvo.
- **~01:00 — CONCLUÍDO + HOMOLOGADO.** Arquivo novo `snTNGRUJO2GwoKpXTHCBjf` (1 página, 13 frames: 3 Médicos + 6 Escala + 2 modais + 2 erros-de-criação). Protótipo navegável (início Médicos Localizar). Todos os [Required] do checklist cobertos; divergências D-075 corrigidas. Verificação visual de Ativo, Médicos-ver, Médicos-editar, Criar, Localizar, Vazio(implícito), Arquivado, Confirmações, Modal-Horas = OK. Registrado D-077. **Parei a construção aqui** (entregável central completo bem antes das 6h; resto = nice-to-have, melhor com você acordado p/ não introduzir erro sem supervisão).
  Nice-to-have pendentes (opcionais, não-Required): Médicos[Localizar empty/overflow, estado CPF-inválido, nota "Faltam p/ faturamento"], Escala[Reativar-bloqueado, timeline-várias, Horas-vazio], filtros Com/Sem navegáveis. Próximo grande passo real = espelhar no CÓDIGO (tokens marca + Montserrat + telas).
- 23:35 — **Escala·Ativo PRONTO** (page Escala 1:26, root 2:2, content 2:21) — 1:1 da v2, "Horas adicionais", Arquivar neutro, Excluir vermelho. **Médicos·Ficha(ver) PRONTO** (page Médicos 0:1, root 5:2, content 5:21) — Dados+Especialidades/RQE+Histórico LGPD+Escala-resumo c/ "Gerenciar escala →".
  PENDENTE: Escala[Localizar, Criar, Vazio, Arquivado/Histórico, Reativar-bloq, Confirmações, Modais timeline+horas±preenchido] · Médicos[Localizar, Ficha-editar] · wiring · homologação.
  Fix de consistência: badge "slots/semana" em Médicos-resumo está verde(success) → deveria ser azul-info como na Escala [D-075b]. Confirmar arquivamento = NEUTRO.
  Técnica: clonar Ativo 2:2 p/ os estados que compartilham shell (Criar/Vazio/Arquivado/Reativar/Confirmações) e trocar o corpo; Localizar = corpo próprio; modais standalone.

## Sessão 2026-06-17 (manhã) — Home + gaps + protótipo 100% clicável
> Pedido do Alessandro: "todos os use cases no Figma, todas as opções clicáveis; doutor com/sem escala,
> ativas e inativas, timeline, horas adicionais lançadas, **home com big numbers e insights**; protótipo
> 100% navegável". Depois: gestão de perfil do doutor.

**Novos frames (arquivo `snTNGRUJO2GwoKpXTHCBjf`, página 0:1):**
- **Início · Visão geral (Home)** `28:2` — banda nova no topo (x=160, y=-1400). Fiel ao `DashboardPage.tsx`:
  4 big numbers (Médicos cadastrados / Com escala ativa / Sem escala / Cadastros incompletos), card
  **"Como estão as escalas"** (barra de cobertura 14% + 3 insights factuais derivados), tabela
  **Capacidade por especialidade**. Nav "Visão geral" ativa. ⚠️ Números são **ilustrativos** (protótipo) e os
  KPIs seguem **PROVISÓRIOS** (decisão de produto — `03-open-questions.md`).
- **Modal · Horas adicionais · vazio** `37:2` (x=6320, y=3100) — clone do preenchido com tabela vazia.
- **Escala · Reativar bloqueado (há ativa)** `39:2` (x=9400, y=1820) — header "tem escala", banner de ativa,
  nota "Arquive a escala ativa para poder reativar a anterior." (sem botão Reativar).
  (Timeline c/ ativa+arquivada e Horas-preenchido já existiam — gaps "timeline-várias"/"horas-vazio" cobertos.)

**Wiring (protótipo navegável) — início do fluxo trocado para a Home `28:2`:**
- `nav/Visão geral → Home` em **todos** os 12 frames com sidebar (antes nunca ligado).
- Modais (Linha do tempo, Horas ±) → ✕/Fechar/Cancelar/Lançar **voltam pra Ativo**.
- Criar → Criar escala/Cancelar → Ativo. Confirmações → Confirmar→Histórico, Excluir→Vazio, Cancelar→Ativo.
- Localizar (Escala): todas as DoctorRows navegam (→ Ativo; 1 → Vazio). Home: 4 KPIs → Médicos/Escala Localizar.
- "+ Criar nova escala" no Histórico e no Reativar-bloqueado → Criar.
- **Pendência menor:** filtros segmentados Com/Sem escala ainda não navegam (precisariam de frames de lista filtrada).

**Próximo (pedido do Alessandro):** gestão de **perfil do doutor** (telas de cadastro/edição do médico já
existem em Médicos `5:2`/`17:2`; aprofundar conforme ele definir).

## Sessão 2026-06-17 (cont.) — Figma-first da 1ª entrega + Perfil do doutor
> Alessandro: "esquecer o código e deixar tudo o que precisamos da 1ª entrega no Figma." Escopo confirmado:
> Perfil do doutor + Configurações + Perfil do usuário + Login. Começamos pelo Perfil do doutor.

**Perfil do doutor aprofundado (Médicos · Ficha-ver `5:2`):**
- Cabeçalho: badge **status "● Ativo"** + ação **"Inativar médico"** (provisória) + faixa de **metadados**
  (Origem sync RO · ID externo · criado/atualizado).
- Card de Dados ganha **nota de completude** ("✓ Cadastro completo p/ faturamento").
- Nova seção **Provisionamento · destinos** (Teleconsulta ✓ provisionado / Telediagnóstico a provisionar),
  com tag **"provisório — mecanismo a definir (D-055)"**.
- **Estados novos** (frames, banda Médicos): incompleto `51:2` (nota de faturamento em warning, CPF/valor "—"),
  editar·**CPF inválido** `52:2` (erro + Salvar desabilitado), Localizar·**vazio** `54:2`, **inativo** `55:2`
  (status Inativo + Reativar + banner explicando propagação à TC pendente).
- Wiring: Inativar→inativo→Reativar; 1 row do Localizar→incompleto→Editar(CPF inválido)→Cancelar.
- ⚠️ **Status/inativação e provisionamento são UI provisória** — a regra/mecanismo segue como pergunta aberta
  (D-055 + `03-open-questions.md`); não foi inferida. **Pendente:** Localizar overflow; confirmação inline de inativar.

## Sessão 2026-06-17 (cont. 2) — Conta (Perfil/Configurações) + Login → 1ª entrega completa no Figma
**Novos frames:**
- **Conta · Perfil do usuário** `57:2` (banda Conta, y=4400): avatar + identidade (Nome, E-mail/Papel travados,
  Organização) ver/editar, sub-abas Perfil|Configurações.
- **Conta · Configurações** `59:2`: 4 seções (Conta & Segurança: alterar senha + sessões/revogar; Notificações:
  3 toggles; Preferências: idioma/tema/densidade; Privacidade & LGPD: baixar dados, histórico de acesso).
- **Login** `65:2` + **Login · erro** `66:2`: card centralizado em navy, e-mail/senha, CTA "Entrar", hint demo;
  erro = alerta vermelho + borda na senha.

**Wiring:** avatar (rodapé da sidebar) → Perfil em 18 frames · sub-abas Perfil↔Configurações ·
Login "Entrar" → Home · **início do protótipo = Login** (Login → Home → tudo).
Estados extras ligados: filtro "Sem escala"→Localizar vazio; row→Reativar-bloqueado; Horas→Horas-vazio.

**Estado final do protótipo:** 24 frames, 135 reações, início em Login. Cobre **toda a 1ª entrega**:
Login · Home/Visão geral · Médicos (Localizar +vazio, Ficha ver/incompleto/inativo, editar/CPF-inválido,
Provisionamento, Histórico LGPD) · Escala (todos os estados + modais) · Conta (Perfil, Configurações).
Órfãos aceitos (estados da mesma tela): Criar·erro, Criar·sem-especialidade, Login·erro.

## Sessão 2026-06-17 (cont. 3) — Auditoria + 100% navegável
Pedido: "cada tela com tudo clicável; rode agents que validam a navegação; qual o % clicável?".
- **Auditoria automática do grafo de reações** (ground truth). Inicial: **54% clicável**.
- Correções: filtros **Todos/Com escala/Sem escala** agora navegam (criadas vistas filtradas
  `Médicos · Localizar · com escala` `79:2` e `Escala · Localizar · com escala` `80:2`); religados TODOS os
  botões de contexto das telas de Escala **no nível do frame `btn`** (estavam no nó de texto → não contavam);
  Salvar/Cancelar/Gerenciar/Trocar das edições; acessos "demo" para os estados de erro (Login·erro,
  Criar·erro, Criar·sem-especialidade).
- **Resultado: navegação 100%** (112/112 botões com destino) · **alcançabilidade 100%** (26/26 frames a
  partir do Login) · **0 becos sem saída**.
- **Validação por agente independente** (análise de grafo): 4 fluxos-chave OK, nenhum dead-end.
- **Controles in-place** (toggles, selects, inputs, Remover/Adicionar, ações de Configurações, Provisionar,
  Editar-perfil) **não navegam por design** — agem na própria tela; viram variante só se quisermos demonstrar estado.

## Tokens (hex, p/ recriar no arquivo novo)
primary #054671 · primary-subtle #E7EEF3 · surface #FFF · surface-muted #F8FAFC · bg #F1F5F9 ·
border #E2E8F0 · border-strong #CBD5E1 · text #0F172A · text-secondary #475569 · text-muted #64748B ·
accent #0073BD · accent-hover #00609E · accent-text #00609E · accent-subtle #E6F1F8 ·
action #B85410 · action-hover #9A440D · text-on-action #FFF ·
success #047857 · success-bg #ECFDF5 · danger #B91C1C · danger-bg #FEF2F2 · warning #B45309 · warning-bg #FFFBEB
Fonts: Montserrat (títulos), Inter (corpo).
