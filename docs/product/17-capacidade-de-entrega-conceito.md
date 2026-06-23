# Conceito: "Nossa capacidade de entrega" (substitui Demanda × Oferta) — rascunho p/ discutir

> Origem: D-083 (2026-06-18). Demanda vem por **estado × especialidade** (fases futuras); sem isso, não existe.
> O cockpit mostra **a NOSSA capacidade de entrega** — tudo dado real (sync TC) ou derivável das escalas (D-072).
> **Este é um rascunho de conceito — ainda não construído no Figma.** Decidir antes com o Alessandro.

## 1. Modelo mental — funil de capacidade
Tudo real: base de médicos (sync RO da Teleconsulta) + escalas (nossas). Unidade dupla: **médicos** e **slots/semana**.

```
CADASTRADOS (4.523)            ← capacidade INSTALADA (potencial total)
   └─ com escala ativa (612)   ← capacidade ATIVADA → gera slots/semana (a oferta real ~2.249)
        └─ cadastro completo    ← capacidade FATURÁVEL (só esses viram receita)
   └─ sem escala (3.911)        ← capacidade OCIOSA   → alavanca: ESCALAR
   └─ cadastro incompleto (3.804)← capacidade TRAVADA  → alavanca: COMPLETAR cadastro
```

5 estados: **Instalada · Ativada · Faturável · Ociosa · Travada**. A história da Fase 1 é mover médicos
**Ociosa→Ativada** e **Travada→Faturável** — destravar capacidade que **já existe**, sem depender de demanda.

## 2. KPIs de topo (capacidade) — candidatos
- **Slots/semana** (capacidade ativada, em slots) — número-herói da oferta. _(derivado das escalas, D-072)_
- **Taxa de ativação** = com escala ÷ cadastrados = **14%** (612/4.523) — a maior alavanca da Fase 1.
- **Capacidade ociosa** = médicos sem escala (3.911) — quanto dá pra ativar sem contratar.
- **Capacidade travada** = incompletos (3.804) — quanto não fatura até completar cadastro.

## 3. Tabela por especialidade (o miolo)
| Especialidade | Cadastrados | C/ escala | Slots/sem | Ociosos | Incompletos | % ativação |
|---|---|---|---|---|---|---|
| Ginecologia | 51 | 18 | 320 | 9 | 24 | 35% |
| Cardiologia | … | … | 448 | … | … | … |
- Ordenável (por ociosos, por % ativação baixa, por incompletos…). Recorte por **HC/cliente/estado** = futuro.
- Sem coluna Demanda, sem Gap, sem "preciso N". Linha → drill do pool (ociosos/incompletos) que já existe (`291:1952`).

## 4. Forecast = projeção da NOSSA capacidade (decidido)
Slots/semana das próximas 4 semanas a partir das **vigências** das escalas ativas: **cai quando uma vigência vence
sem renovação**. Alerta "renovar escala antes de vencer". Real, sem demanda. (≠ o forecast de gap atual.)

## 5. Quando a demanda chegar (futuro, por estado × especialidade)
Aí se **sobrepõe** demanda × capacidade → e só então "gap", "contratar" e "previsão de cobertura" fazem sentido.
Hoje = card/placeholder "Demanda por estado — próximas fases".

## 6. Decisões do Alessandro (2026-06-18) — viram D-084

1. **Número-herói = OS DOIS lado a lado:** **médicos ativos** + **capacidade de atendimento**. E a tela tem
   de ser **navegável entre visões**. Frase-âncora dele: _"com base na escala, temos a capacidade de atender
   **X consultas de 20 min de Cardiologia na terça**"_ → a capacidade é **fatiável por especialidade × dia da
   semana × duração**, e mostrada **na linguagem da tabela de disponibilidade** (atendimentos por hora).

2. **Saneamento da base é parte do conceito:** muitos doutores **não atendem mais** e precisam ser **inativados**.
   **Regra nova (denominador):** médico **inativo NÃO conta como pendência** se **não tem escala** **e** **não tem
   valor de pagamento**. Ou seja: "Travada/incompleto" e o denominador da Taxa de ativação **excluem inativos
   sem escala e sem valor**. **O fluxo de inativar JÁ EXISTE** (flag local `doctors.active`; ficha → zona de risco
   → confirmação `92:2` → inativo `55:2` → edição bloqueada `111:2`; UX #1/#2) — a Capacidade **reusa**, não recria.

3. **Gráficos INTERATIVOS, não números estáticos:** o usuário **monta a visão** — _"como estamos **até o fim do
   dia**"_, _"**até o fim do mês**"_. Unidade dupla (slots/semana **e** atendimentos/dia) **derivada do recorte de
   tempo que ele escolher**, não fixa. Seletor de janela temporal (hoje · fim do dia · semana · fim do mês · custom).

### Pontos menores ainda abertos (não bloqueiam o desenho)
- "Faturável" (ativo + completo) vira coluna própria ou fica só como alavanca? → **provisório: coluna leve.**
- Recorte por HC/cliente → **futuro** (só especialidade × dia × hora por ora).

## 7. CONSTRUÍDO no Figma (2026-06-18) — `snTNGRUJO2GwoKpXTHCBjf`
Reconstrução aplicada sobre o cockpit existente (sem inventar regra; tudo `PROVISÓRIO` + proveniência):
- **`279:1916` "Demanda × Oferta" → "Capacidade de entrega":** seletor de janela temporal (Hoje·Fim do dia·**Esta
  semana**·Fim do mês·Custom); herói duplo **Médicos ativos 612** + **Capacidade 2.249 slots/sem**, mais **Ociosa 3.911**
  e **Travada 3.804** (âmbar = alavanca, não vermelho). Callout virou **construtor de visão** (Cardiologia · 20 min ·
  terça → 30; botão laranja "Abrir tabela de disponibilidade" → grade real `237:1790`). `gapTable`→`capacityTable`
  (ESPECIALIDADE·CADASTRADOS·C/ESCALA·SLOTS/SEM·OCIOSOS·INCOMPLETOS — sem demanda/gap/Contratar).
- **`284:1934` "Previsão de cobertura" → "Projeção de capacidade":** matriz vira **slots/semana** das 4 semanas pelas
  vigências, **caindo quando vence sem renovar** (TOTAL 2.249→2.249→2.177→1.894; âmbar = queda). KPIs: capacidade atual,
  projeção fim do mês, escalas a vencer, especialidade + exposta. Volta → Capacidade de entrega.
- **Home `28:2` manchete:** demanda ("faltam 36") → **história real de ativação** ("só 14% têm escala ativa; 3.911 ociosos,
  3.804 incompletos"); botão "Ver gap" → "Ver capacidade". Saneamento reusa o **Inativar existente**.
- **Removidos** (órfãos, contradizem D-083): `283:1941` "Contratar · Suprir gap" + `288:1970` "Suprir gap · registrado".
- **Navegação:** 58/58 telas alcançáveis desde o Login (100%).

## 8. AUDIT de maturidade — varredura das 58 telas (2026-06-18)
Objetivo (pedido do Alessandro): a visão/previsão/insights tem de **bater com o resto** (é um sistema de
**gestão de escalas** com visões de **capacidade de atendimento**, fatiável por operação inteira / especialidade /
range de datas). Varredura programática + correções:
- **Linguagem (demanda inventada):** scan por `gap|déficit|faltam N|contratar|suprir|demanda×oferta|preciso de`.
  Achados e corrigidos: **Home** (card "Demanda × Oferta" + "preciso de 100… faltam 36" → capacidade);
  **Home·sync-falha `297:1988`** (mesma moldura antiga → capacidade); **Pool Gineco `291:1952`** ("Gap −180",
  "89% do gap", "antes de contratar", "Voltar ao Demanda×Oferta" → capacidade parada/ociosa+travada);
  **Saneamento `294:1970`** ("Déficit primeiro"/"em déficit" → "Incompletos primeiro"/"capacidade travada").
  **Scan final = 0 resíduos** (só restam usos legítimos: "Demanda por estado = fases futuras" e o perfil "Demandas Médicas").
- **Navegação:** após reconstruir as tabelas, a linha **Ginecologia → pool `291:1952`** foi religada (havia caído). **58/58 (100%)**.
- **Marcação do menu lateral:** 0 divergências reais (4 "no-sidebar" são Modais + Exportação, que corretamente não têm sidebar).
- **Tabelas:** `capacityTable` e a matriz de Projeção reconstruídas como **grade de colunas fixas** (alinhamento real).

> **Para o PRD:** as **regras** estão em `decisions/decisions-log.md` (D-083, D-084) + `discovery/03-open-questions.md`
> (pendentes) + `discovery/glossary.md` (linguagem). As correções de UI acima são **implementação** dessas regras
> (não regras novas) — registradas aqui como rastro do audit.

## 9. Limpeza p/ "documentação oficial" (2026-06-18)
O Alessandro definiu que **o Figma é o início da documentação OFICIAL** (criada a partir dos logs, mas limpa). Aplicado:
- **Códigos de regra `D-xx` removidos das telas** (28 ocorrências). Anotação de *como/porquê* permanece, em linguagem de
  produto; os códigos ficam só aqui em `docs/`.
- **Menções de sync/Teleconsulta removidas** (~80): nada de "vem da Teleconsulta / sync RO / external_id / sincronizado".
  Linguagem neutra: "dados reais", "atualizado", "base 17/06", "última atualização". Frame "Home·sync-falha" → "Home·dados
  desatualizados". (E-mails dos médicos demo @clinica-demo permanecem — são dado de exemplo, não integração.)
- **Usuário demo:** Yannka Lins → **Millena Garbiati** (`millena.garbiati@portaltelemedicina.com.br`), papel Demandas
  Médicas, org Portal Telemedicina.
- Política registrada na memória `figma-doc-oficial-politica` para não reintroduzir em sessões futuras.
