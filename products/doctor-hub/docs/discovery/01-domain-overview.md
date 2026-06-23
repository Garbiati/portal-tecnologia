# Domínio — Visão Geral

> Status de cada item: ✅ Confirmado · 🟡 Parcial (precisa detalhe) · ❓ Aberto (não inferir).
> Fonte primária: whiteboard ClickUp "Fluxo Agenda Fixa" (`8cm6geh-107333`) + falas do Alessandro (2026-06-13).

## O pipeline (visão macro)

```
[ Médicos + Escala Fixa ]      → OFERTA ("estoque" de vagas)
            │
[ Governos abrem Solicitação ] → DEMANDA (por especialidade, por HC, por mês)
            │
[ Disponibilização ]           → ALOCAÇÃO (simular → reservar → emitir)
            │
[ HC assume as vagas ]         → vagas viram capacidade real
            │
[ Remanejamento automático ]   → vagas não assumidas vão p/ outros HCs (regras determinísticas)
            │
[ Agendamento ]                → médico + paciente + especialidade + HC
            │
[ TELECONSULTA ]               → destino final (sistema de registro do atendimento)
```

## ① Oferta — Cadastro de médicos com escala fixa ✅
Campos da escala (do whiteboard): dados do médico · especialidade · dias de atendimento ·
horário de atendimento · **período válido de prestação de serviço** · consultas por hora ·
flag ativo/inativo.
Tela de gestão de **cobertura**: mapa por especialidade, por médico, por dia (há um "PDF Modelo" citado).

- 🟡 **Estoque = MISTO**: base calculada automaticamente da escala (dias × horário × consultas/hora ×
  período) **+ ajuste manual** ("retornos/extras"). ❓ Falta: a fórmula exata de derivação e a
  trilha de auditoria do ajuste manual.

## ② Demanda — Solicitação dos Governos ✅
Gestor do estado solicita: lista de especialidades daquele HC · quantidade por especialidade ·
período (mês) · identificação + data da solicitação.

## ③ Alocação — Disponibilização (núcleo) ✅
Visões: macro (solicitações gerais) · por Governo · **dashboard estoque × demanda** · demanda de contratação.
Colunas: qtd solicitada pelo Gov · qtd que vamos disponibilizar · retornos/extras (manual) · saldo +/-.
Ações: **Simular** (demanda × estoque → saldo; flag p/ vagas > 30 dias) · **Limpar** ·
**Reservar** (bloqueia escala, baixa do estoque) · **Emitir** (publica a escala p/ o HC assumir).

## ④ Remanejamento automático ✅ (método) 🟡 (regras)
Vagas **não assumidas** pelo HC solicitante são realocadas para outros HCs.
- ✅ **Por regras determinísticas** na 1ª entrega (sem ML). Auditável.
- ❓ Falta: QUAIS regras/prioridades (ordem de HC? urgência? proximidade? data?).

## ⑤ Saída — Agendamento → Teleconsulta ✅ (direção) ❓ (contrato)
- ✅ **O paciente é entidade DESTE sistema** (decisão Alessandro 2026-06-13): o sistema monta o
  agendamento completo (médico + paciente + especialidade + HC) e o insere na Teleconsulta.
- ❓ Falta: o contrato de integração com a TC (API REST? eventos? banco? padrão FHIR/RNDS?).
- ❓ Falta: de onde vem o paciente e como ele é associado a uma vaga.

## Restrições transversais (a confirmar)
- ❓ **LGPD / dado sensível de saúde**: como o paciente entra, isso é obrigatório. Falta definir
  escopo de tratamento, base legal, retenção, auditoria.
- ❓ Volume esperado (nº de HCs, médicos, especialidades, solicitações/mês) — dimensiona tudo.
