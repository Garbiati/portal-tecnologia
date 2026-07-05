# Discovery — Cancelamentos pelo médico em telemedicina (pesquisa de mercado + regulação)

> **Fonte:** agente de pesquisa, madrugada 2026-07-05 (missão autorizada pelo Alessandro).
> Complementa o braindump [discovery/13](13-agendamentos-faltas-e-flexibilidade.md). Todas as
> afirmações têm fonte; benchmarks numéricos verificados. Status: DISCOVERY (nada vira código
> sem spec — mas o MODELO OPERACIONAL abaixo é a base proposta para a spec de agendamentos).

## Achados-chave (com fonte)

1. **Cancelamento pelo médico ("bump") é ~4,9% em média** (range 0,7–12,4%; 53 orgs, AAMC/Vizient
   CPSC 2020-21); 68% dos providers bumpam 1-10×/mês. Em telessaúde, razões TÉCNICAS lideram (36%)
   → teste de conexão pré-consulta mitiga.
2. **Backfill automatizado de slot funciona** (UCSF Fast Pass, JMIR 2024): 11% de aceite, 84% das
   aceitas realizadas, pacientes atendidos 14 dias antes, 2.576h clínicas recuperadas. ⚠️ Equidade:
   idosos/não-falantes usam menos (OR 0,62–0,86) → fallback humano/telefone obrigatório.
3. **Float provider (= "doutor de plantão da operação" do Alessandro) é padrão consolidado** de
   mercado (internal locums), dimensionado pela taxa histórica de ausência.
4. **Overbooking serve p/ no-show de PACIENTE, não de médico.**
5. **⭐ Achado mais importante (Liu et al., M&SOM):** remarcação INICIADA PELA CLÍNICA piora o
   no-show do retorno em +6,2 p.p.; iniciada PELO PACIENTE melhora em −10,9 p.p. → a mensagem de
   cancelamento deve SEMPRE oferecer horários concretos p/ o paciente ESCOLHER (1/2/3), nunca
   "aguarde contato".
6. **Tempo ideal de reagendamento: ≤7 dias, teto 14** (curvas de lead-time: no-show 9%→38% de
   0-2sem → 6 meses; em psiquiatria 71% remarcam em ≤2 semanas e mantêm vínculo).
7. **Regulação BR (li a íntegra):**
   - **CFM 2.314/2022 art. 6º §2º**: crônico/longo prazo exige presencial com o MÉDICO ASSISTENTE
     a cada ≤180 dias → o retorno é DO médico; trocar quebra a cadeia (valida a regra do Alessandro
     sobre psiquiatria). Sistema precisa do "relógio de 180 dias" por paciente crônico.
   - **CEM art. 36 (CFM 2.217/2018)**: vedado abandonar paciente; renúncia exige comunicação prévia
     + continuidade assegurada → o fluxo "remarcar com prioridade + registro" é COMPLIANCE, não só UX.
   - Lei 14.510/2022 (telessaúde permanente). Evidência clínica: troca de terapeuta ↑ dropout (DBT).

## Benchmarks (tabela de referência)

| Métrica | Valor | Fonte |
|---|---|---|
| Cancel rate por médico (média EUA) | 4,9% (0,7–12,4%) | AAMC/Vizient |
| Remarcação imposta pela clínica → no-show retorno | +6,2 p.p. | Liu et al. M&SOM |
| Remarcação escolhida pelo paciente | −10,9 p.p. | Liu et al. |
| No-show × lead time | 9,1% (0-2 sem) → 38,3% (6 meses) | PMC4370946 |
| Absenteísmo SUS | ~25%; com lembrete WhatsApp acionável: 8,3% | COSEMS-SP/Medscape |
| Lembrete WhatsApp SEM ação (RCT BR) | n.s. (24% vs 25,5%) | Redalyc |
| Meta sugerida doc hub | late-cancel ≤5%; investigar >8% | derivado Vizient |

## MODELO OPERACIONAL PROPOSTO (base da futura spec)

1. **Tipologia de cancelamento** (doença/emergência/conflito/administrativo/sem justificativa) +
   timestamp + lead time; "late cancel" = <48h (parametrizável).
2. **Doutor de plantão (float)** p/ 1º atendimento — redistribuição no MESMO horário quando
   possível; redistribuído no prazo NÃO conta contra ninguém no indicador (padrão Vizient —
   premia a operação que resolve).
3. **Continuidade (psi etc.): NUNCA troca** — remarca com o próprio médico, alvo ≤7d teto 14d;
   estourou → coordenação humana. Relógio de 180 dias (CFM) por crônico.
4. **Fila de reencaixe com score** (prioridade clínica + nº de penalizações + dias desde o
   cancelamento). **Escala de ENCAIXE**: reservar 10–15% dos slots da semana seguinte DO médico
   que cancelou (ele "paga" primeiro) + slots do plantão.
5. **Backfill automático de slot vago** (padrão Fast Pass): oferta WhatsApp top-N da fila, aceite
   1 toque, expira em X min; fallback telefone (equidade). Meta inicial 40–60% de recuperação.
6. **Remarcação SEMPRE com escolha do paciente** (1/2/3 na própria mensagem).
7. **Métricas do médico com fairness**: late-cancel discricionário (principal) + lead time de
   aviso + comparecimento dos reagendados + utilização. Salvaguardas: denominador ≥50 consultas,
   janela 90d, atestado fora do discricionário, SEM ranking público, outlier → conversa 1:1.
8. **Métricas da operação**: mediana cancelamento→reatendido; % reatendidos ≤7d; taxa de
   recuperação de slot; no-show dos reagendados (alarme Liu).
9. **Compliance embutido**: tudo registrado/auditável; zero dado clínico em mensagem (LGPD).
10. **Mensagens-modelo PT-BR** (WhatsApp/SMS):
    - *1ª consulta redistribuída:* "Olá, [Nome]. Tivemos um imprevisto e precisamos ajustar sua
      consulta de [data] às [hora]. Para você não esperar, o(a) Dr(a). [Plantonista] vai te atender
      no mesmo horário. Está bem para você? Responda SIM para confirmar ou 2 para escolher outro horário."
    - *Retorno de continuidade:* "Olá, [Nome]. O(a) Dr(a). [X] teve um imprevisto e não poderá te
      atender em [data] às [hora]. Pedimos desculpas — sabemos que você se organizou para esse
      horário. Vamos reagendar com PRIORIDADE MÁXIMA com o(a) próprio(a) Dr(a). [X]. Temos:
      (1) [data/hora] (2) [data/hora] (3) outro horário. Responda 1, 2 ou 3."
    - *Oferta de encaixe:* "Boa notícia, [Nome]! Abriu um horário com o(a) Dr(a). [X] em [data] às
      [hora] e você tem prioridade. Quer esse horário? Responda SIM nos próximos 30 minutos."
    - *Fallback 24h:* "Olá, [Nome], ainda queremos reagendar sua consulta com prioridade. Responda
      por aqui ou, se preferir, responda LIGAR que nossa equipe te liga."

## ❓ Perguntas pro Alessandro (não inferidas)
(a) atestado do médico entra no indicador individual ou só no operacional? (b) teto de dias p/
reencaixe de 1ª consulta (evidência: ≤14d; há SLA contratual dos projetos?) (c) plantonista é
papel fixo remunerado ou rodízio? (d) psicologia (CFP) segue as mesmas regras que psiquiatria (CFM)?

## Fontes principais
AAMC/Vizient CPSC (vizientinc-delivery.sitecorecontenthub.cloud) · Liu et al. M&SOM
(pubsonline.informs.org/doi/abs/10.1287/msom.2018.0724) · UCSF Fast Pass (PMC10988365) ·
CFM 2.314/2022 (sistemas.cfm.org.br) · CEM 2.217/2018 art. 36 · PMC4370946 · PubMed 28067678 ·
BMC 12913-025-12826-2 · COSEMS-SP · Medscape BR 6510278 · Redalyc 377665638014 · PMC5480417.
