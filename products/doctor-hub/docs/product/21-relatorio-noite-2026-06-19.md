# Relatório da noite — Doctor-Hub (loop autônomo 2026-06-18 → 19)

> Para o Alessandro homologar rápido. Loop overnight a seu pedido ("refinar a Entrega 1 + fluxo de demanda por estado").
> Estado vivo/passo-a-passo: `docs/product/19-overnight-loop-2026-06-18.md`. Figma: `snTNGRUJO2GwoKpXTHCBjf` (pág `0:1`).
> **Partimos de 62 telas → 74 telas, 100% navegáveis** (BFS desde Login). 0 emoji colorido, 0 código "D-xx" exposto na tela.

## ✅ O que foi construído

### 1. Fluxo de DEMANDA por estado (NOVO — 6 telas, PROVISÓRIO)
Pipeline oficial: **Oferta → Demanda → Alocação → Remanejamento → Agendamento → Teleconsulta.** Construído o miolo Demanda→Remanejamento:
1. **Demandas · lista por estado** `486:5408` — tabela Estado·Especialidade·Qtd·Janela·Status·Cobertura (SP/RJ/MG/BA/PE). Item **"Demandas"** na sidebar (todas as telas).
2. **Demanda · detalhe** `490:5414` — campos da solicitação + "Cruzar com a nossa capacidade".
3. **Cruzamento demanda × capacidade** `491:5432` — o coração: **DEMANDA 100 · NOSSA CAPACIDADE 64 · GAP faltam 36**, reusando os slots REAIS das escalas + funil instalada/ativada/ociosa.
4. **Alocação** `494:5939` — alocar 64/64, de quais escalas sai, verbos **Simular / Reservar / Emitir**.
5. **Status** `495:5955` — cobertura 64/100 + timeline (Recebida→Em análise→Alocada parcial→Emitida).
6. **Remanejamento** `503:6013` — pendência 36 coberta por RJ(12)+MG(8)+Clínico Geral(16).
> **Tudo com números DEMO + badge "PROVISÓRIO" + proveniência** ("Demanda = demo · Capacidade = real das escalas"). Nada virou regra.

### 2. Escala v2 (D-091 — confirmado + flex provisório)
- **Escala v2 · Lista** `496:5971` — múltiplas escalas por médico (1 por especialidade/produto), cada uma **FIXA** (sem data de fim) ou **FLEX**; status ativa/inativa/arquivada. "Horas adicionais" virou a escala flex.
- **Criar escala** `499:5991` — passo 1 (especialidade/produto) + passo 2 (tipo FIXA/FLEX com início/fim).

### 3. Estados que faltavam (Track A — confirmados, não-provisório)
- **Reativar especialidade** `492:5450` + **Reativar exame** `492:5681` (verde — D-089: inativados são reativáveis).
- **Erro ao salvar** `493:5748` (banner danger + "Tentar novamente").
- **Loading** `493:6045` (skeleton).
- Acessíveis por links "(demo)" na ficha de editar.

## 🟢 CONFIRMADO (já é regra, com seu ✅ anterior)
Validação faturamento (valor>0 + sem duplicata), RBAC Fase 1 (mesmo perfil), escala editável+cancelável, não-exclusão do que teve uso (só inativar+arquivar), múltiplas escalas por médico, fixa sem fim, reativação mantém histórico.

## 🟠 PROVISÓRIO (precisa do seu ✅ — NÃO inventei)
Todo o fluxo de demanda e a escala flex. Construído como CONCEITO navegável para você ver e decidir.

## 🔴 Perguntas que destravam o REAL (priorizadas — em `docs/discovery/03-open-questions.md`)
**Demanda — 6 bloqueadores:** (1) unidade (atendimentos/horas/pacientes/laudos?) · (2) nível+canal de entrada (estado? formulário/planilha/integração?) · (3) periodicidade + fila represada · (4) o que é "cobrir" + o que fazer na falta · (5) paciente entra? (LGPD) · (6) origem (digitada vs sync externo).
**Escala flex:** valor próprio? várias flex? conflito flex×fixa? quem move status?
**Remanejamento:** de onde remaneja? há substituição entre especialidades (Clínico Geral cobre Gineco — "coringa")? quem aprova? prioridade?
> Detalhe completo (89 perguntas, grupos A–M): `docs/product/20-demanda-conceito-provisorio.md`.

## ⚠️ Limitação conhecida (não é bug — é dívida de componentização)
As 5 fichas de médicos secundários têm as tabelas de faturamento completas, mas **sem os ícones ✎/🗑 por linha** (só o Alessandro `17:2` tem). A tabela é instância de componente (não aceita filhos novos) → resolver exige editar o master (Frente 3 P4/P5). Não fiz no loop por ser componentização pesada sem sua validação.

## ▶️ Sugestão de próximos passos (sua decisão)
1. Responder os **6 bloqueadores da demanda** → transformo o fluxo PROVISÓRIO em real.
2. Definir as **regras da escala flex** → fecho a Escala v2.
3. Aprovar uma rodada de **componentização** (Frente 3) → destrava ações de linha em todos os médicos + reduz dívida.
