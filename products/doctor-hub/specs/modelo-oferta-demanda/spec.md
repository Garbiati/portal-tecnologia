---
id: SPEC-000
title: Modelo Oferta × Demanda (entidades + fluxo de 3 níveis)
status: draft            # draft | specified | tested | implemented
owner: Alessandro
area: Alocação
clickup: ""
figma: ""
validated_by: ""
validated_at: ""
last_update: 2026-06-15
---

# Modelo Oferta × Demanda (entidades + fluxo de 3 níveis)

> Spec **fundacional/transversal**. Define as entidades e as regras do núcleo oferta×demanda que as
> specs de tela (`solicitacao`, `disponibilizacao`, `assuncao`, `medicos-escala`, `agendamento`)
> herdam. Consolida as decisões **D-031..D-047** (ver `docs/decisions/decisions-log.md`) e o modelo
> verificado da Teleconsulta (`docs/discovery/08-healthcenter-unidades.md`).

## 1. Problema / Dor
- **Dor:** o planejamento de capacidade (oferta de médicos × demanda dos estados) é feito **à mão em
  planilha**, fora de qualquer sistema, por 1-2 pessoas. Não há rastro, trava de capacidade, nem visão
  por papel.
- **De quem:** operador **Demandas** (monta a oferta), **Solicitante** (estado pede), **Gestor**
  (unidade assume e agenda).
- **Evidência:** relato do Alessandro (2026-06-15) descrevendo o fluxo manual real; planilhas
  `agenda-operacional-*.xlsx` (D-019).
- **Sucesso = quando:** o ciclo demanda → disponibilidade → reserva → agendamento → envio à TC roda
  **dentro do sistema**, com saldo/teto respeitados e rastreável, substituindo a planilha.

## 2. Função
Sistema em **3 níveis**, com **dois trilhos desacoplados** (planejamento de capacidade vs agendamento):

```
HealthCenter (= cliente = ESTADO)            ── Solicitante atua aqui; é o dono do POOL
  └── Unidade (ProfileTag, com CNES)         ── Gestor gere uma; tem TETO diário
        └── Paciente (patient_profile_tags)

TRILHO 1 (capacidade):  Demanda → Disponibilidade(pool do estado) → Reserva(fatia p/ unidade)
TRILHO 2 (execução):    Agendamento(doutor+paciente no horário) → envio à Teleconsulta
                        Remanejamento (slots ociosos perto de vencer)
```

## 3. Regras de negócio (somente CONFIRMADAS)
> Todas confirmadas por **Alessandro em 2026-06-15** (rastreio no decisions-log entre parênteses).

### Entidades
- ✅ **HealthCenter = um cliente = um ESTADO** (Piauí, Amazonas…). ID próprio; **nunca contém dois
  estados**. É flexível (pode representar estado/cidade/clínica), mas a 1ª entrega **só trata
  HCs-estado**. _(D-041)_
- ✅ **Unidade = ProfileTag**, ligada ao **CNES**, **pertence a exatamente um** HealthCenter.
  Presencial = endereço (CNES real); remoto = CNES do núcleo de telessaúde do estado. _(D-041)_
- ✅ **Unidade tem um TETO = capacidade de atendimento DIÁRIO**, cadastrado por unidade (fixo,
  independente do mês). _(D-037, D-046)_
- ✅ **Doutor** vem da Teleconsulta (busca), não é cadastro livre. **Paciente** vem da TC **por
  unidade** (`patient_profile_tags`). _(D-021, D-012 refinada)_

### Trilho 1 — capacidade
- ✅ **Solicitação** e **Disponibilização** são no nível do **HealthCenter (estado)** +
  especialidade + competência. _(D-031)_
- ✅ **Disponibilizar já cria o POOL** do estado — **sem passo de aprovação** separado. _(D-031, D-043)_
- ✅ **Disponibilidade (v1) = híbrido:** o sistema calcula o que der das **escalas ativas** dos
  doutores e o operador **ajusta** o restante. Derivação 100% automática = evolução futura. _(D-032, D-045)_
- ✅ **Pool = contagem abstrata** de capacidade no estado; o **horário concreto** (dia/hora/médico)
  só é **materializado da escala** na assunção/agendamento. _(D-033)_
- ✅ **Status da solicitação = 3 estados derivados** de disponibilizado×solicitado:
  `Enviada` (disp=0) → `Atendida parcial` (0<disp<solic) → `Atendida` (disp≥solic). _(D-035)_
- ✅ **Reserva (assunção):** o **Gestor** da unidade puxa uma fatia do pool do **seu** estado,
  limitada a **min(saldo do pool, teto diário da unidade)**. _(D-031, D-036)_
- ✅ A reserva pode ser **só quantidade** (sem doutor/paciente) **ou** já virar agendamento. _(D-044)_

### Trilho 2 — execução
- ✅ **Agendamento = 1 doutor + 1 paciente em um horário**, materializado da escala. É **desacoplado**
  da solicitação. _(D-029, D-042)_
- ✅ **Doutor sugerido** (preferencial do paciente → fallback de especialidade) e o Gestor **pode
  trocar**. _(D-011, D-034)_
- ✅ Agendamento pronto é **enviado à Teleconsulta** (`POST /integration/appointment`). _(D-002, D-003)_
- ✅ **Remanejamento:** vagas **reservadas** pro estado, **não usadas**, **vencendo em 48h**, **sem
  doutor/paciente** → **Demandas realoca**. _(D-013, D-047)_

### Escala (oferta)
- ✅ Escala é **nossa** (própria); da TC só **buscamos o profissional**. _(D-026, D-021)_
- ✅ Escala é definida por **DURAÇÃO em minutos** por consulta (ex.: 12/15/26 min); consultas/hora é
  só aproximação. Nº de vagas = janela ÷ duração. _(D-039)_

### Escopo (RBAC por dado)
- ✅ **Solicitante** → escopo do **HealthCenter (estado)**. **Gestor** → enxerga o pool do **seu
  estado** e possui **uma unidade** (dois eixos válidos). **Demandas/Admin** → global. _(D-038, D-008)_

## 4. Critérios de aceite (Gherkin → vira teste)

```gherkin
Cenário: Disponibilizar cria o pool do estado sem aprovação
  Dado uma solicitação do estado "Amazonas" de 1000 vagas de "Cardiologia" na competência 2026-07
  Quando o operador Demandas disponibiliza 1000
  Então o pool de "Amazonas / Cardiologia / 2026-07" passa a ter saldo 1000
  E a solicitação fica com status "Atendida"

Cenário: Status parcial é derivado
  Dado uma solicitação de 40 vagas
  Quando o operador disponibiliza 32
  Então o status da solicitação é "Atendida parcial"

Cenário: Gestor reserva limitado ao menor entre saldo e teto da unidade
  Dado o pool de "Amazonas / Cardiologia / 2026-07" com saldo 300
  E a unidade "UBS Centro" com teto diário 200
  Quando o gestor da "UBS Centro" tenta reservar 250
  Então a reserva é recusada por exceder o teto da unidade (máx. 200)

Cenário: Gestor reserva sem agendar (trilho desacoplado)
  Dado o pool com saldo suficiente e a unidade dentro do teto
  Quando o gestor reserva 50 vagas sem informar doutor nem paciente
  Então existem 50 reservas da unidade no estado "pendentes de agendamento"
  E o saldo do pool do estado cai 50

Cenário: Reserva de unidade de outro estado é negada (escopo)
  Dado um gestor cuja unidade pertence ao estado "Piauí"
  Quando ele tenta enxergar/reservar do pool do estado "Amazonas"
  Então o acesso é negado (fail-closed)

Cenário: Doutor é sugerido mas pode ser trocado
  Dado um agendamento de retorno cujo último doutor foi "Dr. Fernando"
  Quando o gestor abre a escolha de doutor
  Então "Dr. Fernando" vem pré-selecionado
  E o gestor pode trocar por outro doutor da mesma especialidade

Cenário: Remanejamento de slot ocioso perto de vencer
  Dado uma reserva do estado sem doutor/paciente que vence em menos de 48h
  Quando o operador Demandas roda o remanejamento
  Então esse slot fica disponível para realocação
  E reservas já com doutor+paciente NÃO são tocadas
```

## 5. Definition of Done
- [ ] Todos os cenários da seção 4 passam como teste automatizado
- [ ] Sem perguntas abertas 🔴 pendentes
- [ ] Validado por humano (`validated_by`)
- [ ] As specs de tela (`solicitacao`, `disponibilizacao`, `assuncao`, `agendamento`,
      `medicos-escala`, `clientes-hcs`) atualizadas para herdar este modelo

## 6. Fora de escopo (1ª entrega)
- Derivação 100% automática da disponibilidade a partir das escalas (v1 é híbrida — D-045).
- HealthCenters que **não** representam estados (cidade/clínica isolada) — modelo fica aberto, sem implementar (D-041).
- Remanejamento **automático** (v1 é o operador que roda — D-013).
- Elegibilidade avançada, produtividade médica, monitor proativo (entregas futuras — D-027).
- Tratamento de intervalos (almoço) e feriados na fórmula de capacidade (🟡 abaixo).

## 7. Dependências & Integrações (Teleconsulta)
- Buscar profissional: `GET /integration/doctor` (D-021/D-026).
- Resolver unidade por CNES: `GET /integration/profile-tags/by-cnes` (PartnerApiKey).
- Pacientes por unidade: endpoint da TC (`patient_profile_tags`) — localizar exato (D-012).
- Enviar agendamento: `POST /integration/appointment` (D-002/D-003).
- Modelo de dados verificado: `docs/discovery/08-healthcenter-unidades.md`.

## 8. Perguntas abertas (NÃO INFERIR)
> Nenhuma 🔴 — o núcleo está confirmado (D-031..D-047). As 🟡 abaixo não bloqueiam a validação.
- 🟡 HealthCenter não tem coluna de **UF** na TC (estado vem do nome/CNES). Precisamos de UF formal no nosso modelo?
- 🟡 **Fórmula de capacidade**: tratar intervalos (almoço) e feriados ao derivar vagas da escala.
- 🟡 **Vencimento da reserva**: qual o relógio dos "48h" — a partir da disponibilização? da reserva? (afina o remanejamento — D-047).
- 🟡 **Mapeamento de especialidades** (texto/`internal_specialization_id`) com a TC.
- 🟡 **Auditoria** do ajuste manual de disponibilidade (quem pode, trilha LGPD — D-032).
