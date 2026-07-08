# Regra global — SDD + TDD (método da casa)

> Vale para o hub e todos os `services/`. Detalhe: `specs/README.md` e `docs/method/`.

1. **Nada é codificado sem spec aprovada.** A spec é o sistema; o código é derivado.
   Specs de produto em `products/<p>/specs/`; ciclo de vida em `specs/README.md`.
2. **TDD.** Teste antes do código. Toda invariante médica/financeira cercada de teste
   e revisada por humano (não delegada cegamente).
3. **Não inferir regra de negócio.** Se não está na discovery ou numa spec aprovada,
   não existe. Dúvida → pergunta aberta do produto + `// PROVISÓRIO` no código.
4. **Decisão confirmada vira registro.** Transversal → ADR de plataforma `P-xxx`
   (`docs/decisions/platform-decisions.md`); específica do produto → `D-xxx`
   (`products/<p>/docs/decisions/decisions-log.md`). Use a skill `/decisao`.
5. **Lotes pequenos.** Mudanças pequenas, testadas, frequentes. Não dizer "pronto"
   sem os testes verdes e (no doctor-hub-web) o `check:ui` passando.
