# DDD2 — posicionamento vs. o cenário (Kiro · Spec-Kit · BMAD) e o diferencial

> **Propósito:** decidir, com o mapa na mão, se/como extrair o **DDD2** (P-017) como método próprio
> (repo/nome/curso/livro). Não é decoração — é a base do material da missão do farol ("provar o DDD2 a
> ponto de virar método replicável"). Pesquisa: julho/2026.

## 1. O que é o DDD2 (recap — P-017)
Documentation-Driven Design: a **documentação no centro** (realidade + mudanças + o **porquê**), validada
com o humano; **o código é derivado/colateral**; agents especialistas fazem o técnico. Vive na governança
deste umbrella (`.claude/rules`, `agents/`, `skills/`, `specs/`, decisions-log com rationale + checagem de coerência).

## 2. O cenário (2025-26): SDD virou mainstream — o espaço é grande
- **[Kiro (AWS)](https://kiro.dev/)** — IDE agêntica spec-driven (requisitos EARS → design → tasks); GA mar/2026; Bedrock+Claude. "Specs = unidade de trabalho."
- **[GitHub Spec Kit](https://github.com/github/spec-kit)** — toolkit open-source (Spec→Plan→Tasks→Implement), 30+ agents, **~111k stars** (jun/2026).
- **[BMAD Method](https://github.com/bmad-code-org/bmad-method)** — método OSS: "documentação (PRD/arquitetura/stories) é a fonte da verdade, não o código"; agentes + human-in-the-loop.
- Já há [taxonomia acadêmica](https://arxiv.org/pdf/2606.04967) de frameworks de agentes de software.
**Leitura:** AWS e GitHub estão nesta briga → é tendência de indústria, não nicho. O instinto do Alessandro está certo.

## 3. A verdade dura — o CORE já é commodity
O núcleo do DDD2 (doc-como-fonte-da-verdade + agents implementam + humano valida + preservar decisões
cross-sessão) **é exatamente o que Kiro/Spec-Kit/BMAD já entregam**. "DDD2 = mais um framework de SDD" seria
**me-too** num campo lotado, com AWS/GitHub na frente e distribuição que um esforço solo não bate.

## 4. O DIFERENCIAL do DDD2 (o que os grandes NÃO cobrem bem)
1. **Reescrita de LEGADO guiada pela REALIDADE de produção PSEUDONIMIZADA.** Os frameworks são quase todos
   greenfield (feature → código). O DDD2 (como praticado aqui) **reescreve um sistema que existe**, usando o
   **dado/comportamento real como fonte E como oráculo de teste** — de forma **segura, sem expor PII** (o pull
   pseudonimizado; homolog anonimizado × prod real). Nicho valioso e **desservido**.
2. **Governança pra domínio REGULADO (LGPD/saúde/finanças).** Segurança-como-gate (P-014), LGPD, a
   constituição, revisores adversariais. Os frameworks leves não resolvem regulado. Posicionamento que os genéricos não têm.
3. **Profundidade "realidade + porquê", não só spec de feature.** O decisions-log com rationale, a **checagem
   de coerência antes de gravar**, a **classificação por horizonte**, o "documentar a realidade e suas
   mudanças" → um **modelo vivo do domínio**, não um backlog. (Ex.: pegar o conflito "não substitui" × "reescreve".)

## 5. O TRUNFO — um caso real vivo
O **doctor-hub reescrevendo a Teleconsulta** (D-209): saída de fornecedor (SOS Gestor) sem pôr vidas em
risco, EMPI de dado real duplicado, isolamento multi-tenant que habilita coopetição (D-211). **Método provado
na prática > slide.** Nenhum dos grandes tem um estudo de caso regulado desse porte aberto.

## 6. Posicionamento recomendado
- **NÃO** competir em "SDD genérico" (perdido pra AWS/GitHub). **Liderar pelo diferencial:** *reescrever
  sistemas legados regulados, guiado pela realidade pseudonimizada, com prova de conformidade.*
- **Formato:** **conteúdo + caso primeiro** (o livro/curso do farol) — menor esforço, mais credibilidade. O
  **toolkit** (à la Spec-Kit, extraído da governança que JÁ existe aqui) vem depois, se pegar tração.
- **Nome:** "DDD2/Documentation-Driven" é genérico e **colide com Domain-Driven-Design**. Se virar produto,
  nome distintivo em cima do diferencial (reescrita-guiada-pela-realidade / regulado), não "mais um SDD".

## 7. Honestidade (riscos)
- **Distribuição:** AWS/GitHub têm alcance que solo não iguala. "Ser significativo e diferenciado" é realista;
  "vencer AWS/GitHub em SDD genérico" não.
- **Foco:** o produto (doctor-hub) é o que paga as contas; o método é subproduto valioso — não deixar o método
  canibalizar o foco no produto. Extrair quando o caso estiver maduro (mais alguns marcos reais).

## 8. Próximo passo sugerido
Manter este doc como o **posicionamento vivo**; quando houver mais 1-2 marcos reais (fundação em prod +
1ª migração), extrair o **conteúdo do método** com este umbrella como estudo de caso. Não criar repo "no susto".
