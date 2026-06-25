# Perguntas Abertas (o "instrumento" da descoberta)

> Atualizado 2026-06-14. A maior parte dos 🔴 foi respondida — ver `docs/decisions/decisions-log.md`.
> Prioridade: 🔴 bloqueia modelagem · 🟡 importante · 🟢 pode esperar.

## 🏛️ Demanda por estado (D-092) — PROTÓTIPO PROVISÓRIO no Figma, regras a confirmar — NÃO inferir
> O fluxo de demanda (5 telas: lista→detalhe→cruzamento→alocação→status) está no Figma como **PROVISÓRIO** (números demo,
> proveniência marcada). Conceito + as **89 perguntas (grupos A–M)** em `docs/product/20-demanda-conceito-provisorio.md`.
> **6 BLOQUEADORES — ✅ RESPONDIDOS por Alessandro em 2026-06-19 (ver D-093):**
- ✅ **B1 — Unidade:** **ATENDIMENTOS**, **só Teleconsulta por ora** (telediag depois).
- ✅ **A2/A3 — Nível + canal:** entrada por **`health_center` (≡ cliente, pode ser estado ou não)**; perfil **GESTOR GERAL** digita a necessidade.
- ✅ **C1/C3 — Periodicidade:** **mensal** (geralmente), podendo ser **semanal**. (represamento histórico: não citado → assumir forward-looking; confirmar se surgir.)
- ✅ **F1/F3 — "Cobrir" + falta:** cobrir = ter capacidade de **disponibilizar**; sem capacidade → **RELATÓRIO DE CONTRATAÇÃO** (info p/ contratar mais doutores). _(Aberto: precedência remanejamento × contratação.)_
- ✅ **K3 — Paciente (LGPD):** **NÃO entra** — demanda **agregada**.
- ✅ **L1 — Origem:** **DIGITADO** pelo Gestor Geral (login + perfil); não é sync externo.
> **Levantadas pelas telas status/alocação:** estados oficiais do ciclo de vida e quem os move? "Alocada parcial" → remanejamento automático ou manual?
> os verbos Simular/Reservar/Emitir — efeito real (reserva trava a escala? expira?)? cada transição guarda autor+data? há rejeição/cancelamento? margem de no-show?
> **Remanejamento (tela PROVISÓRIO `503:6013`):** de onde se remaneja (outro estado? outra especialidade?)? **há substituição entre especialidades** (Clínico Geral cobre Ginecologia — "coringa")? quem aprova o remanejamento? qual a prioridade/ordem das fontes? remanejar tira capacidade de outra demanda já alocada?

### Demanda-workflow (Sobrepor + Draft + Travas — D-094/D-095, 2026-06-19)
- ✅ **Disputa de capacidade (D-095):** **Demandas Médicas decide**; o sistema dá **insights** (urgência por prazo, gap a contratar). Sem auto-resolução.
- ✅ **Descartar/expirar draft (D-095):** draft pode ser **descartado → libera a reserva**; **não expira**. Home terá relatório de pendências (drafts/solicitações).
- 🟡 **Enviar — efeito (parcial, D-095):** "Enviar" **notifica o Gestor Geral (talvez Gestores Regionais), in-app** (canal e-mail/WhatsApp a definir). **AINDA ABERTO:** o que o cliente FAZ ao receber — só vê, ou **assume/agenda** (conecta ao Gestor Regional do modelo antigo)?
- 🟡 **Gestores Regionais** também recebem a notificação do "Enviar"? (D-095 deixou "talvez".)
- 🟡 **Solicitação imutável — exceções:** Demandas pode **editar** a solicitação travada (corrigir qty) ou só a **disponibilização**? se o cliente quiser mudar, abre **nova** solicitação?
- 🟡 **Cobertura parcial:** sobreposição que cobre só parte → envia o parcial ao cliente **e** gera o "Captar novos médicos", ou segura até cobrir?
- 🟡 **Captar novos médicos:** formato do relatório à recrutadora (export? integração?); prazo/SLA da contratação; como a capacidade contratada volta a alimentar a disponibilização.

### Agendamento + integração com a Teleconsulta (D-097/D-098) — tela `522:6125`
- 🔴 **LGPD (PACIENTE entra no sistema):** base legal, retenção, minimização e RBAC da **lista de pacientes por cliente**. ✅ Confirmado: Gestor Regional vê **só o seu cliente/unidade** (isolamento). Falta o resto da política de dado sensível.
- 🔴 **Integração TC:** PULL **read-only** de **pacientes + doutores** da Teleconsulta (paciente é mais sensível que médico — estende D-069: credencial dedicada, escopo mínimo, segurança). PUSH do **agendamento completo** para a TC.
- 🟡 **"Último doutor que atendeu o paciente naquela especialidade":** fonte e regra exata (vem da TC; casa com D-011 preferencial).
- 🟡 **Campos do agendamento:** por ora paciente + doutor + horário + local. **Refinar depois** (data, primeira vez/retorno, duração) quando focar nesta parte.
- 🟡 **"Local":** o que é (unidade do cliente? do paciente? virtual?).

## 🆕 Abertas na sessão de 2026-06-23 (confirmações D-113..D-118) — NÃO inferir
> O Alessandro confirmou 8 decisões (D-113..D-118 + nota de auth/redirect). Estas 4 ficaram **explicitamente em aberto**:
- 🔴 **Janela de envio do Monitor — prazo e gatilho do alerta:** qual é a "janela de envio" do Monitor (a partir de quando uma solicitação/disponibilização é alertada como atrasada)? **prazo** (quantos dias/horas) e **gatilho** do alerta (evento que dispara) **não definidos**. Não inferir.
- 🔴 **Fonte do funil do Monitor:** de onde vêm os números do funil do Monitor — da **nossa integração com a Teleconsulta** (PULL RO, D-069/D-098) ou de um **hub externo (AM / SISReg)**? Define a proveniência do dado e a confiabilidade. Não inferir.
- 🟡 **Flag ">30 dias" (D-118) — regra:** a sinalização ">30 dias" nas telas de Disponibilização/Sobrepor está **DESLIGADA** até a regra existir. **Quando** aparece (prazo/gatilho), **o que mede** (>30 dias de quê: janela? data de início? prazo restante?) e **qual o efeito** (só visual? bloqueia ação?). Não inferir.
- 🟡 **Atribuição de capacidade entre clientes simultâneos (D-117):** a capacidade **disponível na janela** (ex.: Cardiologia 700 de 7.000) é **consumida/decrementada** como, quando vários clientes reservam ao mesmo tempo? (FIFO por solicitação? rateio? trava ao reservar? libera ao descartar/expirar?) **PROVISÓRIA / indefinida** — não inferir; afeta o Sobrepor multi-cliente e a Contratação.

## 🗓️ Escala v2 — múltiplas escalas + fixa/flexível (surgidas em D-091, 2026-06-18) — NÃO inferir
- ✅ **RESOLVIDO (2026-06-18):** **1 escala por especialidade (Teleconsulta) OU por exame/modalidade (Telediagnóstico)**; o médico acumula **VÁRIAS**, e o conjunto cobre os 2 produtos. Cada escala é FIXA (sem fim) ou FLEXÍVEL.
- ✅ **RESOLVIDO (2026-06-18):** a **escala FLEXÍVEL evolui os modais de "Horas adicionais"** (hoje 1 dia → ganha início+fim; renomear/expandir, reaproveitando o que existe).
- 🔴 **Escala flexível — regras completas:** além de "não conflita com a fixa", quais? (vínculo a especialidade/produto? valor próprio? pode haver várias flex? a flex some quando vence ou vira histórico? quem cria?)
- 🟡 **Faturamento × escala:** o faturamento (valor por atendimento/laudo) é por especialidade/produto (já definido) — a escala fixa/flex muda o valor, ou só define disponibilidade?
- 🟡 **Fixa sem fim:** se a fixa não tem data de fim, como se "encerra/troca" uma fixa? (arquivar = encerrar?)
- 🟡 **Migração "horas adicionais" → flex:** os modais de "Horas adicionais" existentes viram a "escala flexível"? (renomear + adicionar início/fim).

## 🔎 Levantadas pela VALIDAÇÃO multi-agente da arquitetura Figma (2026-06-18) — NÃO inferir
> 4 agents validaram completude/arquitetura/padronização/UX das 51 telas. Regras de negócio a confirmar:
- 🟡 **Padrão de feedback de sucesso** _(PROVISÓRIO: toast — aplicado 2026-06-18)_: usei **toast verde no canto superior** ("✓ Especialidade adicionada/excluída/inativada…", "Escala criada e ativada") nas 9 ações de faturamento+escala. Confirmar se prefere **banner persistente** ou **retorno a lista com a linha destacada** em vez de toast efêmero.
- 🔴 **Validação no modal de faturamento:** valor é obrigatório / > 0? tempo válido por modo (hora/consulta)? **especialidade/exame duplicado é bloqueado**? (dinheiro público — não pode salvar lixo).
- 🔴 **Médico sem nenhuma especialidade/exame ativo pode ser escalado?** E pode-se **remover a última** especialidade (deixar o médico sem produto)?
- 🟡 **Escala criada é EDITÁVEL e/ou cancelável**, ou só arquivável+recriável? (hoje só existe "Criar nova").
- 🟡 **Sobreposição de horário** na escala é bloqueada? (o "erro de validação" genérico cobre isso?)
- 🟡 **Edição concorrente** (2 gestores no mesmo médico): exclusiva, last-write-wins, ou bloqueio?
- 🟡 **RBAC:** quais papéis alteram faturamento vs. só montam escala? (CLAUDE.md exige least-privilege).
- 🟡 **Autoria das alterações** visível na ficha/escala (quem mudou o valor, não só quando)? — LGPD/dinheiro público.
- 🟡 **Reativar especialidade/exame inativado:** a regra (D-089) diz "reativável" mas não há tela de reativar especialidade/exame (≠ reativar médico).

## ✅ Resolvido (ver decisions-log)
- Fronteira/integração com a TC → `POST /integration/appointment` (D-002, D-003).
- Onde o sistema vive → repo separado, parceiro (D-002).
- Alocação de médico é nossa; preferencial + fallback de especialidade (D-003, D-011).
- Paciente: associado ao assumir; lista vem da TC por health center (D-004, D-009, D-012).
- Papéis: Admin/Demandas, Solicitante (secretário estadual), Gestor (local/HC); só esses logam (D-008, D-010).
- Remanejamento: janela configurável 24/48h, critério "demanda não atendida", manual na v1 (D-006, D-013).
- Estoque misto (auto + ajuste manual) (D-005).

## ✅ Posicionamento / rename — RESOLVIDO → D-055 (2026-06-15)
- ✅ ~~**Q-rename**~~ **RESOLVIDO → D-055.** O produto é **reposicionado** para **gestão de médicos**
  com o **médico como entidade central**; o **cadastro-dono do médico entra na 1ª entrega**;
  **Telediagnóstico é DESTINO, não origem** (o cadastro nasce aqui e é provisionado p/ TC e/ou
  Telediagnóstico via `external_id` por destino). Inverte a direção do D-054 (de RO→nós para nós→jusante;
  o snapshot RO vira reconciliação inicial dos ~4.500 existentes). Ver [11-doutor-schema-legado](11-doutor-schema-legado.md).
  - 🟡 **Resta confirmar (não bloqueia):** (a) **rótulo/nome final** do projeto ("Gestão Médica" / "Gestão
    de Médicos" / outro); (b) **mecanismo de provisionamento nós→TC** (API de parceiro a desenhar — escrita
    em prod da TC nunca por DB direto); (c) campos do telediagnóstico como destino (que dados ele exige).
- 🟡 **Inativar o cadastro do médico DENTRO da Teleconsulta a partir do nosso sistema (req. do Alessandro, 2026-06-15):**
  como somos o dono, ao inativar um médico aqui precisamos **propagar a inativação para a TC**. Candidatos
  de estado na TC (verificados): `core.health_center_doctor_profiles.disabled_at`/`status`/`deleted_at`,
  `core.doctor_status_enums` (0=Away,1=Active), `auth.AspNetUsers.disabled_at`/`deleted_at`,
  `auth.health_center_doctor_profiles.disabled_at`. **NÃO escrever no DB da TC** (só RO) — a inativação tem
  de ser via **API de parceiro** (a desenhar, junto do provisionamento nós→TC). Confirmar com a equipe da TC
  qual endpoint/campo representa "médico inativo" e se é por health-center (vínculo) ou global.

## 🟡 Levantadas pela AUDITORIA multi-agente (2026-06-16 madrugada) — regra de negócio, NÃO inferida
- 🟡 **Conjunto exato de KPIs do Dashboard Fase-1 (PROVISÓRIO):** a "Visão geral" foi trocada do funil
  Fases 2–4 (vazio) por KPIs factuais: médicos cadastrados, com escala ativa, sem escala, cadastros
  incompletos (= falta CPF, valor fixo, ou ≥1 especialidade c/ RQE) + capacidade por especialidade.
  Confirmar QUAIS KPIs a diretoria quer e a definição de "incompleto". (`GET /api/dashboard/phase1`).
- 🟡 **Remover especialidade que uma escala ATIVA usa:** `PUT /doctors/{id}/specialties` faz replace e
  pode remover a especialidade que uma `schedule` ativa referencia (FK aponta p/ `specialties`, não p/
  `doctor_specialties`), deixando a escala "órfã" da especialidade do médico. **Como tratar?** bloquear
  (409)? arquivar a escala em cascata? permitir e avisar? — **regra de negócio, não codifiquei** (deixei
  o comportamento atual). Confirmar.
- 🟡 **Escopo do cadastro/escala do médico:** hoje qualquer admin/demandas edita/cria/arquiva escala e
  cadastro de QUALQUER médico (cadastro-mestre global, coerente com D-055). Confirmar que **não há recorte
  por HealthCenter/Unit** (se um dia "demandas" for limitado a um estado, faltará filtro de escopo aqui).
- 🟡 **Formato/obrigatoriedade de CPF/e-mail no cadastro do médico:** o backend agora impõe só **limites de
  tamanho** (defensivo). Validar dígito verificador de CPF, formato de e-mail e se são obrigatórios/únicos
  é regra a confirmar (não implementei por suposição).

## 🟡 Levantadas na sessão autônoma (2026-06-15 noite) — PROVISÓRIO, revisar
- 🟡 **`doctors.specialty_id` (única) × `doctor_specialties` (conjunto, D-064):** agora o médico tem N
  especialidades com RQE cada. Resta a coluna `doctors.specialty_id` (especialidade "principal/legada")
  usada na busca e no detalhe. No wizard, ao salvar o cadastro, o front envia a **1ª especialidade da
  lista** como `specialty_id` principal (`// PROVISÓRIO`). **Confirmar:** existe "especialidade principal"
  do médico, ou ela deve ser 100% derivada de `doctor_specialties`? (afeta a busca por especialidade).
- 🟡 **Completude p/ faturamento (CPF + valor fixo + ≥1 especialidade c/ RQE):** hoje é só um AVISO na
  tela, não trava o salvar. Confirmar se deve bloquear/validar.
- 🟡 **`DoctorOwnerInput.rqe`** ficou no contrato por compat mas não é mais usado (RQE migrou p/ especialidade) — limpar.

## 🟡 Ainda em aberto (não bloqueiam a estimativa de alto nível)
- ✅ ~~**Granularidade do estoque**~~ **RESOLVIDO → D-033** (contagem abstrata em cima, horário concreto materializado na assunção/agendamento). Foi exatamente a recomendação.
- 🟡 Fórmula exata de capacidade: **input = duração em minutos (D-039)**; **intervalos/almoço RESOLVIDO → D-051** (períodos por dia; o vão não gera slots). **Falta só tratar feriados.**
- 🟡 Auditoria do ajuste manual de estoque ("retornos/extras", D-032): quem pode, trilha (LGPD).
- ✅ ~~Escopo de dados: Solicitante vê só o estado; Gestor só a unidade~~ **RESOLVIDO → D-031/D-038** (solicitante=estado/cliente; gestor=vê pool do estado + possui a unidade, com cota fixa).
- 🟡 Mapeamento de especialidades (texto / `internal_specialization_id`) com a TC.
- 🟡 Localizar no repo da TC o endpoint de "pacientes por health center" (D-012) e o de criação de PartnerType/API-key.

## 🟡 Surgidas na implementação do CRUD de Usuários (FASE B — backend)
- 🟡 **Composição do campo `org` do usuário:** no front (`UsuariosPage.tsx`, `orgFor`) o `org` é
  calculado no cliente (nome da unidade p/ gestor, nome do HealthCenter p/ solicitante, 'PTM' p/ os
  demais). O contrato do `POST/PUT /api/usuarios` recebe `{name,email,role,scope*}` SEM `org`. O backend
  hoje deriva um valor CONSERVADOR a partir do escopo (un → hc → 'PTM') só para não gravar vazio.
  **Confirmar a regra canônica:** o backend deve derivar `org` (e como — resolvendo nome real da
  unidade/HC?), ou o contrato deve passar a receber `org` explicitamente do front?

## 🟡 Surgidas na refatoração do protótipo (FASE A — modelo de 3 níveis)
- 🟡 **Editar a quantidade solicitada de uma demanda já registrada:** o redesenho da tela
  `SolicitacoesPage.tsx` em "planilha de demanda do mês" (uma linha por especialidade, um único submit)
  precisa decidir o que acontece quando o Solicitante quer **corrigir/atualizar** uma especialidade que
  JÁ tem solicitação na competência. Hoje a `store.tsx` só expõe `addSolicitacao` (CRIA) — **não há
  função de ATUALIZAR `solicitado`**. Para não inventar regra nem criar duplicata, a tela trava o input
  dessas especialidades (mostra o valor atual + status, desabilitado, com nota "já registrada"). Confirmar:
  o Solicitante pode **editar** uma demanda já enviada? Pode **reenviar** (gerar nova solicitação na mesma
  competência, somando)? Há janela/trava após disponibilização começar? Tem trilha de auditoria (LGPD)?
  Enquanto não confirmado, fica READ-ONLY para o que já existe. NÃO inferido.
- 🟡 **Limite de agendamentos por reserva:** a SPEC-000 diz que a reserva pode ser só quantidade e
  que o agendamento é desacoplado (D-042/D-044), mas **não** define se o nº de agendamentos de uma
  unidade pode exceder a `qtd` reservada. No protótipo o `agendar()` NÃO trava contra `reserva.qtd`
  (comportamento conservador, marcado `// ⚠️ PROVISÓRIO` em `store.tsx`). Confirmar se deve travar.
- 🟡 **UF do HealthCenter:** a TC não tem coluna de UF (doc 08); o protótipo carrega `uf` como DADO
  descritivo no `HealthCenter` (não como regra). Confirmar se a UF precisa ser modelada formalmente.
- 🟡 **Doutor "preferencial" no agendamento (D-011/D-034):** a SPEC-000 diz "preferencial do paciente
  → fallback de especialidade", mas a `store.tsx` **não** expõe o preferencial do paciente em retorno
  (nem há histórico de último doutor). Na tela `AgendamentoPage.tsx` a sugestão é, conservadoramente, o
  **1º doutor da especialidade** (`buscarDoctors(esp)[0]`) — com troca livre entre doutores da mesma
  especialidade. Confirmar a fonte do "preferencial" (campo do paciente? último agendamento? vínculo na
  TC?) para que a sugestão deixe de ser só o fallback. NÃO inferido.
- 🟡 **Quem edita o teto diário da unidade?** A tela "Estados & Unidades" (`ClientesPage.tsx`) mostra
  o `tetoDiario` como leitura. A SPEC-000 diz que o teto é "cadastrado por unidade, fixo" (D-037/D-046),
  mas **não** define o papel que cadastra/edita (Admin? Demandas? Gestor da própria unidade?) nem se há
  trilha de auditoria da mudança. Mantido READ-ONLY até confirmar — não inferir.
- 🟡 **Granularidade do teto na assunção (DIÁRIO × competência MENSAL):** D-037/D-046 definem o teto
  da unidade como **diário**, mas a reserva/assunção (tela Assunção, `AssuncaoPage.tsx`) é por
  **competência mensal**. A SPEC-000 (D-036) diz "min(saldo do pool, teto diário da unidade)" sem
  definir conversão dia→mês. O protótipo aplica o limite **literal** (min(saldoPool, tetoDiario)) sem
  inferir multiplicação por dias úteis (marcado `// ⚠️ PROVISÓRIO`). Confirmar se o limite da reserva
  mensal é o teto diário cru, o diário × dias úteis, ou um teto mensal separado.
- 🟡 **KPIs por persona no Dashboard (Visão geral):** a SPEC-000 confirma o funil
  Solicitado→Disponibilizado→Reservado→Agendado e o escopo por papel (D-038), mas **não** define o
  conjunto EXATO de KPIs que cada persona deve ver na home. O protótipo (`DashboardPage.tsx`) mostra
  o mesmo funil de 4 KPIs + "Saldo em aberto" para todos, escopado por dado (gestor = sua unidade;
  solicitante = seu estado; admin/demandas = global). Confirmar se cada papel quer KPIs distintos
  (ex.: gestor focar "reservado a agendar" e "teto vs reservado"; solicitante focar só saldo da sua
  demanda) — escolha conservadora feita só com dados existentes, sem inferir regra.
- 🟡 **Sugestão híbrida da disponibilização (D-045) — base de cálculo:** na tela de Disponibilização
  (`DisponibilizacaoPage.tsx`) o número sugerido é a **contagem de slots de UMA semana** de referência
  das escalas ativas da especialidade. A SPEC-000 NÃO define como converter isso em capacidade da
  **competência** (mês): quantas semanas contam? como tratar intervalos (almoço) e feriados? (já listado
  como 🟡 "fórmula de capacidade" na SPEC-000 §8). No protótipo NÃO multiplicamos por nº de semanas —
  marcado `// ⚠️ PROVISÓRIO`. Confirmar a fórmula com o Alessandro.
- 🟡 **Teto de disponibilização:** a SPEC-000 não define um limite superior para o número
  disponibilizado (pool) — pode passar do solicitado? Está atrelado à oferta real da escala? O protótipo
  aceita qualquer inteiro ≥ 0 (sem teto, conforme `store.disponibilizar`). Confirmar.
- 🟡 **Histórico da escala no servidor (`historicoEscala` / `EventoEscala`):** o front mantém uma trilha
  de eventos "criou/removeu" bloco em localStorage (`store.tsx`), mas o schema do server (`001_init.sql`)
  **não tem tabela de histórico**. A API de Escala (`EscalaEndpoints.cs`) NÃO expõe
  `GET /api/escala/historico` para não inventar persistência. Confirmar se o histórico deve ser
  persistido no banco (e com que campos/retenção — relevante p/ LGPD/auditoria, ligado à pergunta de
  "auditoria do ajuste manual" acima) ou se é só conveniência de UI.

## 🟡 Surgidas na implementação do backend (Execução — reservas/agendamentos)
- 🟡 **Limite de agendamentos por reserva (backend):** mantida a decisão conservadora do protótipo —
  o `POST /api/agendamentos` NÃO trava o nº de agendamentos contra `reserva.qtd` (só valida reserva
  existente + slot livre, igual ao `store.agendar`). Atenção: a tela `AgendamentoPage.tsx` JÁ filtra
  `reservasComVaga = agsPorReserva < qtd` na UI, então a UI sugere que o teto existe — mas a SPEC-000
  não o define explicitamente e o `store.agendar()` não o aplica. **Há divergência UI×store.** Confirmar
  se o servidor deve recusar (400) agendamento que exceda `reserva.qtd`.
- 🟡 **`slotKey` obrigatório no POST /api/agendamentos:** o escopo lista `slotKey?` como opcional, mas é
  a PK do agendamento (`escala.slotKey` = `${blocoId}|dia|inicio`) e sem ele não há horário a materializar.
  O backend EXIGE `slotKey` (recusa 400 se ausente) — não inventei geração de slot. Confirmar se há caso
  de agendamento sem slot ou se obrigatório está correto.
- 🟡 **Quem cancela reserva/agendamento (papel):** o backend permite cancelar a admin/demandas (visão
  ampla) e ao gestor SÓ no escopo da própria unidade (fail-closed). Solicitante não participa (403). A
  SPEC-000 não detalha o papel que cancela — escolha conservadora alinhada ao D-038, a confirmar.
- 🟡 **Validação doutor↔especialidade / paciente↔unidade no agendamento:** o `store.agendar` (e portanto
  o backend) NÃO valida que o doutor é da especialidade da reserva nem que o paciente é da unidade da
  reserva — confia no front (D-034: doutor sugerido vem do front). A UI restringe as opções, mas o
  endpoint aceita qualquer `doctorId`/`pacienteId`. Confirmar se o servidor deve validar esses vínculos
  (defesa em profundidade) ou manter o front como única trava.

## 🟢 Pode esperar
- 🟢 Volume esperado (nº de HCs, médicos, especialidades, solicitações/mês) — afina dimensionamento.
- 🟢 Ambientes (homolog/prod), hospedagem, SLA.
- 🟢 "PDF Modelo" de cobertura citado no whiteboard — compartilhar quando possível.

## ✅ Regras inferidas no protótipo — TODAS DECIDIDAS em 2026-06-15 (ver D-031..D-040)
> Em 2026-06-15 o Alessandro respondeu o questionário de 10 perguntas. Tudo que o protótipo havia
> tomado como provisório virou decisão registrada. Resumo do que mudou (detalhe no decisions-log):
- ✅ **Núcleo oferta×demanda → D-031:** modelo de 3 níveis. Solicitação + disponibilização no **ESTADO** (pool por estado); Gestor **assume** fatia p/ sua unidade; Gestor materializa doutor+paciente. (Resolve "slot→HC", "fonte única da capacidade", "quem reserva/agenda".) **Reescreve o protótipo, que era por HC.**
- ✅ **Disponibilização = misto → D-032** (sistema sugere da escala, operador ajusta).
- ✅ **Granularidade do estoque = híbrido → D-033** (pool = contagem abstrata; horário concreto materializado da escala na assunção). Atualiza D-028.
- ✅ **Máquina de status → D-035:** 3 estados simples (Enviada → Parcial → Atendida), derivado de disponibilizado×solicitado.
- ✅ **Doutor no slot → D-034:** sugere (preferencial D-011) + permite trocar.
- ✅ **Elegibilidade/limite da reserva → D-036 + D-037:** saldo do pool **+ teto da unidade** (cota = cadastro fixo por unidade).
- ✅ **Escopo do Gestor → D-038:** dois eixos válidos (vê pool do **estado**, possui a **unidade**). `scopeClienteId`+`scopeHcId` não são dead-data.
- ✅ **Duração do slot → D-039:** escala definida por **duração em minutos** por consulta; consultas/hora é só aproximação. Inverte o input da escala.
- ✅ **Borda dos inputs → D-040:** reforçar p/ WCAG 1.4.11 (3:1).
- ⓘ Itens técnicos relacionados JÁ corrigidos no protótipo (não são regra de negócio): fail-closed no filtro de escopo; sobreposição de blocos que cruzam a meia-noite; id de bloco monotônico; agendamento exige reserva.

> ⚙️ **Pendente de IMPLEMENTAÇÃO** (decisões tomadas, código ainda reflete o modelo antigo por-HC):
> o protótipo `app/` precisa ser **refatorado para o modelo de 3 níveis (D-031)** — solicitação/pool
> por estado, assunção do gestor com teto por unidade, escala por duração em minutos. Não é mais
> pergunta aberta — é trabalho de construção.

## 💼 Para a estimativa (Fase 4)
- 🟡 Prazo-alvo e orçamento mental para a 1ª entrega.
- 🟡 Quem aprova o escopo e participa dos gates semanais.

## 🧭 Cockpit C-level / lado da DEMANDA (suposições do loop overnight 2026-06-17 — PROVISÓRIO)
> Telas exploratórias de visão executiva construídas no Figma (`snTNGRUJO2GwoKpXTHCBjf`) usam números-demo.
> Cada definição abaixo precisa de ✅ do Alessandro/diretoria antes de virar regra. Ver `docs/product/15-overnight-*`.
- ✅ **RESOLVIDO por D-083 (2026-06-18):** a DEMANDA vem por **estado × especialidade** (fases futuras); sem o estado
  enviar, **não existe** → o cockpit mostra a **NOSSA CAPACIDADE DE ENTREGA**, não demanda inventada nem "gap".
  As perguntas de demanda abaixo passam a valer **só** quando a demanda real chegar (por estado).
- 🔵 (futuro) **"Demanda" (o que falta cobrir):** de onde vem o número de atendimentos necessários por especialidade/dia?
  (fila represada histórica? meta da secretaria? solicitação formal D-008?) — **só quando vier por estado** (D-083).
- 🔴 **"Demanda represada / anos de espera":** existe esse dado? unidade (pacientes na fila? atendimentos/mês?)?
- 🔴 **Gap = Demanda − Oferta:** "preciso 100 de Gineco terça, tenho M, faltam N". Oferta = slots da escala (D-072).
  A Demanda é a incógnita. Regra de cor/alerta do gap (quando vira "vermelho/contratar")?
- 🔴 **Previsão de falta de cobertura (forecast):** horizonte (próximas 4 semanas?), método (repete escala vigente?
  tendência?), o que conta como "vai faltar".
- 🔴 **Ação "Contratar/Suprir gap":** o que o botão dispara no mundo real (abrir vaga? notificar? gerar demanda)?
- 🔴 **Conjunto de KPIs da Home executiva:** "a confirmar com a diretoria" (já rotulado provisório na tela 28:2).
- 🔴 **Limiar/severidade do gap:** a partir de que % de cobertura é Crítico/Reforçar/OK? (provisório: <85% / 85–99% / ≥100%). Necessário p/ alerta proativo e tabela.
- 🔴 **Dado de represamento/anos de espera:** existe por especialidade/unidade? em que fonte e unidade? (habilita KPI de aging 0-30/30-90/90-180/180+ e coluna de SLA).
- 🟡 **Segmentação por estado/HC/cliente:** a demanda chega identificada por governo? (habilita filtro global por carteira; hoje números são agregados nacionais).
- 🟡 **Definição oficial de cadastro "incompleto":** quais campos exatos bloqueiam faturamento? (hoje provisório: CPF/RQE/valor — D-055).
- 🟡 **Feriados no cálculo de Oferta:** slots da escala em feriado contam ou não? (borda do "atendimentosNaVigencia", D-072 PROVISÓRIO).
- 🟡 **Precedência Remanejar-antes-de-Contratar (RN-39):** há restrição clínica/contratual que impeça puxar capacidade de uma especialidade com folga p/ outra?
> _(Levantadas pelo painel multi-agente C-level — `docs/product/16-overnight-melhorias-c-level.md`, 2026-06-18.)_

## 🧾 Faturamento por produto — Teleconsulta vs Telediagnóstico (surgidas em D-086, 2026-06-18)
> Alessandro está escrevendo aos poucos. Confirmado: 2 produtos, faturamento separado; teleconsulta por hora|consulta
> (valor por especialidade) + escala de clínico geral; telediagnóstico por laudo. Pendente p/ desenhar a ficha:
- ✅ **RESOLVIDO (2026-06-18):** o **modo (hora|consulta) é por ESPECIALIDADE** (cada especialidade do médico no
  teleconsulta tem modo + valor próprios). Ex.: Cardiologia por consulta R$40/20min · Clínico Geral por hora R$180.
- ✅ **RESOLVIDO (2026-06-18):** Telediagnóstico = **valor por laudo POR TIPO DE EXAME/MODALIDADE** (cada exame tem seu valor).
- ✅ **RESOLVIDO (2026-06-18):** **médico pode atender os DOIS produtos** → a ficha mostra os dois blocos quando provisionado em ambos.
- 🟡 **Tempo de atendimento:** só relevante p/ teleconsulta **por consulta** (define slots). No modo **por hora**, como
  entram os slots/capacidade? No telediagnóstico (por laudo), não há tempo de atendimento — qual a unidade de capacidade?
- 🟡 **Clínico Geral escalável:** volta ao seletor de especialidade da escala (revisita D-067, que o tirava da atribuição)?

## 💰 Modelo de valor por atendimento + tempo de atendimento (surgidas em D-085, 2026-06-18)
> O Alessandro definiu valor POR ATENDIMENTO + tempo de atendimento default por médico. Antes de virar cálculo:
- ✅ **RESOLVIDO (2026-06-18):** tempo + valor são **por médico × especialidade** (confirmado por Alessandro). Cada
  especialidade do médico tem seu **tempo de atendimento** e **valor por atendimento** (ex.: Cardiologia 20 min/R$ 40 ·
  Clínica 15 min/R$ 30). Modelagem: mover esses campos da ficha (nível médico) para `doctor_specialties` (já tem RQE — D-064).
- 🔴 **CASCATA de recálculo (slots/capacidade):** hoje a escala mostra blocos com duração própria ("15 min") e os números
  de capacidade (escala "64 slots", cockpit "2.249 slots/sem", Cardiologia "448") foram calculados com a duração antiga.
  Com D-085, **a duração do slot = tempo de atendimento do médico**. Confirmar o tempo (por médico/especialidade) e então
  **recalcular consistentemente** Escala + Relatório/Capacidade + Cockpit. _(Não recalculado ainda — evita inventar número.)_
- 🟡 **Hora adicional:** o valor da hora adicional (lançado na Escala, D-065) é **por hora** ou também **por atendimento**?
  E a duração do atendimento na disponibilidade adicional = o mesmo tempo default do médico?

## 🩺 Saneamento da base / "médico inativo" (surgidas em D-084, 2026-06-18)
> O Alessandro pediu inativar médicos que não atendem mais e **não contar inativo como pendência** se não tem
> escala nem valor. Antes de virar regra/código, confirmar (NÃO inferir):
- ✅ **RESOLVIDO (2026-06-18):** o flag "inativo" **já existe** = coluna local `doctors.active` (migration
  `001_init.sql`), controlada pela **ação "Inativar" já implementada** (Figma: zona de risco → confirmação `92:2`
  → ficha inativa `55:2` → edição bloqueada `111:2`; UX feedbacks #1/#2). A tela de Capacidade **reusa** esse fluxo,
  não cria outro. _(Resta confirmar só o critério de SUGERIR inativação e o efeito no denominador — abaixo.)_
- 🔴 **"Valor de pagamento" da regra de pendência:** é o **valor/h fixo do cadastro** (D-061/D-053)? Conta valor
  adicional? Ter qualquer um dos dois já "exclui da pendência" ou precisa do fixo?
- 🔴 **Critério para sugerir inativação:** o que marca um médico como "não atende mais"? (sem escala há N meses?
  sem atendimento realizado há N? decisão manual do gestor?) — afeta a worklist de saneamento.
- 🟡 **Efeito no denominador da Taxa de ativação:** confirmado que o denominador = cadastrados **ATIVOS** (exclui
  inativos sem escala e sem valor). Inativo COM escala ou COM valor permanece no denominador?

## 📊 Período de cálculo do estoque — D-113 (22 dias úteis) × modelo v2 (mês-calendário ∩ vigência) (surgida na auditoria de maturidade, 2026-06-25)
> A auditoria de coerência apontou que coexistiam DOIS cálculos de estoque: o **v1** (D-113: `vagas/dia × 22
> dias úteis` = 264 p/ o Henrique) e o **v2** (multi-escala FIXA/FLEX contando ocorrências do dia-da-semana
> dentro de `período ∩ vigência` = 132+24=156). O caminho **v1 foi REMOVIDO** (código) p/ não haver dois números,
> mas a definição oficial do período precisa ser confirmada (NÃO inferir):
- 🔴 **Qual é o período canônico do estoque?** (a) mês-calendário corrente contando os dias reais em que a escala
  é válida (modelo v2, respeita vigência/effective-dating), ou (b) "22 dias úteis" fixos (D-113)? Os dois divergem
  porque o v2 respeita a vigência (ex.: FIXA do Henrique começa 16/06 → só 11 dias úteis no mês, não 22).
- 🔴 **D-113 fica revisada?** Se o canônico é o v2, a D-113 ("22 dias úteis") deve ser atualizada para "dias válidos
  no período = período ∩ vigência, por dia-da-semana". Confirmar com o Alessandro antes de reescrever a decisão.
- 🟡 **Sábados/domingos:** o v2 já conta sábado (FLEX do Henrique) — confirmar que fins de semana entram no estoque
  quando há escala FLEX nesses dias (hoje entram).

## 📧 Empresa de CAPTAÇÃO — destinatário do relatório/e-mail (surgida ao implementar o pipeline, 2026-06-25)
> O objetivo prevê: sem capacidade → gerar RELATÓRIO + disparar E-MAIL a uma "empresa de captação" que
> recruta médicos. A UI já gera o relatório (consolidado de contratação) e registra o disparo na Auditoria,
> mas o DESTINATÁRIO não está na discovery (NÃO inferir):
- 🔴 **Quem é a empresa de captação?** É uma empresa externa fixa, várias (por região/especialidade), ou um
  setor interno? Qual o e-mail/canal de envio?
- 🔴 **O que vai no e-mail?** Só o consolidado (especialidade × faltam × clientes/prazos) ou também dados de
  contexto (período, prioridade, valor/h alvo)?
- 🟡 **Retorno do ciclo:** quando a captação inclui o médico (disponibilidade+especialidades), como isso volta
  ao sistema e soma à capacidade — entrada manual no cadastro de médicos, importação, ou integração?

## 🔁 "Capacidade soma" — capacidade derivada das escalas × `disponivel` estático (auditoria 2ª rodada, 2026-06-25)
> O painel agora mostra "Nossa capacidade efetiva por especialidade" DERIVADA das escalas (capacidadeInstalada),
> que cresce AO VIVO quando um médico/escala entra — o elo "médico entra→capacidade soma" do objetivo é visível.
> PORÉM o downstream (Disponibilização, Sobrepor, consolidado de contratação) ainda lê `Especialidade.disponivel`,
> um número ESTÁTICO da fixture, desconectado das escalas. NÃO inferir como reconciliar:
- 🔴 **`disponivel` deve passar a derivar de Σ estoqueMedico (escalas vigentes)?** Ou `disponivel` (capacidade
  livre p/ alocação imediata) é um conceito distinto da capacidade instalada (já há PROVISÓRIO em types.ts)?
- 🟡 Se derivar: a avaliação cobre/falta (UC-FALTA "faltam 300") passaria a reagir às escalas — confirmar o
  efeito desejado antes de ligar (hoje os casos canônicos dependem dos números fixos da fixture).

## 🔑 Trocar a senha de gestão sem reautenticação (auditoria de maturidade 3, 2026-06-25)
> Na tela "Configurações do sistema" (persona Demandas), a senha de gestão (que protege excluir/trocar
> escala iniciada, D-123) pode ser TROCADA sem provar identidade (sem pedir a senha atual). Coerência:
> a senha protege ações sensíveis, mas trocá-la não exige prova. No mock é aceitável; NÃO inferir o real:
- 🔴 **Quem pode trocar a senha de gestão?** Só admin? Exige reautenticação (senha atual) antes de trocar?
- 🟡 No backend: senha nunca trafega/persiste no client; troca via endpoint autenticado + RBAC.

## ✏️ Editar dados do médico — escopo dos campos editáveis (D-127, 2026-06-25)
> O card "Dados do médico" tem "Editar" funcional: edita CPF/nascimento/telefone/e-mail; NOME e CRM
> ficam bloqueados (vêm do credenciamento). NÃO inferir o que falta:
- 🔴 **NOME/CRM realmente nunca editáveis no hub?** (vêm da fonte oficial/credenciamento — ou há caso de correção?)
- ✅ **Edição dos VALORES de faturamento** — IMPLEMENTADA (D-128, CRUD add/alterar/inativar/remover, auditado).
  🔴 **Falta:** **effective-dating** — alterar valor hoje vale imediato; o real precisa "a partir de quando vale"
  (ex.: novo valor só p/ atendimentos futuros) + **aprovação** (quem pode alterar valor financeiro)?
- 🟡 Validação real de CPF/RQE contra fonte oficial; no mock só há máscara + validação de dígito do CPF.

## 📤 Provisionamento aos produtos de destino (Teleconsulta/Telediagnóstico) (D-130, 2026-06-25)
> A ficha tem o card "Provisionamento · destinos" (Figma), HOJE só reflete o que está configurado p/
> faturar em cada produto e é marcado "provisório — mecanismo a definir". NÃO inferir:
- 🔴 **O que é "provisionar" um médico num produto?** Cria/ativa o profissional na Teleconsulta/Telediagnóstico
  (via sync D-069?), ou é só um flag interno? Quem dispara, quando, e o que precisa estar completo antes?
- 🟡 Telediagnóstico como 2º destino: mesmo mecanismo da Teleconsulta ou fluxo próprio?

## 🌙 Escala que cruza a meia-noite (Madrugada 22–02) (D-131, 2026-06-25)
> O preset "Madrugada (22–02)" está DESABILITADO: o motor de estoque (horasDoBloco) não calcula
> bloco que vira o dia (fim ≤ início = inválido hoje). D-022 já previa "bloco pode cruzar a meia-noite"
> como futuro. NÃO inferir: confirmar se há demanda real de plantão de madrugada e como contar os slots
> (dividir em 22–24 + 00–02? turno único?) antes de habilitar.

## 🔄 Sync Doctor-Hub ← Teleconsulta (carga + atualizações, D-133, 2026-06-25)
> Backend iniciado: o Doctor-Hub vira a fonte da verdade de médicos; sync TEMPORÁRIO via banco
> read-only (D-069) + BackgroundService leve. NÃO inferir — confirmar com humano (baseline de segurança):
- 🔴 **Mapeamento exato TC→Doctor** (confirmar campo a campo): `doctor_profiles.id`→ExternalId;
  `User.Person.FirstName+LastName`→Nome; `DoctorProfileLicense.license`→Crm (e RQE?); `doctor_profiles.cpf`→Cpf;
  `Specialization`(enum DoctorSpecializationType) / specialty por license → Especialidade. **CNS** entra?
  **Multi-especialidade** (TC tem N licenses/specialties): como mapear p/ a v1 (Especialidade única)?
- 🟡 **CBO das especialidades** — a TC tem a tabela `Specialty` mas o CBO das **33 operacionais** (legacy
  0..32) é placeholder `TEMP_xx`. Decisão (D-133): doctor-hub semeia os **nomes/ids da TC** com o **CBO REAL**
  (CBO 2002/MTE, pesquisado). **Confirmar os ⚠** (CBO não tem código próprio): Obstetra=Ginecologista (225250),
  Traumatologista=Ortopedista (225270), variantes "Infantil" (Psiquiatra/Neurologista/Endócrino/Psicólogo)
  caem no CBO base, Hepatologia→Gastroenterologista (225165). E se as 35 não-operacionais (CBO real, sem
  doutores) entram também.
- 🔴 **Credencial READ-ONLY dedicada** + allowlist tabela:colunas (D-069/baseline) — host/usuário/segredo (infra).
- 🟡 **Política de conflito na TRANSIÇÃO:** enquanto a TC é a fonte, o sync sobrescreve edições locais do hub?
  (hoje: TC vence; quando inverter, o sync é removido). Confirmar.
- 🟡 **Watermark:** onde persistir o "último sync OK" (tabela SyncState?) p/ o incremental por updated_at.
- 🟡 **`deleted_at` (soft-delete na TC)** → desativa aqui. E se for "re-criado" depois? (reativar?)

## 🔑 RQE não vem da origem (descoberta 2026-06-25, sync Core-Api)
> O código antigo (saude-digital-demandas) SUMIU, mas o DB `saude_demandas` (4523 médicos sincronizados
> da Core-Api) sobrevive como gabarito. Achado: `doctor_specialties.rqe` está **vazio em 4524 de 4525**
> (só 1 registro de teste). Ou seja, o **RQE não está disponível/preenchido na origem (Core-Api)**.
> O usuário pediu "RQE para especialidades" (modelado em DoctorEspecialidade.Rqe). NÃO inferir:
- 🔴 **De onde vem o RQE?** (a) é cadastrado/gerido no Doctor-Hub (vira NOSSO dado, coerente com "fonte
  da verdade") e o sync NÃO mexe nele; (b) existe em outro campo/tabela da Core-Api que não achamos; (c)
  fica vazio até ser preenchido. Hoje o sync não tem de onde puxá-lo.
- 🟡 **Mapeamento doutor→especialidade (Core-Api):** chave do doutor = `doctor_profiles.id`; especialidade
  via `doctor_profiles.specialization` (enum) → nossa Especialidade por `ExternalId` (legacy id). CRM via
  `doctor_profile_licenses.license` (confirmar CRM×RQE). Multi-especialidade é raro (quase todos 1).
