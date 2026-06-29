# Fluxo de Demanda por Estado — CONCEITO PROVISÓRIO (discovery multi-agente, 2026-06-18)

> ⚠️ **TUDO PROVISÓRIO** (D-092 + Diretriz Suprema). Nenhuma regra confirmada; todo número é demo; cada regra é
> pergunta aberta. Gerado por 2 agents de discovery no loop overnight (doc 19). Construir no Figma com proveniência
> (real/demo) e marcas `PROVISÓRIO`, **sem inferir**.

## Pipeline (CLAUDE.md): Oferta → **Demanda** → Alocação (simular/reservar/emitir) → Remanejamento → Agendamento → Teleconsulta

## 5 telas (PROVISÓRIO)
1. **Demandas recebidas (lista por estado)** — só o que o estado enviou (D-083: sem estado, sem demanda). Por linha:
   Estado · Especialidade · Qtd pedida (`unidade?`) · Janela · Status · Cobertura (badge "cobre / faltam X"). Filtros.
2. **Demanda (detalhe)** — estado · especialidade · qtd · janela · origem · recebimento · histórico de status. Ação "Cruzar com capacidade".
3. **Cruzamento Demanda × Nossa Capacidade** (o coração) — reusa a capacidade real (D-084, slots = turnos × 60÷tempo):
   Demanda "Preciso 100 Gineco terça" / Capacidade "tenho 64" / **GAP = faltam 36** (verde cobre · vermelho falta) +
   funil instalada/ativada/ociosa/travada da fatia. Ação "Alocar/Reservar".
4. **Alocação / Reserva** — quanto alocar (total/parcial), de quais escalas sai, **Simular → Reservar → Emitir**.
5. **Acompanhamento / Status** — timeline do ciclo de vida; insumo p/ Remanejamento e Agendamento.

**Fórmula GAP (PROVISÓRIO):** chave = estado×especialidade×dia×duração; `GAP = DEMANDA(fatia) − CAPACIDADE_alocável(fatia)`.

**Máquina de estados (PROVISÓRIO):** Recebida → Em análise → {Alocada total | Alocada parcial → Remanejamento | Recusada} → (Emitida → Agendamento).

## ✅ WORKFLOW CONFIRMADO (D-094, 2026-06-19) — Solicitação → Sobrepor → Draft → Enviar
Dois atores: **Cliente/Regulação** (solicita) e **Demandas Médicas** `demandas` (sobrepõe/aprova/envia).

```
CLIENTE (Regulação)                    DEMANDAS MÉDICAS (operador PTM)
─────────────────────                     ──────────────────────────────
cria SOLICITAÇÃO ad-hoc      ──notifica──▶ recebe notificação de nova solicitação
(prazo "até dia X" +                       │
 especialidade × qtd,                      ▼
 atendimentos/Teleconsulta)         abre e SOBREPÕE  (nossa capacidade × solicitação do cliente)
        │                                  │  = simula se cobre
   🔒 não pode + alterar/excluir           ▼
                                    salva DRAFT da disponibilização (NÃO envia) ──▶ RESERVA capacidade
                                           │  ⟵ este momento = "aprovou a solicitação"
                                           │     → solicitação fica IMUTÁVEL (só Demandas altera)
                                           ▼
                                    (repete p/ vários clientes; vê TOTAL solicitado + por cliente)
                                           ▼
                                    ENVIA ao cliente  (≈ "emitir")  ──▶ [a definir: cliente assume/agenda?]
                                           │
                                    se não cobre → RELATÓRIO DE CONTRATAÇÃO (511:6029)
```

**Máquina de estados da SOLICITAÇÃO (provisória):** Recebida → (Sobreposta/Draft = aprovada, imutável p/ cliente) → Enviada → [assumida/agendada?].
**Travas (D-094):** cliente read-only após enviar; solicitação imutável após sobreposição (mesmo draft, pois reserva capacidade) — só `demandas` altera.
**Mapa no pipeline:** Sobrepor ≈ simular/cruzar · Draft ≈ reservar · Enviar ≈ emitir.
**Pontos abertos:** ver `03-open-questions.md` §Demanda-workflow (enviar=o quê? disputa entre clientes? descartar/expirar draft? parcial? status ao cliente?).

## 🔴 6 BLOQUEADORES — ✅ RESPONDIDOS (D-093). Mantidos aqui como histórico:
1. **B1 — Unidade da demanda:** atendimentos? horas-médico? pacientes na fila? laudos (telediag)?
2. **A2/A3 — Nível e canal:** demanda nasce no estado/HC/unidade? chega por formulário no sistema / planilha / integração (SISReg?) / ofício?
3. **C1/C3 — Periodicidade e represamento:** mensal/semanal/pontual? existe fila histórica (anos de espera) com data de entrada?
4. **F1/F3 — "Cobrir" e falta:** o que conta como atender (reservado? emitido? agendado-realizado?)? na falta: contratar / remanejar / recusar / fila?
5. **K3 — Paciente (LGPD):** a demanda é só agregada (quantidades, sem paciente) ou traz lista nominal de pacientes da fila?
6. **L1 — Origem:** digitada no Doctor-Hub ou puxada (sync RO) de um regulador externo?

## Demais grupos de perguntas (89 no total — A..M)
Origem/entrada (A) · Unidade (B) · Tempo/SLA (C) · Edição/ciclo de vida (D) · Prioridade/fila (E) · Cruzamento
demanda×capacidade (F) · Alocação simular/reservar/emitir (G) · Telediagnóstico (H) · Faturamento da demanda (I) ·
Segmentação estado/HC/cliente (J) · LGPD/RBAC (K) · Integração/fonte (L) · Métricas/forecast (M).
> Consolidar em `03-open-questions.md` quando o Alessandro voltar. **Construo as 5 telas PROVISÓRIO** (números demo,
> proveniência, cada regra rotulada) — a homologação vê o CONCEITO e responde as perguntas; nada vira regra sem ✅.
