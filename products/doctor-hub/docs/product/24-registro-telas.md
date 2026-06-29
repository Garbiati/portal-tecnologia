# Registro de Telas Canônicas + Detectores (3º pilar de coerência) — 2026-06-22

> **Por que existe (D-108):** o Alessandro pegou, homologando, **duas Escalas paralelas** (v1 polida + v2 PROVISÓRIO)
> — eu tinha criado a v2 e **não apaguei a v1**, e os cliques se dividiram. Causa: eu vinha **deixando versões
> desatualizadas** em vez de apagar/repontar. Este doc é a defesa: **1 tela por intenção** + detectores antes de "pronto".
>
> Pilares de coerência: **(1) dados** = fixture (`22-demo-fixtures.md`) · **(2) navegação** = linter de persona
> (`23-navegacao-contrato.md`) · **(3) ciclo de vida de tela** = ESTE doc.

---

## 1. REGRA DURA (ciclo de vida de tela)
1. **1 tela canônica por intenção.** Nunca duas telas servindo o mesmo propósito (ex.: "gerenciar escala do médico").
2. **Superou uma tela? APAGUE a antiga e REPONTE todas as referências.** Nada de "v2" convivendo com "v1".
   - Antes de apagar: achar todos os inbound (`reactions → destinationId == idAntigo`) e repontar para a nova.
   - Se a antiga era índice de telas de borda (ex.: o QA lab indexava erros), decidir caso a caso: apagar as órfãs ou re-homear no fluxo.
3. **Rodar os 2 detectores (§3) antes de dizer "pronto"** — junto do linter de navegação e da revisão de coerência de dados.
4. **Variantes legítimas ≠ duplicatas:** estados de erro/sucesso, modais, por-médico, e exemplos (Sobrepor com/sem) são telas distintas com intenção distinta — OK. Duplicata = **mesma intenção, telas diferentes**.

## 2. Telas canônicas por intenção (oficial)
| Intenção | Tela canônica | id | Notas |
|---|---|---|---|
| Login | Login | `65:2` | |
| Trocar perfil | Seletor "Entrar como" | `529:6141` | única ponte entre personas |
| **Demandas** | | | |
| Início (pendências) | Home · Pendências | `514:6045` | |
| Listar médicos | Médicos · Localizar | `16:2` | filtros 79:2 (com escala) / 54:2 (sem) — derivados |
| Ficha do médico | Médicos · Ficha (ver) | `5:2` + `175:*` por médico | editar = `17:2` + `186:*` |
| **Gerenciar escala (multi, D-091)** | **Escala · Ativo (lista FIXA/FLEX)** | **`2:2`** | **NÃO é mais "1 escala ativa"** — é lista multi-escala (FIXA sem fim / FLEX período). Criar (com seletor FIXA/FLEX) = `10:2`; vazio = `9:2` + `176:*` por médico; localizar = `8:2`; arquivado = `12:2`. **"Horas adicionais" foi removido — virou FLEX.** |
| Inbox de solicitações | Demandas · Inbox | `516:6102` | |
| Demanda · detalhe / status | `490:5414` / `495:5955` | | estados/transições = `654:6226` |
| Sobrepor (sem capacidade) | Sobrepor · SES-PI | `517:6093` | exemplo "em falta" |
| Sobrepor (com capacidade) | Sobrepor · SES-AP coberto | `651:6207` | exemplo "coberto" |
| Reservado (draft) | Disponibilização · Reservado | `518:6109` | |
| Multi-cliente | Demandas · visão multi-cliente | `516:6307` | |
| Contratação + exportar | Relatório de contratação | `511:6029` (+ modal `641:6188`) | |
| Remanejamento (futuro) | Remanejamento | `621:6169` | placeholder |
| Conta | Meus dados | `57:2` (+ Configurações `59:2`) | menu do avatar = `683:6241` |
| **Regulação** | Minhas solicitações / Nova / De acordo | `530:6141` / `531:6141` / `531:6251` | |
| **Gestor** | Agendamentos / Assumir-Agendar | `532:6141` / `522:6125` | |

## 3. Detectores (rodar antes de "pronto") — `use_figma` read-only
### 3a. Inventário (inbound/PROVISÓRIO/órfã)
Lista todas as frames com nº de inbound, outbound e flag PROVISÓRIO. **Sinais de duplicata/lixo:** duas frames com nome/propósito parecido; uma PROVISÓRIO ao lado de uma definitiva da mesma intenção; frame com `inbound==0` que não é o Login (órfã = provável resto).

### 3b. Consistência de clique (mesmo rótulo → destinos diferentes)
Agrupa todo NAVIGATE pelo **texto visível do elemento clicado**; sinaliza rótulos que vão para **>1 destino distinto**. Pega o caso "Gerenciar escala → 2:2 num caminho e → 496 noutro". **Splits legítimos** (ignorar): rótulo igual em módulos diferentes (Todos/Com escala/Ver), por-médico (Gerenciar escala → Ativo p/ quem tem, Vazio p/ quem não tem), exemplos (Sobrepor →).

> Scripts completos dos dois detectores: ver histórico desta sessão (2026-06-22) ou recriar pela descrição acima. O linter de navegação (`23-navegacao-contrato.md`) cobre alcançabilidade/persona/cliques-mortos.

## 4. Log de telas removidas (supersede)
| Data | Removida | id | Motivo | Repontado para |
|---|---|---|---|---|
| 2026-06-22 | Escala v2 · Lista (PROVISÓRIO) | `496:5971` | duplicava a v1 (`2:2`) | cards de médico → `2:2` (Henrique) / `176:*` (demais) |
| 2026-06-22 | Escala · Criar (nova v2) | `499:5991` | duplicava `10:2` | — |
| 2026-06-22 | Laboratório de estados (QA/demo) | `552:6041` | scratchpad de dev exposto no Seletor | link removido do Seletor |
| 2026-06-22 | 10 telas de erro/borda (Login erro, CPF inválido, carregando, +esp/+exame erro, reativar confirmações, erro ao salvar, Reativar bloqueado) | `66:2,51:2,52:2,493:6045,484:4988,485:5136,492:5450,492:5681,493:5748,39:2` | só eram alcançáveis pelo QA lab (órfãs após removê-lo) | apagadas (re-homear sob demanda) |

| 2026-06-22 | Escala · Criar · erro / sem especialidade | `22:2`,`22:124` | scaffolding de erro (links "Estados (demo)") | links removidos do `10:2` |
| 2026-06-22 | Modais "Horas adicionais" (preenchido/vazio) | `15:2`,`37:2` | conceito antigo — FLEX o substitui (D-091) | bares "+ Horas adicionais" removidos de todas as telas de Escala |

**⚠️ Regressão corrigida (D-091):** o módulo Escala tinha ficado no modelo **antigo de 1 escala** (subtítulo "escala fixa do médico", nota "arquiva a ativa atual", criar sem FIXA/FLEX) — só a tela de detalhe fora migrada. Alinhado **tudo** ao multi-escala: subtítulo, notas, seletor FIXA/FLEX no criar, "horas adicionais" → FLEX. **Lição:** ao migrar um modelo, migrar o MÓDULO inteiro, não só a tela-âncora.

**Estado pós-consolidação:** 71 telas · 71/71 alcançáveis · 0 vazamentos · 0 órfãs · 0 cliques mortos · 0 duplicatas de intenção · módulo Escala 100% D-091.
