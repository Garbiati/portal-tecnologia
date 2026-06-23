# <Produto> — Constituição do Produto (template)

> **Template de onboarding.** Copie `products/_template/` → `products/<produto>/`, renomeie e preencha.
> A **constituição-mãe** está na raiz: [`../../CLAUDE.md`](../../CLAUDE.md) — vale integralmente
> (Diretriz Suprema, método SDD/TDD, segurança/LGPD, princípios de risco). Aqui ficam só os recortes
> **específicos deste produto**.
>
> Caminhos: `docs/…` = docs deste produto; `../../docs/…` = governança de plataforma.

## 🎯 O que é o produto
<Uma frase: que problema resolve, para quem, e onde se encaixa no ecossistema.>
Detalhe do domínio: `docs/discovery/01-domain-overview.md` (crie antes de qualquer spec).

## 👥 Papéis
<Liste os papéis. Marque `(provisório)` o que não tem `✅ Confirmado` no decisions-log.>

## 🚦 Fase atual
<Em que fase do Double Diamond está? Descobrir/Definir/Construir? Aponte o gate.>

## 🧱 Stack
<Adota o baseline da plataforma (.NET/React/GCP) ou diverge? Se diverge, registre a decisão.>

## 🔒 Integrações & dados sensíveis
<Sync com a Teleconsulta? Outros sistemas? Siga o `../../docs/security/security-baseline.md`.>

## 📌 Estado atual
- **Decisões:** `docs/decisions/decisions-log.md`
- **Perguntas abertas:** `docs/discovery/03-open-questions.md`

> Checklist mínimo antes de codar: discovery escrita · papéis listados · 1 spec `specified` (sem 🔴) ·
> teste de aceite antes do código (TDD) · produto registrado em `../README.md`.
