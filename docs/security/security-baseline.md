---
title: Baseline de Segurança & LGPD — Plataforma (healthcare)
status: active
scope: plataforma (hub + todos os services)
date: 2026-06-23
---

# Baseline de Segurança & LGPD

> Vale para o **hub** e para **todos os `services/`** de todos os produtos. Fundamentação (estudos,
> taxas): [`../method/ai-coding-sdd-report.md`](../method/ai-coding-sdd-report.md). A versão curta,
> aplicada pela máquina, está em [`../../.claude/rules/security.md`](../../.claude/rules/security.md)
> — este doc é o **detalhe**.

## Por que healthcare eleva a régua
Lidamos com **dado sensível (LGPD)** e, em saúde pública, **dinheiro público**. Além disso, IA gera
código inseguro ~45% das vezes, **dobra** vazamento de segredo e sugere ~20% de dependências
inexistentes (fontes no relatório de método). O baseline abaixo não é opcional.

## 1. Zero segredo no código
Nada de senha/token/connection string em código, `appsettings`, `.mcp.json` ou settings.
- **Dev:** `.env` (gitignored) + `dotnet user-secrets`.
- **Prod:** **GCP Secret Manager**.
- **Barreira:** `gitleaks` + pre-commit (`.gitleaks.toml`, `.pre-commit-config.yaml`) barram vazamento
  antes do commit. Segredo já commitado = rotacionar a credencial, não só apagar o arquivo.

## 2. LGPD — dado sensível de paciente
- Nunca expor dado de paciente em **logs** ou **respostas**. Em demo/protótipo, **só iniciais**
  (ex.: "Maria S.").
- **Least-privilege / RBAC por papel** em cada produto. Acesso mínimo necessário, por padrão negado.

## 3. Verificar todo pacote sugerido por IA
≈20% das sugestões de dependência são inexistentes (risco de "slopsquatting"). Confirmar que o pacote
existe, é mantido e é o oficial **antes** de adicionar.

## 4. Núcleo crítico à mão
Invariantes médicas/financeiras (capacidade, escala, alocação, elegibilidade, fairness, status,
dinheiro) são **escritas/revisadas por humano e cercadas de teste** — não delegadas cegamente à IA.
A spec + a suíte de testes são a única verdade de campo (contra a lacuna de superconfiança).

## 5. Sync com a Teleconsulta = via banco (D-069)
Qualquer produto que sincronize com a Teleconsulta segue **exatamente** este protocolo:
- **PULL** (leitura): **read-only**.
- **PUSH** (escrita): **só via credencial dedicada** + **allowlist `tabela:colunas`** + **dry-run** +
  flag explícita **`--apply`** + **log** de tudo.
- **Nunca** `DELETE` / `DROP` / `TRUNCATE`.
- `UPDATE` **sempre** com `WHERE` por `external_id`.
- **Mapeamento confirmado pelo humano** antes de qualquer escrita.

> Caso concreto (Doctor-Hub ↔ Teleconsulta): ver o decisions-log do produto
> (`products/doctor-hub/docs/decisions/decisions-log.md`, D-069).
