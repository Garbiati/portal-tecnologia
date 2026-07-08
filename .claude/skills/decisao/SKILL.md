---
name: decisao
description: Registra uma decisão confirmada pelo humano — D-xxx no decisions-log do produto ou P-xxx no log de plataforma — no formato padrão da casa, e commita. Use quando o Alessandro confirmar uma regra de negócio, escolha de arquitetura ou mudança de escopo.
---

# /decisao — registrar decisão confirmada

Uso: `/decisao <resumo da decisão>` (ou sem argumento — extraia a decisão do contexto
da conversa; se houver mais de uma candidata, confirme com o usuário qual registrar).

## Regras

- **Só decisão CONFIRMADA pelo humano.** Nunca registre suposição sua (Diretriz Suprema
  do CLAUDE.md raiz). Na dúvida se foi confirmada, pergunte antes de gravar.
- Específica de produto → `D-xxx` em `products/<produto>/docs/decisions/decisions-log.md`
  (padrão: doctor-hub). Transversal de plataforma → `P-xxx` em
  `docs/decisions/platform-decisions.md`.

## Passos

1. Descubra o próximo número: `grep -oE '(D|P)-[0-9]+' <log> | sort -t- -k2 -n | tail -1`.
2. Acrescente ao FIM do log, no formato da casa:

   ```
   ### D-NNN — Título curto e específico (AAAA-MM-DD)
   Contexto em 1-2 frases (o que o Alessandro pediu/confirmou, citando quando possível).
   O que foi decidido, em prosa densa; alternativas descartadas quando relevante;
   consequências práticas (o que muda no código/telas/fluxo).
   ```

   Data = hoje. Estilo: prosa compacta em pt-BR, **negrito** nos termos-chave, referências
   a outras decisões como (D-xxx). Para P-xxx, se muda a estrutura, atualize também
   `CLAUDE.md` raiz e `docs/architecture/platform-architecture.md`.
3. Commite **só o log** no umbrella: `docs: D-NNN — <resumo em minúsculas>`.
4. Responda ao usuário com o número registrado e o título.
