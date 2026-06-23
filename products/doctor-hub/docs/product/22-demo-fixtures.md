# Fixtures do demo — FONTE ÚNICA dos dados do protótipo (v2 · 2026-06-22)

> ⚠️ **REGRA DURA (CLAUDE.md / D-106):** toda tela do Figma que mostra dados de demo deve **derivar destes valores** —
> nunca digitar dados à mão por tela. Filtros/variantes são **subconjuntos derivados** (ex.: "Com escala" =
> `medicos.filter(m => m.temEscala)`). Quando um dado mudar, muda **AQUI** e propaga para todas as telas.
> Todos os documentos (CPF/CNPJ) abaixo são **FICTÍCIOS** (gerados para demo, não correspondem a pessoas/órgãos reais).

---

## 1. Clientes (5) — `health_center ≡ cliente` (órgãos de governo, saúde pública)
Demanda em **atendimentos de Teleconsulta**. Manter os MESMOS clientes/siglas/prazos entre Inbox, Sobrepor, Multi-cliente, Status e Contratação.

| # | Cliente (nome oficial) | sigla | CNPJ (fictício) | tipo | prazo (demo) |
|---|---|---|---|---|---|
| C1 | Secretaria de Estado da Saúde do **Piauí** | **SES-PI** | 06.553.481/0001-20 | estado | até 30/06 |
| C2 | Secretaria de Estado da Saúde do **Amazonas** | **SES-AM** | 04.312.609/0001-77 | estado | até 26/06 |
| C3 | Secretaria de Estado da Saúde de **Alagoas** | **SES-AL** | 12.200.135/0001-08 | estado | até 28/06 |
| C4 | **IASEP** — Inst. de Assist. dos Servidores do Estado do **Pará** | **IASEP-PA** | 05.054.982/0001-63 | autarquia (servidores) | até 02/07 |
| C5 | Secretaria de Estado da Saúde do **Amapá** | **SES-AP** | 23.086.176/0001-49 | estado | até 02/07 |

**Mapa de substituição (v1→v2)** para renomear telas existentes:
`Governo de São Paulo`→**SES-PI** · `Prefeitura do Rio de Janeiro`→**SES-AM** · `Secretaria de Saúde de MG`→**SES-AL** · `Prefeitura de Salvador (BA)`→**IASEP-PA** · `Secretaria de Saúde de PE`→**SES-AP**. Siglas curtas (SP/RJ/MG/BA/PE) → (PI/AM/AL/PA/AP).

---

## 2. Perfis / usuários do sistema (com nome + documento fictício)

### Operadora PTM — persona **Demandas Médicas** (interno)
| Papel | Nome | Doc (fictício) | Avatar | Onde aparece |
|---|---|---|---|---|
| **Demandas Médicas** (operadora PTM) | **Renata Troncoso** | renata@portaltelemedicina.com.br · CPF 318.224.905-11 | **RT** (azul-marinho) | header de todas as telas de Demandas + login (substitui "Millena Garbiati / MG") |

### Clientes — persona **Gestor Geral** (quem solicita; 1 por cliente)
| Cliente | Gestor Geral (nome) | Doc (fictício) | Avatar |
|---|---|---|---|
| SES-PI | **Aldair Moura** | CPF 502.118.334-70 | AM (verde-petróleo) |
| SES-AM | **Tânia Albuquerque** | CPF 233.490.661-05 | TA |
| SES-AL | **Cleidson Tenório** | CPF 711.205.448-92 | CT |
| IASEP-PA | **Marivalda Pinheiro** | CPF 044.876.219-30 | MP |
| SES-AP | **Jucélio Tavares** | CPF 690.331.572-14 | JT |
> Persona logada nas telas de **Gestor Geral** (Minhas solicitações / Nova / De acordo) = **Aldair Moura (SES-PI)** por padrão no demo.

### Unidade — persona **Gestor Regional** (assume/agenda)
| Papel | Nome | Doc (fictício) | Unidade | Avatar |
|---|---|---|---|---|
| **Gestor Regional** | **Eronildes Bastos** | CPF 825.640.173-06 | Núcleo Teresina-Centro (SES-PI) | EB (teal) |

---

## 3. Médicos (6) — fichas, cards, filtros, Escala, Sobrepor, Agendar
Avatar = **iniciais coloridas** consistentes (mesma cor por médico em toda tela). Especialidade dá a cor do badge.

| # | Nome | CRM | Especialidade | temEscala | escala (resumo) | cadastro | status |
|---|------|-----|---------------|-----------|-----------------|----------|--------|
| 1 | **Dr. Henrique Sampaio** | CRM-PI 55210 | Cardiologia | **sim** | Seg–Sex · 08–12h · 20 min/atend · ~12/turno | completo | ativo |
| 2 | **Dra. Juliana Castro** | CRM-AM 23456 | Cardiologia | não | — | completo | ativo |
| 3 | **Dr. Rafael Lima** | CRM-AP 56789 | Clínica geral | não | — | completo | ativo |
| 4 | **Dra. Fernanda Alves** | CRM-PI 12345 | Cardiologia | não | — | completo | ativo |
| 5 | **Dr. Marcos Tavares** | CRM-AL 34567 | Dermatologia | não | — | **incompleto** (falta valor) | ativo |
| 6 | **Dra. Paula Nunes** | CRM-PA 45678 | Pediatria | não | — | completo | **inativo** |

> Especialidades dos médicos (demo): Cardiologia ×3 (Henrique, Juliana, Fernanda) · Dermatologia (Marcos) · Pediatria (Paula) · Clínica geral (Rafael). Casa com a alta demanda de Cardiologia (SES-PI/SES-AP) nos use cases.

**Subconjuntos derivados (devem bater SEMPRE):**
- `Todos` = 6.
- `Com escala` = `filter(temEscala)` = **[1 Henrique]** (1 médico).
- `Sem escala` = `filter(!temEscala)` = **[2 Juliana, 3 Rafael, 4 Fernanda, 5 Marcos, 6 Paula]** (5 médicos).
- `Incompleto` = [5 Marcos]. `Inativo` = [6 Paula].
- Contador "6 médico(s)" = `Todos.length`. Badge: temEscala → "tem escala" (verde) · senão "sem escala" (cinza).
> ✅ **Split 1/5 (2026-06-22, D-108):** só o **Henrique tem escala** — e tem **conteúdo de escala real** (tela `2:2` Ativo). "Tem escala" ↔ realmente tem escala. (Reverteu o 3/3 que deixava Juliana/Rafael com badge "tem escala" mas tela vazia.) **Escala v2 (múltiplas escalas) foi removida** — a oficial é a v1 (uma escala por médico).

---

## 4. Especialidades × nossa capacidade (derivada das escalas) — Sobrepor / Contratação
Capacidade real = soma dos slots das escalas ativas por especialidade (demo).

| Especialidade | nossa capacidade (atend., demo) |
|---|---|
| Cardiologia | 7.000 |
| Pediatria | 1.800 |
| Clínica geral | 3.000 |
| Dermatologia | 600 |
| Ginecologia | 2.500 |

---

## 5. Use cases nomeados (cada exemplo do protótipo tem nome próprio)
> Cada cenário usa cliente + especialidade + números coerentes com §1 e §4.

| Use case | Cliente | Cenário | Resultado esperado na tela |
|---|---|---|---|
| **UC-COBRE** "Amapá coberto" | SES-AP | pede **200** cardio · nossa capacidade folgada | Sobrepor **COM capacidade** → reserva total (verde, "cobre 200/200") |
| **UC-FALTA** "Piauí em falta" | SES-PI | pede **1.000** cardio · capacidade insuficiente | Sobrepor **SEM capacidade** → "faltam 300" → vai p/ Contratação |
| **UC-RESERVAR** "Amazonas reservado" | SES-AM | Aberto → **Reservar** (pediatria 250) | status **Reservado · atendendo total** |
| **UC-VOLTAR** "Alagoas reaberto" | SES-AL | Reservado → **Voltar para Aberto** (dermato 120) | status volta a **Aberto** (pré-cancelamento) |
| **UC-CANCELAR** "Alagoas cancelado" | SES-AL | Aberto → **Cancelar** (motivo: data expirada) | status **Cancelado · data expirada** |
| **UC-ENTREGUE** "IASEP entregue" | IASEP-PA | Reservado → **Provisionar** | status **Entregue** · cliente notificado · segue p/ agendamento |

### Contratação (consolidado) — derivado de UC-FALTA + reservas parciais
Organizar **POR ESPECIALIDADE** (quantos médicos contratar) e, dentro, **para quais clientes** (prioridade = quem pediu primeiro):
| Especialidade | faltam (atend.) | ≈ médicos | clientes (prioridade) |
|---|---|---|---|
| Cardiologia | 300 | ~2 | SES-PI (1ª · 16/06, até 30/06) |
| Pediatria | 120 | ~1 | SES-AM (2ª · 17/06, até 26/06) |
| Dermatologia | 120 | ~1 | SES-AL (3ª · 18/06, até 28/06) |
| Ginecologia | 80 | ~1 | IASEP-PA (4ª · 19/06, até 02/07) |
> **Total a contratar:** 620 atend. · 4 especialidades · **~5 médicos** · 4 clientes. (≈ médicos = atend. ÷ ~capacidade média por médico — estimativa demo, a confirmar.)

---

## 6. Pacientes (agendamento — Gestor Regional) — LGPD: só iniciais
Maria S. · João P. · Ana R. (por unidade/cliente). **Nunca** nome completo no demo.
> **Agendamento (GR · `522:6125`) usa SÓ médicos da fixture** — para Cardiologia: Henrique Sampaio, Fernanda Alves, Juliana Castro. Nunca inventar nomes (já houve "Helena Costa"/"Paulo Reis" — corrigido).

## 6b. Fluxo da demanda (exemplo canônico) — Inbox → detalhe → Sobrepor → Reservado → status
Tudo no MESMO cliente/especialidade para o caminho clicado bater: **SES-PI · Cardiologia · 1.000 solicitados · faltam 300** (coberto 700). Telas: detalhe `490` · Sobrepor `517` · Reservado `518` · status `495`. O exemplo "coberto" é **SES-AP** (`651`); o "entregue" fica na galeria de estados `654` (IASEP·Ginecologia). **Status sempre no vocabulário D-104** (Aberto/Reservado/Entregue/Cancelado) — nunca "Em análise"/"Provisionada".

## 7. Como derivar no build (padrão)
```js
const MEDICOS = [
 {id:1,nome:'Dr. Henrique Sampaio',crm:'CRM-PI 55210',esp:'Cardiologia',temEscala:true,cadastro:'completo',status:'ativo'},
 {id:2,nome:'Dra. Juliana Castro',crm:'CRM-AM 23456',esp:'Cardiologia',temEscala:false,cadastro:'completo',status:'ativo'},
 {id:3,nome:'Dr. Rafael Lima',crm:'CRM-AP 56789',esp:'Clínica geral',temEscala:false,cadastro:'completo',status:'ativo'},
 {id:4,nome:'Dra. Fernanda Alves',crm:'CRM-PI 12345',esp:'Cardiologia',temEscala:false,cadastro:'completo',status:'ativo'},
 {id:5,nome:'Dr. Marcos Tavares',crm:'CRM-AL 34567',esp:'Dermatologia',temEscala:false,cadastro:'incompleto',status:'ativo'},
 {id:6,nome:'Dra. Paula Nunes',crm:'CRM-PA 45678',esp:'Pediatria',temEscala:false,cadastro:'completo',status:'inativo'},
];
const comEscala = MEDICOS.filter(m=>m.temEscala);   // 3
const semEscala = MEDICOS.filter(m=>!m.temEscala);  // 3
// invariante: comEscala.length + semEscala.length === MEDICOS.length
```
