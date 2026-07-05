# Definição de PRONTO — homologação E2E contra infra real (D-153)

> Criado em 2026-07-05 após o Alessandro pegar, em 2 minutos de homologação, 2 bugs que
> **quebravam a funcionalidade** enquanto a suíte unitária estava 100% verde. Motivo: os testes
> unitários usam a **API mockada** — provam a lógica do componente, mas NÃO provam que o dado dá a
> volta de verdade (form → API → Keycloak → volta). O bug do vínculo (I-009) é o exemplo: o
> Keycloak descartava `clienteId`/`unidade` em silêncio e nenhum teste unitário via isso.

## Regra: "pronto" = testado de ponta a ponta

Uma tela/feature só é **PRONTA** quando, além de unit/build verdes, passa por um **harness E2E que
exercita os fluxos reais do usuário contra a API + Keycloak REAIS** (prod ou staging), afirmando
**persistência** (criar → reler → editar → reler → excluir → 404), **validação** (lixo é rejeitado)
e os **efeitos colaterais** (vínculo, papéis, status). Sem isso, dizer "pronto" está proibido.

### Camadas de teste (todas obrigatórias antes de "pronto")
1. **Unit/componente** (Vitest) — lógica, estados, render. Rápido, mockado. NÃO prova integração.
2. **E2E de homologação** (script real, este doc) — CRUD real contra a infra, com persistência.
3. **Homologação humana** — o dono navega. O E2E existe pra que a etapa 3 não pegue bug grotesco.

## Harness por tela (padrão)
- **Usuários:** [`infrastructure/scripts/homolog-usuarios-e2e.py`](../../../../infrastructure/scripts/homolog-usuarios-e2e.py)
  — criar → ler pela lista → editar (nome + **vínculo cliente/unidade**) → desativar/reativar →
  rejeitar CPF inválido → excluir (→404). Cria usuário DESCARTÁVEL (e-mail `@doctorhub.local`
  não-entregável, sem spam), limpa no fim, sai != 0 em qualquer falha.
  ```bash
  E2E_ADMIN_USER=<user> E2E_ADMIN_PASS=<senha> python3 infrastructure/scripts/homolog-usuarios-e2e.py
  # aponta p/ outro ambiente: API_BASE=... KC_BASE=...  · zero segredo no código
  ```
- **Próximas telas** (a fazer, mesmo padrão): Clientes & Projetos (CRUD + exclusão por vínculo);
  Escala (criar FIXA por-dia/semana-excluída/tipo/projeto → ler → arquivar); Solicitações; Assunção.

## Onde roda
- **Manual/agora:** rodar o script antes de dizer "pronto" e na homologação.
- **Objetivo:** rodar no **CI pós-deploy** (job de smoke E2E) contra o ambiente recém-deployado,
  barrando promoção se falhar — mesma disciplina do `pnpm build`/CI atual, mas na infra real.

## Por que não bastava o unit test
O unit test do form de Usuários mockava `lib/api`, então "salvar vínculo" só verificava que a função
mock foi chamada com o argumento certo. Nunca tocou o Keycloak, que **rejeitava o atributo não
declarado**. E2E real contra Keycloak = a única camada que pega essa classe de bug (config de infra,
serialização, RBAC, migração, mapeamento DTO↔atributo).
