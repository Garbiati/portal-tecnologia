# Design System — Componentes (spec para AI Coding)

> Arquivo Figma `snTNGRUJO2GwoKpXTHCBjf`, página **🎨 Design System**. Cada master é a **fonte única de verdade**:
> editar o master → propaga para todas as instâncias nas telas. Cores ligadas às variáveis de marca (coleção
> Tokens `1:3`..`1:25`). Este doc liga cada componente às **regras de negócio** (decisões `D-NNN`) — é a base
> para gerar o código (React + .NET) da 1ª entrega.

## Átomos
| Componente | Variants | Regras / origem |
|---|---|---|
| **Button** | action, primary, secondary, subtle, accent, accentSolid, danger, dangerSolid | 1 CTA `action` (laranja) por tela (D-075a); `danger` só p/ destrutivo (D-075d). Tokens D-074. |
| **Badge** | success, info, neutral, warning, danger | "slots/semana" = info/azul, não verde (D-075b). Status escala = success/neutral. |
| **Field** | — (label + box) | Read-only usa fill `surface-muted`. Base de todos os campos de formulário. |

## Moléculas / Organismos
| Componente | Variants | Onde / Regras |
|---|---|---|
| **Sidebar** | active = visao / medicos / escala / **relatorio** / none | Em **32 telas** (modais não têm). Navegação embutida (override por instância): Visão geral→Home, Médicos→Localizar, Escala→Localizar, **Relatório→home do relatório**, avatar→Perfil. **Destaque** = fill branco @12% + texto 100% + Semi Bold (inativo = sem fill + texto 75% + Regular). Variante `relatorio` criada em D-081 (as 8 telas de Relatório marcavam "escala" por engano). |
| **DoctorRow** | escala = tem / sem | Linhas do Localizar (16 instâncias). Badge "tem escala"(verde ●)/"sem escala"(neutro) (D-075b). Ordem criação DESC (D-071d). Reação por linha → ficha/escala daquele médico. |
| **ContextHeader** | status = ativo / inativo | Barra de identidade das fichas/edições (18 instâncias): nome (Montserrat navy) · CRM · badge status · "← Trocar médico". Nome/CRM = **read-only, vêm da Teleconsulta** (D-066). |
| **DadosMedico** (ver) | — (26 campos) | Card de cadastro read-only. Ver regras de campo abaixo. Botão **Editar** libera edição (D-070). |
| **DadosMedicoEditar** | — (32 campos) | Mesma estrutura editável + Remover/Adicionar especialidade + Cancelar/Salvar (D-070). |
| **Card** | — | Container branco genérico (radius 10, borda, surface). |

## Regras de campo — DadosMedico (D-064/066/070/071/053/055)
| Campo | Regra |
|---|---|
| **Nome, CRM** | **read-only** (master da Teleconsulta) — nunca editável aqui (D-066). |
| **CPF** | máscara `000.000.000-00`; **validar dígito verificador** (bloqueia Salvar); vazio permitido (D-070/071). |
| **Nascimento** | `dd/mm/aaaa`; data passada + **idade ≥ 18** (D-071c). |
| **Telefone, E-mail** | texto livre (e-mail longo → fonte menor p/ não cortar). |
| **Valor/h fixa, Valor/h adicional (R$)** | taxas próprias; adicional tem taxa separada (D-053). |
| **Especialidades · RQE** | tabela esp+RQE; **≥1 p/ salvar**; **RQE por especialidade** (D-064); **Clínico Geral não atribuível** (D-064/67). |
| **Completude** | nota "✓ completo" / "⚠ Faltam p/ faturamento: CPF/valor fixo/≥1 esp c/ RQE" (D-055). |

## Estados de ciclo de vida do médico (regras aprendidas — `ux-feedback-log.md`)
- **Ativo/Inativo** = badge no ContextHeader. **Inativar/Reativar** vivem numa **Zona de risco** no rodapé
  (separada da navegação) e **sempre confirmam** (frames de confirmação dedicados). Inativo = **evidência visual
  forte** (cards esmaecidos + faixa "em LEITURA"), e **edição bloqueada** com aviso "reative primeiro".
- ⚠️ Propagação inativação→Teleconsulta = **mecanismo a definir** (D-055), UI marcada como provisória.

## Telas novas (17/06) — relatórios
- **Histórico de atendimentos por vigência** (card na ficha, D-078): tabela Especialidade · Vigência · Dias·
  Horário · **Previstos** (slots da escala na vigência) · **Realizados** (0, "em breve") · Status (ativa/arquivada)
  + total. Realizados reais = integração futura (D-072).
- **Relatório de escalas** (dashboard, D-079): grade Especialidade→Médico × faixas 30min (08:00–17:30).
  Célula = 🟢 escalado · 🔴 especialidade sem cobertura · ⚪ fora da escala. **Fonte = escalas (planejamento)**,
  não a operação. Seletor de período (Hoje/Amanhã/Semana/Fim do mês) + navegação dia-a-dia. Indicadores do dia.
  Acesso: item **"Relatório"** na Sidebar (componente → todas as telas). Regra da cor: derivada das vigências
  ativas das escalas naquele dia/horário/especialidade (sem cancelado/retorno — isso é operacional/futuro).
- **KPIs por granularidade (D-082):** telas de **DIA** (Hoje/Amanhã) mostram KPIs diários (médicos escalados,
  especialidades com/sem cobertura, slots no dia). Telas **AGREGADAS** (Semana/Mês) mostram **métricas próprias
  do período**: _Médicos distintos no período_ (≥1 turno), _Especialidades cobertas_ (≥1 slot), _Especialidades
  sem cobertura_ (0 slots), _Slots previstos no período_ (= grande total da grade). Rótulo do card de slots muda
  ("NO DIA / NA SEMANA / NO MÊS"). Nunca clonar números de um dia numa tela de período. ⚠️ "sem cobertura = 0"
  não deve ser vermelho (0 é bom). Reconciliar grão dia(11 esp)×semana/mês(5 esp) quando houver dado real.

## Pendências de componentização (não convertidos de propósito)
Os cards de Dados das telas-demo de estado (incompleto, inativo, CPF-inválido, confirmações — persona Alessandro)
seguem como clones, pois têm tratamento de cor/opacity específico que a cópia campo-a-campo não preserva.
Converter exigiria variants extras do DadosMedico (incompleto/erro/faded) — incremento futuro.
