# Regra global — Segurança & LGPD (healthcare)

> Vale para o hub e para todos os `services/`. **Detalhe completo:** `docs/security/security-baseline.md`.
> Fundamentação (estudos/taxas): `docs/method/ai-coding-sdd-report.md`.

1. **Zero segredo no código.** Nada de senha/token/connection string em código, `appsettings`,
   `.mcp.json` ou settings. Dev: `.env` (gitignored) + `dotnet user-secrets`. Prod: **GCP Secret Manager**.
   O `gitleaks` + pre-commit (`.gitleaks.toml`, `.pre-commit-config.yaml`) barram vazamento.
2. **LGPD — dado sensível de paciente.** Nunca expor dado de paciente em logs ou respostas; no demo,
   **só iniciais** (ex.: "Maria S."). Least-privilege/RBAC por papel.
3. **Verificar todo pacote sugerido por IA** antes de adicionar (≈20% das sugestões são inexistentes).
4. **Núcleo crítico à mão.** Invariantes médicas/financeiras (capacidade, escala, alocação, status)
   são escritas/revisadas por humano e cercadas de teste — não delegadas cegamente.
5. **Sync com a Teleconsulta = via banco (D-069):** PULL é read-only; PUSH (escrita) só via credencial
   dedicada + allowlist tabela:colunas + dry-run + `--apply` + log; nunca DELETE/DROP/TRUNCATE;
   UPDATE sempre com WHERE por `external_id`; mapeamento confirmado pelo humano.
