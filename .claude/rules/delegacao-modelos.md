# Regra global — Economia de modelos (orquestrador caro, executores baratos)

> Objetivo: usar o modelo top (Opus-class) SÓ onde ele paga o preço — decisão, arquitetura,
> regra de negócio, revisão final — e delegar o resto a subagents com modelo mais barato.
> Os agents em `.claude/agents/` já vêm com o modelo certo pinado no frontmatter. ADR: P-016.

## Divisão de trabalho

| Papel | Modelo | Quem faz |
|---|---|---|
| **Orquestração** — entender o pedido, decidir abordagem, desenhar spec, revisar resultado, falar com o humano | **Opus (sessão principal)** | a sessão principal, sempre |
| **Exploração/recon** — achar arquivos, mapear código, responder "onde está X?" | **haiku** | agent `explorador` (ou `Explore` com `model: haiku`) |
| **Implementação de lote bem especificado** — spec pronta, arquivos e mudanças apontados | **sonnet** | agent `implementador` |
| **Revisões** — adversarial de coerência, segurança/LGPD do diff | **sonnet** | agents `revisor-adversarial` / `revisor-seguranca` |
| **Routines cloud** (smoke, tarefas agendadas) | **sonnet** | `claude-sonnet-5` no job_config |

## Regras duras

1. **Nunca delegar a modelo barato:** regra de negócio, invariante médica/financeira,
   decisão de arquitetura, e a revisão final antes de "pronto". Isso é do orquestrador
   (+ humano, cf. `security.md` §4).
2. **Orquestrador não faz trabalho de formiga.** Varredura em massa de arquivos, greps
   exploratórios (>3 buscas) e lotes mecânicos de edição → delegar. Isso também protege
   o contexto da sessão principal (menos compactação = menos perda).
3. **Delegação com prompt auto-contido:** o subagent nasce sem contexto. O orquestrador
   entende ANTES, delega com paths/linhas/critério de aceite, e VERIFICA o diff depois
   (confiar ≠ não conferir).
4. **Paralelize subagents independentes** (uma mensagem, várias chamadas de Agent).
5. Na dúvida entre sonnet e haiku: haiku para ler/procurar/resumir; sonnet quando precisa
   escrever código ou julgar algo com nuance.
